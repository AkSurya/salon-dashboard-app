import 'package:flutter/material.dart';
import 'edit_services_screen.dart';
import 'support_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenServices;
  const ProfileScreen({
    super.key,
    required this.onOpenSettings,
    required this.onOpenServices,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Track the salon name locally so UI updates instantly after edit
  String? _cachedName;
  String? _cachedAddress;

  Future<void> _editSalonName(BuildContext context, String currentName) async {
    final controller = TextEditingController(text: currentName);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Salon Name"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: "Salon Name",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return;

        await FirebaseFirestore.instance
            .collection('salons')
            .doc(uid)
            .update({'name': result});

        // Update local cache so UI refreshes instantly
        setState(() => _cachedName = result);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Salon name updated!"),
            backgroundColor: Colors.teal,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subTextColor = isDarkMode ? Colors.grey[400] : Colors.grey;
    final iconCircleColor =
    isDarkMode ? const Color(0xFF1E1E1E) : Colors.teal.shade50;

    return Scaffold(
      backgroundColor: bgColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: iconCircleColor,
                        child: const Icon(Icons.person,
                            size: 50, color: Colors.teal),
                      ),
                      const Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: Colors.teal,
                          child:
                          Icon(Icons.edit, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('salons')
                          .doc(FirebaseAuth.instance.currentUser?.uid)
                          .get(),
                      builder: (context, snapshot) {
                        // Use cached name if available (after edit), else use Firestore data
                        final name = _cachedName ??
                            (snapshot.data?.get('name') ?? 'Salon');
                        final address = _cachedAddress ??
                            (snapshot.data?.get('address') ?? '');

                        // Cache initial values from Firestore
                        if (_cachedName == null &&
                            snapshot.hasData &&
                            snapshot.data!.exists) {
                          _cachedName = snapshot.data?.get('name') ?? 'Salon';
                          _cachedAddress =
                              snapshot.data?.get('address') ?? '';
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  // ✅ Now functional — opens edit dialog
                                  onPressed: () =>
                                      _editSalonName(context, name),
                                  icon: const Icon(Icons.edit,
                                      size: 18, color: Colors.grey),
                                ),
                              ],
                            ),
                            Text(
                              address,
                              style: TextStyle(color: subTextColor),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            _buildProfileOption(
              icon: Icons.content_cut,
              title: "My Services",
              subtitle: "Edit prices and service duration",
              textColor: textColor,
              subTextColor: subTextColor!,
              onTap: widget.onOpenServices,
            ),
            _buildProfileOption(
              icon: Icons.location_on_outlined,
              title: "Salon Address",
              subtitle: "Update your location",
              textColor: textColor,
              subTextColor: subTextColor,
              onTap: () {},
            ),
            _buildProfileOption(
              icon: Icons.notifications_none,
              title: "Notifications",
              subtitle: "Appointment alerts & reminders",
              textColor: textColor,
              subTextColor: subTextColor,
              onTap: () {},
            ),
            _buildProfileOption(
              icon: Icons.help_outline,
              title: "Support",
              subtitle: "Get help with your manager app",
              textColor: textColor,
              subTextColor: subTextColor,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SupportScreen(),
                  ),
                );
              },
            ),
            _buildProfileOption(
              icon: Icons.settings_outlined,
              title: "App Settings",
              subtitle: "Control automation and AI features",
              textColor: textColor,
              subTextColor: subTextColor,
              onTap: widget.onOpenSettings,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color textColor,
    required Color subTextColor,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Colors.teal),
      title: Text(title,
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
      subtitle: Text(subtitle, style: TextStyle(color: subTextColor)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}