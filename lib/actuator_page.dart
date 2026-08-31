// =============================================================================
// LINEAR ACTUATOR CONTROL — pushed from the "9 CANISTER" button on HomePage.
// Uses the SAME UdpService / Cmd as the rest of Zulu Buttons, so it talks
// to whatever Pi/drone is currently configured.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'services/commands.dart';
import 'services/udp_service.dart';
import 'services/event_log.dart';

// Local theme tokens — private to this file (leading underscore) so they
// never collide with the kBg/kSurface/etc. tokens already declared in
// main.dart, no matter how these files are imported.
// Matched to the main Zulu Buttons palette (near-black + caution yellow).
const Color _aBg = Color(0xFF0A0A0A); // near-black background
const Color _aPanelLine = Color(0xFF2A2A2A); // hairline border
const Color _aTextPrimary = Color(0xFFFFFFFF);
const Color _aTextDim = Color(0xFF888888);
const Color _aBlue = Color(0xFFFFC72C); // "Current Angle" value → accent yellow
const Color _aGreenAccent = Color(0xFF4CAF50); // "Target Angle" value → success green
const Color _aIndigo = Color(0xFFFFC72C); // GO button → accent yellow
const Color _aTeal = Color(0xFF222222); // canister tiles → raised surface
const Color _aGreen = Color(0xFF4CAF50); // Auto Trigger → success green
const Color _aOpenBlue = Color(0xFFFFC72C); // OPEN → accent yellow
const Color _aClosePurple = Color(0xFFB8901F); // CLOSE → dim accent
const Color _aStopRed = Color(0xFFFF5252); // STOP → danger red
const Color _aInputBg = Color(0xFF222222); // raised / input surface
const Color _aInputBorder = Color(0xFF2A2A2A); // hairline border

class ActuatorControlPage extends StatefulWidget {
  /// When true, this widget is embedded inside another Scaffold (e.g. the
  /// sidebar-driven HomePage) and should NOT draw its own Scaffold/AppBar
  /// or back arrow. When false (default), it behaves as a standalone
  /// pushed screen, same as before.
  final bool embedded;

  const ActuatorControlPage({super.key, this.embedded = false});

  @override
  State<ActuatorControlPage> createState() => _ActuatorControlPageState();
}

class _ActuatorControlPageState extends State<ActuatorControlPage> {
  static const num _kMaxAngle = 90; // change this to adjust the cap

  final TextEditingController _angleController = TextEditingController(
    text: '-45',
  );

  // Placeholder — live feedback needs a UDP listener once the Pi's angle
  // broadcast format is confirmed. See udp_service.dart for notes.
  final String _currentAngle = '--';
  String _targetAngle = '--';

  @override
  void dispose() {
    _angleController.dispose();
    super.dispose();
  }

  void _sendCanister(int n) {
    HapticFeedback.selectionClick();
    UdpService.send(Cmd.canister(n), port: Cmd.port);
    _showSnack('CANISTER $n → ${Cmd.canister(n)}', _aTeal);
    EventLog.log(
      'Canister $n triggered',
      channel: EventLog.channelNineCanister,
      binary: "cmd '${Cmd.canister(n)}' → :${Cmd.port}",
    );
  }

  static const List<int> _autoSequence = [1, 9, 3, 7, 2, 8, 4, 6, 5];

  Future<void> _autoTrigger() async {
    HapticFeedback.mediumImpact();
    _showSnack('AUTO TRIGGER STARTED', _aGreen);
    EventLog.log(
      'Auto Trigger started',
      channel: EventLog.channelNineCanister,
      binary: 'sequence ${_autoSequence.join(',')} → :${Cmd.port}',
    );
    for (final n in _autoSequence) {
      UdpService.send(Cmd.canister(n), port: Cmd.port);
      EventLog.log(
        'Canister $n triggered (auto)',
        channel: EventLog.channelNineCanister,
        binary: "cmd '${Cmd.canister(n)}' → :${Cmd.port}",
      );
      await Future.delayed(const Duration(milliseconds: 750));
    }
  }

  void _go() {
    final raw = _angleController.text.trim();
    final angle = num.tryParse(raw);
    if (angle == null) {
      _showSnack('ENTER A VALID ANGLE', _aStopRed);
      return;
    }
    if (angle > _kMaxAngle) {
      _showSnack('MAX ANGLE IS $_kMaxAngle°', _aStopRed);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _targetAngle = angle.toString());
    UdpService.send(Cmd.goToAngle(angle), port: Cmd.port);
    _showSnack('GO → ${angle.toString()}°', _aIndigo);
   EventLog.log(
      'Target angle set to ${angle.toString()}°',
      channel: EventLog.channelNineCanister,
      binary: "cmd '${Cmd.goToAngle(angle)}' → :${Cmd.port}",
    );
  }

