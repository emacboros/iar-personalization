**Update 2026-09-21 -- third system (frigate 0.17.2 / go2rtc 1.9.10, 8 RTSP cams), the video-track mirror of the audio reconnect, and the conn-scoped wedge model**

Follow-up after 3 more days of fleet observation. Two new evidence classes, both from the same 8-camera frigate 0.17.2 system (go2rtc 1.9.10) as the original report.

**1. The same AddTrack gap exists for the video track, not just audio -- and when audio keeps the conn alive, go2rtc never heals.**

The audio-only death shape from the original report has a mirror: an established producer conn where the *video* track wedges while audio keeps flowing. On 2026-09-20 we caught two live episodes (exterior_3, exterior_4):

- go2rtc receiver counters: `hevc` frozen (620717 -> 620717 over 20s) while `aac` grows (+85k/20s). Camera OS alive (ping + HTTP 200), SDP still advertises video, prudynt's video pipe is wedged.
- Because the conn is TCP-healthy (audio flows), the i/o-timeout remake never fires. go2rtc holds the conn indefinitely -- one episode ran 33+ minutes with zero log output at WRN level, until we restarted go2rtc itself.
- frigate's recorder discards the audio-only segments (`Invalid or missing video stream in segment`), so this is real recording loss that no watchdog sees: frigate's watchdog watches the *detect* leg, which consumes video -- but the record leg's ffmpeg gets restarted by the watchdog and still receives no video, so restarts don't heal it either.
- A fresh conn re-establishes the video track immediately (after restart: hevc 684694 -> 767498 in 8s). The wedge is **conn-scoped, not camera-OS-scoped**.

So the same asymmetry as the original report applies one level up: `GetTrack` dedups against existing receivers, but nothing in the producer/consumer path detects a track that stops delivering packets on a living connection. The ask extends: go2rtc should notice a track whose receiver counter stops advancing while sibling tracks on the same conn keep flowing, and re-dial (or at minimum expose a per-track staleness metric consumers like frigate could alert on).

**2. A caution for anyone correlating RTSP reconnect storms with camera behavior: scheduled camera reboots manufacture the same log signature.**

We discovered all 8 of our cameras reboot daily on a staggered cron (thingino-side). Each reboot produces: WRN i/o timeout at HH:00:05, retry ladder, stop producer, disconnect, new consumer + start producer -- i.e. a WRN storm and a producer remake that looks exactly like the probe-triggered remakes in this issue, once per camera per day. If you're counting WRNs or remakes to characterize this bug, exclude your cameras' reboot windows first. (The probe-triggered remakes are still real and still the bug -- the dedup fix is still justified -- but naive WRN-rate stats will overcount.)

**3. Independent confirmation of the wedge class from another stack (1davethomas-design's comment):** the accumulating-duplicate-ffmpeg shape you saw on HA 1.9.14 matches what we see at 1.9.10 when a remade producer's consumers wedge -- on our system it manifests as recorder restart loops that never self-heal (the 2026-09-18 update, item 3) rather than duplicate PIDs, but both are the same underlying shape: a producer remake that leaves consumers holding stale state with no recovery path except manual intervention.

Happy to test a patch. The cheapest discriminator for the fix: after dedup lands in `Conn.AddTrack`, a `microphone=` probe on a playing sendonly-audio producer should leave the producer's session id and packet counters completely untouched.
