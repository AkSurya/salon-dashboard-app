import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'add_service_screen.dart';
import 'tutorial_controller.dart';

class EditServicesScreen extends StatefulWidget {
  const EditServicesScreen({super.key});

  @override
  _EditServicesScreenState createState() => _EditServicesScreenState();
}

class _EditServicesScreenState extends State<EditServicesScreen> {
  final GlobalKey addServiceKey = GlobalKey();
  final GlobalKey firstServiceKey = GlobalKey();

  List<Map<String, dynamic>> myServices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    final prefs = await SharedPreferences.getInstance();
    final String? detailedJson = prefs.getString('detailedServices');

    if (detailedJson != null) {
      final List<dynamic> decodedData = json.decode(detailedJson);
      setState(() {
        myServices = decodedData.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } else {
      final List<String>? savedNames = prefs.getStringList('userServices');
      if (savedNames != null) {
        setState(() {
          myServices = savedNames.map((name) => {
            "name": name,
            "price": 500,
            "duration": 30,
          }).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }


    bool showTutorial = prefs.getBool('showTutorial') ?? false;
    if (showTutorial) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && myServices.isNotEmpty) {
          startTutorial();
        }
      });
      await prefs.setBool('showTutorial', false);
    }
  }

  Future<void> _saveToMemory() async {
    final prefs = await SharedPreferences.getInstance();
    String encodedData = json.encode(myServices);
    await prefs.setString('detailedServices', encodedData);
  }

  void startTutorial() {
    TutorialController.showHighlight(
      context: context,
      targetKey: addServiceKey,
      text: "Click here to add new services that you provide!",
      onNext: () {
        TutorialController.showHighlight(
          context: context,
          targetKey: firstServiceKey,
          text: "Swipe LEFT to delete, or CLICK to change price/time.",
          onNext: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Tutorial Complete!")),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Prices & Time", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : myServices.isEmpty
          ? const Center(child: Text("No services selected yet."))
          : ListView.builder(
        itemCount: myServices.length,
        itemBuilder: (context, index) {
          final service = myServices[index];
          return Container(
            key: index == 0 ? firstServiceKey : null,
            child: Dismissible(
              key: Key(service['name']),
              direction: DismissDirection.endToStart,
              confirmDismiss: (direction) async {
                return await showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      title: const Text("Confirm Delete"),
                      content: Text("Are you sure you want to remove ${service['name']}?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text("Delete", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    );
                  },
                );
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: Colors.red,
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (direction) {
                setState(() {
                  myServices.removeAt(index);
                });
                _saveToMemory();
              },
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  title: Text(service['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("₹${service['price']} • ${service['duration']} mins"),
                  trailing: const Icon(Icons.edit_note, color: Colors.teal),
                  onTap: () => _showEditPanel(index),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: addServiceKey,
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add New Service", style: TextStyle(color: Colors.white)),
        onPressed: () => _goToAddServicePage(),
      ),
    );
  }

  void _goToAddServicePage() async {
    List<String> existingNames = myServices.map((e) => e['name'] as String).toList();
    final String? selectedServiceName = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddServiceScreen(existingServiceNames: existingNames),
      ),
    );

    if (selectedServiceName != null) {
      setState(() {
        myServices.add({
          "name": selectedServiceName,
          "price": 500,
          "duration": 30,
        });
      });
      _saveToMemory();
    }
  }

  void _showEditPanel(int index) {
    TextEditingController manualPriceController =
    TextEditingController(text: myServices[index]['price'].toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Edit ${myServices[index]['name']}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Price: ₹${myServices[index]['price']}",
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      SizedBox(
                        width: 80,
                        height: 40,
                        child: TextField(
                          controller: manualPriceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            prefixText: "₹",
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onChanged: (val) {
                            int? newPrice = int.tryParse(val);
                            if (newPrice != null && newPrice >= 100 && newPrice <= 5000) {
                              setModalState(() => myServices[index]['price'] = newPrice);
                              setState(() {});
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: myServices[index]['price'].toDouble(),
                    min: 100,
                    max: 5000,
                    divisions: 49,
                    activeColor: Colors.teal,
                    onChanged: (val) {
                      setModalState(() {
                        myServices[index]['price'] = val.toInt();
                        manualPriceController.text = val.toInt().toString();
                      });
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 20),
                  Text("Time: ${myServices[index]['duration']} Minutes",
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  Slider(
                    value: myServices[index]['duration'].toDouble(),
                    min: 15,
                    max: 180,
                    divisions: 11,
                    activeColor: Colors.orange,
                    onChanged: (val) {
                      setModalState(() => myServices[index]['duration'] = val.toInt());
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () async {
                      await _saveToMemory();
                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                    child: const Text("Save Changes", style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}