  void _open() {
    HapticFeedback.lightImpact();
    UdpService.send(Cmd.openCmd, port: Cmd.port);
    _showSnack('OPEN SENT', _aOpenBlue);
    EventLog.log(
      'Actuator Open',
      channel: EventLog.channelNineCanister,
      binary: "cmd '${Cmd.openCmd}' → :${Cmd.port}",
    );
  }

  void _close() {
    HapticFeedback.lightImpact();
    UdpService.send(Cmd.closeCmd, port: Cmd.port);
    _showSnack('CLOSE SENT', _aClosePurple);
    EventLog.log(
      'Actuator Close',
      channel: EventLog.channelNineCanister,
      binary: "cmd '${Cmd.closeCmd}' → :${Cmd.port}",
    );
  }

  void _stop() {
    HapticFeedback.heavyImpact();
    UdpService.send(Cmd.stopCmd, port: Cmd.port);
    _showSnack('STOP SENT', _aStopRed);
    EventLog.log(
      'Actuator Stop',
      channel: EventLog.channelNineCanister,
      binary: "cmd '${Cmd.stopCmd}' → :${Cmd.port}",
    );
  }

  void _showSnack(String msg, Color color) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: color.withOpacity(0.92),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 520,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 10),
                      _buildAngleSection(),
                      const SizedBox(height: 10),
                      const Divider(color: _aPanelLine, height: 1),
                      const SizedBox(height: 10),
                      _buildCanisterSection(),
                      const SizedBox(height: 10),
                      _buildAutoTriggerButton(),
                      const SizedBox(height: 10),
                      const Divider(color: _aPanelLine, height: 1),
                      const SizedBox(height: 10),
                      _buildActuatorSection(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    if (widget.embedded) {
      return Container(color: _aBg, child: content);
    }

    return Scaffold(
      backgroundColor: _aBg,
      appBar: AppBar(
        backgroundColor: _aBg,
        foregroundColor: _aTextPrimary,
        elevation: 0,
        title: const Text(
          '9 CANISTER',
          style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.w800),
        ),
      ),
      body: content,
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings, color: _aTextPrimary, size: 22),
            SizedBox(width: 8),
            Text(
              'LINEAR ACTUATOR CONTROL',
              style: TextStyle(
                color: _aTextPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(color: _aPanelLine, height: 1),
      ],
    );
  }

  Widget _buildAngleSection() {
    return Column(
      children: [
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _aTextPrimary,
            ),
            children: [
              const TextSpan(text: 'Current Angle : '),
              TextSpan(
                text: '$_currentAngle°',
                style: const TextStyle(color: _aBlue),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _aTextDim,
            ),
            children: [
              const TextSpan(text: 'Target Angle : '),
              TextSpan(
                text: '$_targetAngle°',
                style: const TextStyle(color: _aGreenAccent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 150,
          child: TextField(
            controller: _angleController,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
            ),
            style: const TextStyle(color: _aTextPrimary, fontSize: 14),
            decoration: InputDecoration(
              filled: true,
              fillColor: _aInputBg,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: _aInputBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: _aIndigo, width: 1.5),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: _aInputBorder),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _go,
            style: ElevatedButton.styleFrom(
              backgroundColor: _aIndigo,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.play_arrow, size: 16),
                SizedBox(width: 6),
                Text(
                  'GO',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCanisterSection() {
    return Column(
      children: [
        const Text(
          'CANISTER TRIGGER',
          style: TextStyle(
            color: _aTextDim,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 9,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.6,
          ),
          itemBuilder: (_, i) {
            final n = i + 1;
            return ElevatedButton(
              onPressed: () => _sendCanister(n),
              style: ElevatedButton.styleFrom(
                backgroundColor: _aTeal,
                foregroundColor: _aBlue,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: const BorderSide(color: _aPanelLine),
                ),
                elevation: 0,
              ),
              child: Text(
                '$n',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAutoTriggerButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _autoTrigger,
        style: ElevatedButton.styleFrom(
          backgroundColor: _aGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bolt, size: 16),
            SizedBox(width: 6),
            Text(
              'AUTO TRIGGER',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActuatorSection() {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.build, color: _aTextDim, size: 15),
            SizedBox(width: 6),
            Text(
              'ACTUATOR CONTROL',
              style: TextStyle(
                color: _aTextDim,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _open,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _aOpenBlue,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_upward, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'OPEN',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _close,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _aClosePurple,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_downward, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'CLOSE',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _stop,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _aStopRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.stop, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'STOP',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
