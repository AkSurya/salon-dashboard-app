import 'package:flutter/material.dart';


class SettingsScreen extends StatelessWidget {
  final bool isAutoApprove;
  final Function(bool) onToggleAutoApprove;
  final bool isGapProtectorEnabled;
  final int gapDuration;
  final Function(bool) onToggleGapProtector;
  final Function(int) onGapDurationChanged;

  const SettingsScreen({
    super.key,
    required this.isAutoApprove,
    required this.onToggleAutoApprove,
    required this.isGapProtectorEnabled,
    required this.gapDuration,
    required this.onToggleGapProtector,
    required this.onGapDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("App Settings"),
        backgroundColor: Theme.of(context).cardColor,
      ),
      body: ListView(
        children: [

          _buildSettingsCategory(
            context,
            icon: Icons.bolt,
            title: "Instant Booking",
            subtitle: "Manage how requests are auto-approved",
            destination: InstantBookingDetailScreen(
              isEnabled: isAutoApprove,
              onChanged: onToggleAutoApprove,
            ),
          ),
          _buildSettingsCategory(
            context,
            icon: Icons.timer_outlined,
            title: "Gap Protector",
            subtitle: "Automatically add cleaning time between sessions",
            destination: GapProtectorDetailScreen(
              isEnabled: isGapProtectorEnabled,
              currentGap: gapDuration,
              onToggle: onToggleGapProtector,
              onGapChanged: onGapDurationChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCategory(BuildContext context, {required IconData icon, required String title, required String subtitle, required Widget destination}) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => destination)),
    );
  }
}

class InstantBookingDetailScreen extends StatefulWidget {
  final bool isEnabled;
  final Function(bool) onChanged;

  const InstantBookingDetailScreen({super.key, required this.isEnabled, required this.onChanged});

  @override
  State<InstantBookingDetailScreen> createState() => _InstantBookingDetailScreenState();
}

class _InstantBookingDetailScreenState extends State<InstantBookingDetailScreen> {
  late bool _tempEnabled;

  @override
  void initState() {
    super.initState();
    _tempEnabled = widget.isEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Instant Booking")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text("What is Instant Booking?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text("When enabled, requests are approved instantly if the slot is free.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            SwitchListTile(
              title: const Text("Enable Automation"),
              value: _tempEnabled,
              onChanged: (val) {
                setState(() => _tempEnabled = val);
                widget.onChanged(val);
              },
            ),
          ],
        ),
      ),
    );
  }
}
class GapProtectorDetailScreen extends StatefulWidget {
  final bool isEnabled;
  final int currentGap;
  final Function(bool) onToggle;
  final Function(int) onGapChanged;

  const GapProtectorDetailScreen({
    super.key,
    required this.isEnabled,
    required this.currentGap,
    required this.onToggle,
    required this.onGapChanged
  });

  @override
  State<GapProtectorDetailScreen> createState() => _GapProtectorDetailScreenState();
}

class _GapProtectorDetailScreenState extends State<GapProtectorDetailScreen> {
  late bool _localEnabled;

  @override
  void initState() {
    super.initState();

    _localEnabled = widget.isEnabled;
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text("Gap Protector", style: TextStyle(color: Colors.black, letterSpacing: -0.5)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),

          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _localEnabled ? Colors.orange.withOpacity(0.1) : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                  Icons.timer_rounded,
                  size: 64,
                  color: _localEnabled ? Colors.orange : Colors.grey[400]
              ),
            ),
          ),
          const SizedBox(height: 24),


          SwitchListTile.adaptive(
            title: const Text("Automatic Buffering", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
            subtitle: const Text("Give your team time to breathe"),
            value: _localEnabled,
            activeColor: Colors.orange,
            onChanged: (val) {
              setState(() => _localEnabled = val);
              widget.onToggle(val);
            },
          ),

          const SizedBox(height: 40),


          AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: _localEnabled ? 1.0 : 0.0,
            child: Column(
              children: [
                const Text("SELECT DURATION", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 2)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [5, 10, 15, 20].map((mins) {
                    bool isSelected = widget.currentGap == mins;
                    return GestureDetector(
                      onTap: () => widget.onGapChanged(mins),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 60,
                        height: 60,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.black : Colors.transparent,
                          border: Border.all(color: isSelected ? Colors.black : Colors.grey[300]!),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                            "${mins}m",
                            style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold
                            )
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}