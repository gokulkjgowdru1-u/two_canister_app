// Master UDP command map — both joystick and UI send these to Pi 3B+ port 3000.
// Single source of truth. Edit here only.
class Cmd {
  static const int port = 3000;

  static const String canister1 = '2'; // BTN_TOP2     292 — canister 1 release
  static const String canister2 = '3'; // BTN_THUMB2   290 — canister 2 release
  static const String pumpToggle = '4'; // BTN_PINKIE   293 — pump ON/OFF toggle
  static const String pumpStart = '5'; // BTN_BASE     294 — pump 3s pulse

  // ---------------------------------------------------------------------
  // 9-CANISTER / LINEAR ACTUATOR CONTROL — added for actuator_page.dart
  //
  // CONFIRMED: canister(n) sends its own digit as an ASCII string,
  //   e.g. canister(5) → "5", same pattern as canister1/canister2 above.
  //
  // NOT YET CONFIRMED — PLACEHOLDERS:
  //   openCmd / closeCmd / stopCmd / autoTriggerCmd / goToAngle() are
  //   placeholders. Confirm the exact strings/bytes your Pi firmware
  //   expects for the actuator, then update these before real use.
  // ---------------------------------------------------------------------

  /// Canister N (1-9) sends its own digit as a string — confirmed pattern.
  static String canister(int n) => n.toString();

  static const String openCmd = 'OPEN'; // TODO: confirm exact string/byte
  static const String closeCmd = 'CLOSE'; // TODO: confirm exact string/byte
  static const String stopCmd = 'STOP'; // TODO: confirm exact string/byte
  static const String autoTriggerCmd =
      'AUTO'; // TODO: confirm exact string/byte

  /// TODO: confirm the exact format the Pi expects for a target angle.
  static String goToAngle(num angle) => 'ANGLE:$angle';
}
