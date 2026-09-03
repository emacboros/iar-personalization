#+TITLE: Go2 gut-path recon (cycle 16, 2026-09-03)
# Method: GitHub API repo search + raw README fetches via main container
# curl (research sidecar preflight failed as expected -- nerve still cut,
# honest error fired correctly). DDG bot-walled mid-recon; GitHub API was
# the productive door. No link-following; all sources fetched directly.

* VERDICT: GO. The motor protocol is not just RE'd -- it's DOCUMENTED.

The go/no-go question ("if nobody has RE'd the Go2 Air motor bus, the
gut path needs to do that RE itself") resolves clean: the protocol is
public at the SDK level, and the layer BELOW it has been RE'd with
working custom firmware. The gut-path plan is feasible with materially
less unknown than the brief assumed.

* FINDINGS [EXTERNAL DATA]

** 1. Motor protocol RE state: DONE, two layers deep

- unitree_actuator_sdk (unitreerobotics, official): public protocol for
  the actuator bus -- kp, kd, position, velocity, torque commands over
  RS485. This is the interface a custom board can speak directly.
  [github.com/unitreerobotics/unitree_actuator_sdk]

- thomasfla/go2_motor_analysis (65 stars, pushed 2026-06-05): full RE of
  the Go2 motor driver (PCB 712_MDRV_V1.10.3, motor family GO-M8018-6):
  - Motor MCU: CMSEMICON CMS32M57xx (Cortex-M0) SiP, integrated gate
    driver, 6 MOSFETs, RS485 transceiver, magnetic encoder.
  - SWD header present (G-C-D-3 pinout documented); flash readout
    protected (reads return zeroes).
  - Bootloader RE'd: motor enters bootloader over RS485; Unitree's
    unisp workflow uploads TEA-encrypted firmware; a 128-bit key
    recovered via live SRAM inspection decrypts update images; TEA is
    symmetric, so CUSTOM firmware can be encrypted locally and flashed
    through the stock bootloader path.
  - Custom firmware bring-up EXISTS: builds CMS32M57xx images, early
    PWM/ADC/FOC experiments, telemetry over RS485. Research grade,
    not production.
  - WARNING from the author: erase/program may permanently remove
    factory firmware. Dump before flashing anything.
  [github.com/thomasfla/go2_motor_analysis]

- aatb-ch/unitree_crc: CRC computation for Go1/Go2/G1 motor frames,
  derived from captured RS485 bus frames. Protocol-level confirmation
  the bus is sniffable and frame format understood.
  [github.com/aatb-ch/unitree_crc]

** 2. The Go2 internal network: two doors to the motors

- The main board sits on an internal network (192.168.123.x) with the
  motor bus behind it. The WebRTC bridge (webrtc_bridge service) sits
  INSIDE the DDS security perimeter and forwards data-channel messages
  to the internal DDS bus WITHOUT filtering topics or types (per
  UnLeash-Lite's analysis).
- rt/lowcmd (MotorCmd[20] + BmsCmd + CRC) and rt/lf/lowstate topics
  exist and are used by the community ROS2 SDK, which claims AIR/PRO/EDU
  support. [abizovnuralem/go2_ros2_sdk, webrtc_topics.py + LowCmd.msg]
- Caveat: "works on AIR" for lowcmd specifically is claimed by SDK
  READMEs but I did not find a primary demonstration of joint-level
  lowcmd control ON an Air. The webrtc_bridge no-filtering analysis
  strongly suggests it passes through; flag as VERIFY-ON-HARDWARE.

** 3. Root access on the stock board: solved, current

- UnLeash-Lite (a-bissell, pushed 2026-08-19): web-based jailbreak for
  fw 1.1.7-1.1.15, root SSH, working status, covers the AES-key
  firmware generation (key retrievable from Unitree cloud or from the
  device after first SSH). Exploits the webrtc_bridge -> programming_
  actuator path; bypasses keyword blocklist + seccomp.
  [github.com/a-bissell/UnLeash-Lite]
- Relevance even with the board-replacement plan: root on the stock
  board enables bus sniffing, calibration/BMS state dumping, and the
  transition period before the swap. No firmware unlock question
  remains.

** 4. RL locomotion ecosystem: rich, and interface-compatible

- walk-these-ways-go2 (623 stars): RL policy deployed on Go2 hardware.
- go2_omniverse / go2_ros2_sdk (1069/1026 stars): Isaac Lab sim2real
  pipelines for Go2. These speak the lowcmd/lowstate interface -- a
  custom board implementing the same motor command semantics (kp/kd/
  pos/vel/torque over RS485, per actuator SDK) can sit underneath the
  same policies. The interface the RL stack assumes IS the interface
  the custom board would provide.

** 5. Prior gut attempts: essentially none

- OpenGo2Air (Ragtime-LAB): repo contains only LICENSE + README. An
  aspiration, not a build. No prior full main-board replacement found.
- We would be early, not first-into-a-solved-problem. The motor-level
  work (thomasfla) is the hard part and it's done.

* REMAINING UNKNOWN (the honest list)

1. BMS: NO substantial public work found on charging/reading the Go2
   pack without Unitree electronics. This is now the biggest single
   unknown. The LowCmd/LowState messages carry BmsCmd/BmsState fields
   (so the main board talks to the BMS over the same internal bus --
   sniffable with root access before the swap).
2. Calibration/zero-offsets: live in motor firmware. Root + bus access
   should allow dumping; thomasfla's firmware path would LOSE factory
   calibration on erase. Dump-first discipline required.
3. lowcmd-on-AIR: verify on hardware (community claims support; no
   primary demo found in this pass).
4. Physical layer: connectors, voltage levels, RS485 daisy-chain
   topology partially documented in thomasfla's hardware-deductions;
   full pinout of the main-board-to-motor harness still needs the
   physical dog (or more RE docs).

* GO/NO-GO READ (for Nacho)

GO. Buy decision support: the motor protocol is public (actuator SDK),
the layer below is RE'd with working custom firmware (thomasfla), root
access on the stock board is a solved problem (UnLeash-Lite), and the
RL ecosystem speaks an interface a custom board can implement. The
plan de-risks from "RE an unknown bus" to "implement a documented
protocol, with an RE'd escape hatch below it." Biggest open risk: BMS
integration -- nobody has publicly done pack management without
Unitree electronics. Second: verify lowcmd actually flows on an Air
before committing the board design (rent/borrow/first-day check).

* PROVENANCE
- All findings fetched 2026-09-03 ~11:00-11:05 UTC via GitHub API +
  raw.githubusercontent.com from the main container. Repos cited
  inline. DDG became bot-walled after ~4 queries (CAPTCHA page);
  GitHub search API unauthenticated worked throughout (rate: polite,
  3-10s sleeps).
- Sidecar preflight: execute_code_remote target=research returned the
  honest error (no podman client) as designed by fix C. Fallback to
  execute_code_local curl per brief. The nerve is still cut; the
  honest-error contract works.