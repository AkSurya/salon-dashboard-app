import 'package:flutter/material.dart';

class AddServiceScreen extends StatefulWidget {
  final List<String> existingServiceNames;

  const AddServiceScreen({super.key, required this.existingServiceNames});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {

  final Map<String, List<String>> _serviceCategories = {
    'Hair Services': ['Cutting', 'Styling (Blowouts)', 'Coloring', 'Extensions', 'Treatments'],
    'Skin Care & Facials': ['Facials', 'Cleansing', 'Detan', 'Acne Treatments'],
    'Hair Removal': ['Waxing', 'Threading', 'Sugaring'],
    'Nail Services': ['Manicures', 'Pedicures', 'Gel Nails', 'Nail Art'],
    'Makeup & Beauty': ['Bridal', 'Evening Makeup', 'Eyelash Application', 'Eyebrow Tinting'],
    'Body & Spa': ['Massages', 'Body Polishing', 'Aromatherapy'],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Services", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        children: _serviceCategories.keys.map((category) {

          List<String> availableInThisCategory = _serviceCategories[category]!
              .where((service) => !widget.existingServiceNames.contains(service))
              .toList();


          if (availableInThisCategory.isEmpty) return const SizedBox.shrink();

          return ExpansionTile(
            title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
            children: availableInThisCategory.map((service) {
              return ListTile(
                title: Text(service),
                trailing: const Icon(Icons.add_circle_outline, color: Colors.teal),
                onTap: () {

                  Navigator.pop(context, service);
                },
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}