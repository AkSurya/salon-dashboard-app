import 'package:flutter/material.dart';
import 'tutorial_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'edit_services_screen.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Support & Help", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSupportCard(
            context,
            title: "Administration",
            subtitle: "Contact us for payments & technical queries",
            icon: Icons.admin_panel_settings,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Admin support coming soon!")),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSupportCard(
            context,
            title: "App Tutorial",
            subtitle: "Learn how to use Glamour Salon features",
            icon: Icons.play_circle_fill,
            onTap: () {
              _showTutorialSelection(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard(BuildContext context, {required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          backgroundColor: Colors.teal.withOpacity(0.1),
          child: Icon(icon, color: Colors.teal),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  void _showTutorialSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text("What do you want to learn?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.orange),
            title: const Text("How to Edit/Add Services"),
            onTap: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('showTutorial', true);

              if (!context.mounted) return;
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditServicesScreen())
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep, color: Colors.red),
            title: const Text("How to Delete Services"),
            onTap: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('showTutorial', true);

              if (!context.mounted) return;
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EditServicesScreen())
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}