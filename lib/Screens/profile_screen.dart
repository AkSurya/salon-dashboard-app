import 'package:flutter/material.dart';
import 'edit_services_screen.dart';
import 'support_screen.dart';

class ProfileScreen extends StatelessWidget {
  final VoidCallback onOpenSettings;
  const ProfileScreen({super.key, required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final subTextColor = isDarkMode ? Colors.grey[400] : Colors.grey;
    final iconCircleColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.teal.shade50;

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
                      CircleAvatar(radius: 50, backgroundColor: iconCircleColor, child: const Icon(Icons.person, size: 50, color: Colors.teal)),
                      const Positioned(bottom: 0, right: 0, child: CircleAvatar(radius: 15, backgroundColor: Colors.teal, child: Icon(Icons.edit, size: 14, color: Colors.white))),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text("Glamour Salon", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                            IconButton(onPressed: () {}, icon: const Icon(Icons.edit, size: 18, color: Colors.grey))
                          ],
                        ),
                        Text("Premium Hair & Skin Care", style: TextStyle(color: subTextColor)),
                      ],
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
              onTap: () {},
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

                Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportScreen()));
              },
            ),
            _buildProfileOption(
              icon: Icons.settings_outlined,
              title: "App Settings",
              subtitle: "Control automation and AI features",
              textColor: textColor,
              subTextColor: subTextColor,
              onTap: onOpenSettings,
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
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
      subtitle: Text(subtitle, style: TextStyle(color: subTextColor)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}