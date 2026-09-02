# Frigate event-DB archaeology -- cycle 126 (2026-09-02 ~05:00 UTC)

Follow-up to frigate-first-wander.md and the cycle-125 first-night
read. This closes the "DB begins yesterday" question with primary
evidence, and it corrects cycle 125 in one place.

## The DB timeline (all times local -03 unless marked UTC)

- 2026-09-01 01:24-01:28: frigate restart, ONNX yolov9 loads fine.
  Detector WAS running before the migration. (Corrects the
  implication in frigate-first-wander.md that no detector was ever
  configured -- that was true on Aug 30; by Sep 1 01:28 ONNX was
  live. The gap in that note is now filled.)
- 03:53:20: frigate restart + peewee migrations 028-032 (0.17
  schema upgrade: event.model_hash/detector_type/model_type,
  trigger table, user_review_status, password_changed_at). DB
  backup made (config/backup.db -- contains ONLY migratehistory,
  i.e. the pre-migration DB had no event rows to preserve).
  frigate.db birth: 03:53:20 (file birth timestamp).
- 03:53 -> 23:33: old container keeps running. ZERO ONNX lines in
  the journal in this window -- the detector was configured but
  SILENT (no load, no errors). Event table: 0 rows in 20h.
- 23:33-23:41: config edits + restarts. Crash-loop discovered:
  57 "Detection appears to be stuck" + ONNX reload cycles in 8
  minutes, escalating 23:35-23:40. Root cause found in the
  detector traceback: `Exception: ModelTypeEnum.ssd is currently
  not supported for onnx` -- the config still declared the OLD
  ssd_mobilenet detector type while pointing at the yolov9 onnx
  file. Detector processes died on every frame batch; watchdog
  restarted them; loop.
- 23:40:59: config.yaml mtime -- the fix lands (model_type:
  yolo-generic in the model block).
- 23:41:06: current container created + started.
- 23:41:20: FIRST EVENT EVER (interior_2, top_score 0.91) -- 14
  seconds after container start. Detection works immediately.

## What the first night contains (49 events, all person)

- interior_2: 33, interior_1: 11, interior_3: 5. exterior: 0.
- Scores 0.69-0.94 (json_extract(data,'$.top_score'); the
  top_score/score COLUMNS are NULL in this schema -- data JSON
  is the source).
- reviewsegment: 21 alert segments, all interiors.
- timeline: 132 rows (visible/gone/active/stationary), same span.
- has_snapshot=0, has_clip=1 on all 49 (snapshots disabled in
  config; clips recorded).
- Hourly flow: 02h UTC=8, 03h=5, 04h=36. The 04h burst is the
  01:31-01:39 local movement (i3 -> i1 -> i2 -> i1 -> i3 flow,
  scores 0.73-0.94) -- consistent with a person walking through
  the house. No UI requests in that window (caddy log not
  reachable from here -- rammstein ssh denied for my key; the
  cycle-125 correlation with camaras browsing stands as
  inference, unchanged).

## The exterior-zero question, sharpened

All 8 cameras: enabled, detect+record roles, no per-camera
objects filter (default = COCO all), no zones. Exteriors record
continuously (4900+ segments/24h each, current to 04:54). The
detector is healthy (interiors flow). So exterior-zero is NOT a
config gap -- it is either a genuinely empty yard at night, or
something about the exterior scenes (distance, angle, IR) that
keeps yolov9 below confidence. Longitudinal watch now runs in
fleet-check v2.7 (0c-c) every cycle. A week of exterior=0 with
interior flow = look at exterior detect params (frame size,
confidence threshold) -- config change is Nacho's call.

## Instrument notes (methods that mattered)

- sqlite read-only URI over ssh root@sophon is the working path
  (API 8971 needs JWT; basic auth gone in 0.17).
- event.data JSON holds score/top_score; the dedicated columns
  are NULL. Schema-first, then query.
- The loop guard caught me shrinking journal windows 5x hunting
  for detection log lines that don't exist: Frigate does not log
  detections at INFO. Absence in the journal is expected, not a
  finding. The DB is the detection record, not the journal.
- backup.db contains only migratehistory = the pre-migration DB
  was already event-empty. The 20h gap (03:53-23:33) had a live
  ONNX detector (01:28 proof) and still produced nothing --
  consistent with the ssd/onnx mismatch existing BEFORE the
  0.17 migration too (the migration didn't cause it; the config
  fix at 23:40:59 did resolve it).

## Provenance

All reads: ssh root@10.66.0.5 (sophon), frigate.db opened
mode=ro, journalctl -u frigate, config.yaml parsed with pyyaml,
podman inspect via user socket. No writes to frigate config or
DB. Times cross-checked between -03 journal stamps and UTC DB
stamps (the cycle-125 tz scar discipline).