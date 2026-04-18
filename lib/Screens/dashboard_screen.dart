import 'package:flutter/material.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'edit_services_screen.dart';
import 'emergency_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}
List<Map<String, dynamic>> salonServices = [
  {"name": "Haircut", "price": 500, "duration": "30 min", "icon": Icons.content_cut},
  {"name": "Beard Trim", "price": 200, "duration": "15 min", "icon": Icons.face},
  {"name": "Facial", "price": 1200, "duration": "60 min", "icon": Icons.auto_awesome},
  {"name": "Coloring", "price": 2500, "duration": "120 min", "icon": Icons.palette},
];
class _DashboardScreenState extends State<DashboardScreen> {
  bool _isDarkMode = false;
  bool _isAutoApproveEnabled = false;
  bool _isGapProtectorEnabled = false;
  bool _isZenMode = false;
  int _gapDuration = 10;
  double _dailyGoal = 50000;
  List<Map<String, dynamic>> salesHistory = [];
  double totalDailyEarnings = 45200.0;

  Stream<List<Map<String, dynamic>>> getBookingsStream() {
    final salonId = FirebaseAuth.instance.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('salonId', isEqualTo: salonId)
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  Future<void> updateBookingStatus(String bookingId, String status) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .update({'status': status});
  }

  int _selectedIndex = 0;
  Map<String, dynamic>? _activeSession;
  bool _isScheduleExpanded = false;

  Map<int, List<Map<String, dynamic>>> _monthlyRequests = {};

  int getVisitCount(String customerName) {
    return salesHistory.where((sale) => sale['customer'] == customerName).length;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkMode ? const Color(0xFF121212) : Colors.white;
    final cardColor = _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black;

    return Theme(
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: cardColor,
          elevation: 0,
          title: Text(_isScheduleExpanded ? "Full Schedule" : "Manager Console",
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: Icon(_isDarkMode ? Icons.wb_sunny : Icons.nightlight_round, color: _isDarkMode ? Colors.orange : Colors.indigo),
              onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
            ),
            IconButton(icon: Icon(Icons.logout, color: textColor), onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) =>  AuthScreen()));
            }),
          ],
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: getBookingsStream(),
          builder: (context, snapshot) {
            final bookings = snapshot.data ?? [];

            return IndexedStack(
              index: _selectedIndex,
              children: [
                DashboardHomeContent(
                  isDarkMode: _isDarkMode,
                  isExpanded: _isScheduleExpanded,
                  onToggleExpand: () =>
                      setState(() => _isScheduleExpanded = !_isScheduleExpanded),
                  onVerified: (booking) =>
                      setState(() { _activeSession = booking; _selectedIndex = 1; }),
                  onOpenCalendar: () => _showCalendarDialog(),
                  onOpenServiceEditor: () => _showServiceEditor(context),
                  currentEarnings: totalDailyEarnings,
                  bookings: bookings,
                  salesHistory: salesHistory,
                  dailyTarget: _dailyGoal,
                  onTargetChanged: (newGoal) =>
                      setState(() => _dailyGoal = newGoal),
                ),
                ActiveSessionPage(
                  isDarkMode: _isDarkMode,
                  sessionData: _activeSession,
                  bookings: bookings,
                  onClear: () {
                    if (_activeSession != null) {
                      // Update Firestore when session finished
                      if (_activeSession?['id'] != null) {
                        FirebaseFirestore.instance
                            .collection('bookings')
                            .doc(_activeSession!['id'])
                            .update({'status': 'completed'});
                      }
                      final service = salonServices.firstWhere(
                            (s) => s['name'] == _activeSession!['service'],
                        orElse: () => {"name": "Service", "price": 0},
                      );
                      setState(() {
                        salesHistory.add({
                          "customer": _activeSession!['customer'],
                          "service": _activeSession!['service'],
                          "price": service['price'],
                          "time": DateTime.now(),
                        });
                        totalDailyEarnings += service['price'];
                        _activeSession = null;
                      });
                      _showReceipt(
                        salesHistory.last['customer'],
                        salesHistory.last['service'],
                        salesHistory.last['price'],
                      );
                    }
                  },
                ),
                FullCalendarPage(
                  requests: _monthlyRequests,
                  isDarkMode: _isDarkMode,
                  onApprove: (day, index) => _approveRequest(day, index),
                ),
                InsightsPage(
                  salesHistory: salesHistory,
                  isDarkMode: _isDarkMode,
                ),
                ProfileScreen(
                  onOpenSettings: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SettingsScreen(
                          isAutoApprove: _isAutoApproveEnabled,
                          onToggleAutoApprove: (val) =>
                              setState(() => _isAutoApproveEnabled = val),
                          isGapProtectorEnabled: _isGapProtectorEnabled,
                          gapDuration: _gapDuration,
                          onToggleGapProtector: (val) =>
                              setState(() => _isGapProtectorEnabled = val),
                          onGapDurationChanged: (val) =>
                              setState(() => _gapDuration = val),
                        ),
                      ),
                    );
                  },
                  onOpenServices: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditServicesScreen(),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.teal,
          onPressed: _addNewBooking,
          child: const Icon(Icons.person_add_alt_1, color: Colors.white),
        ),
        bottomNavigationBar: Container(
          margin: const EdgeInsets.fromLTRB(40, 0, 40, 30), // Slimmer width (40 instead of 20)
          height: 55, // Leaner height
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.black.withOpacity(0.7) : Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(Icons.grid_view_rounded, 0),
              _buildNavItem(Icons.bolt_rounded, 1),
              _buildNavItem(Icons.calendar_today_rounded, 2),
              _buildNavItem(Icons.analytics_rounded, 3),
              _buildNavItem(Icons.person_rounded, 4),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildNavItem(IconData icon, int index) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(8),
        child: Icon(
          icon,
          size: 22,
          color: isSelected ? Colors.teal : Colors.grey.withOpacity(0.5),
        ),
      ),
    );
  }


  void _addNewBooking() {
    String newName = "";
    String selectedService = salonServices[0]['name'];
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("New Walk-in"),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(decoration: const InputDecoration(labelText: "Customer Name"), onChanged: (val) => newName = val),
            const SizedBox(height: 15),
            DropdownButton<String>(
              value: selectedService,
              isExpanded: true,
              items: salonServices.map((s) => DropdownMenuItem<String>(value: s['name'], child: Text("${s['name']} (₹${s['price']})"))).toList(),
              onChanged: (val) => setDialogState(() => selectedService = val!),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(onPressed: () async {
              if (newName.isNotEmpty) {
    await FirebaseFirestore.instance.collection('bookings').add({
      "time": "Just Now",
      "customer": newName,
      "service": selectedService,
      "color": "teal",
      "isVerified": false,
      "salonId": FirebaseAuth.instance.currentUser!.uid,
      "status": "confirmed",
      "createdAt": FieldValue.serverTimestamp(),
    });
                Navigator.pop(context);
              }
            }, child: const Text("Add")),
          ],
        ),
      ),
    );
  }

  void _showCalendarDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          title: Text("Quick Scheduler", style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black)),
          content: SizedBox(
            width: 350,
            height: 450,
            child: Column(
              children: [

                _buildCalendarGrid(setDialogState),
                const Divider(height: 30),
                const Text("Pending for this day:", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                Expanded(
                  child: _buildPopupRequestList(_selectedDayForPopup, setDialogState),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
          ],
        ),
      ),
    );
  }


  int _selectedDayForPopup = DateTime.now().day;

  Widget _buildCalendarGrid(StateSetter setDialogState) {
    return GridView.builder(
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 5, crossAxisSpacing: 5),
      itemCount: 30,
      itemBuilder: (context, index) {
        int day = index + 1;
        bool hasPending = _monthlyRequests.containsKey(day);
        bool isSelected = _selectedDayForPopup == day;

        return InkWell(
          onTap: () => setDialogState(() => _selectedDayForPopup = day),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? Colors.teal : (hasPending ? Colors.purple.withOpacity(0.1) : Colors.transparent),
              borderRadius: BorderRadius.circular(8),
              border: hasPending ? Border.all(color: Colors.purple, width: 0.5) : null,
            ),
            child: Text("$day", style: TextStyle(
              color: isSelected ? Colors.white : (hasPending ? Colors.purple : (_isDarkMode ? Colors.white : Colors.black)),
              fontWeight: hasPending || isSelected ? FontWeight.bold : FontWeight.normal,
            )),
          ),
        );
      },
    );
  }

  Widget _buildPopupRequestList(int day, StateSetter setDialogState) {
    final requests = _monthlyRequests[day] ?? [];
    if (requests.isEmpty) return const Center(child: Text("Clear!", style: TextStyle(color: Colors.grey)));

    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, i) => ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(requests[i]['customer'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        subtitle: Text(requests[i]['service'], style: const TextStyle(fontSize: 11)),
        trailing: IconButton(
          icon: const Icon(Icons.check_circle, color: Colors.teal, size: 20),
          onPressed: () {

            _approveRequest(day, i);
            setDialogState(() {});
          },
        ),
      ),
    );
  }

  void _showServiceEditor(BuildContext context) {
    showModalBottomSheet(context: context, builder: (context) => Container(padding: const EdgeInsets.all(20), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text("Pricing Manager", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ...salonServices.map((s) => ListTile(leading: Icon(s['icon'] as IconData), title: Text(s['name']), trailing: Text("₹${s['price']}"))),
    ])));
  }

  void _showReceipt(String customer, String serviceName, int price) {
    int visits = getVisitCount(customer);
    double gst = price * 0.05;
    double total = price + gst;
    showDialog(context: context, barrierDismissible: false, builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 60),
        const Text("Payment Success", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        if (visits > 1) Container(margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(10)), child: Text("Loyal Customer: $visits Visits", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold))),
        const Divider(height: 30),
        _receiptRow("Customer", customer),
        _receiptRow("Service", serviceName),
        _receiptRow("Total", "₹${total.toStringAsFixed(2)}", isBold: true),
        const SizedBox(height: 20),
        ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Done")),
      ]),
    ));
  }

  Widget _receiptRow(String label, String value, {bool isBold = false}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : null))]);
  }
  void _approveRequest(int day, int requestIndex) async {

      var request = _monthlyRequests[day]![requestIndex];
      await FirebaseFirestore.instance.collection('bookings').add({
        "time": request['time'],
        "customer": request['customer'],
        "service": request['service'],
        "color": "purple",
        "isVerified": false,
        "salonId": FirebaseAuth.instance.currentUser!.uid,
        "status": "pending",
        "createdAt": FieldValue.serverTimestamp(),
      });
      setState(() {
      _monthlyRequests[day]!.removeAt(requestIndex);
      if (_monthlyRequests[day]!.isEmpty) {
        _monthlyRequests.remove(day);
      }
    });
  }
  void _handleNewIncomingRequest(Map<String, dynamic> newRequest, int day) async {
    String finalTime = newRequest['time'];

    if (_isGapProtectorEnabled) {
      finalTime = "${newRequest['time']} (+${_gapDuration}m Gap)";
    }

    if (_isAutoApproveEnabled) {
        await FirebaseFirestore.instance.collection('bookings').add({
          "time": finalTime,
          "customer": newRequest['customer'],
          "service": newRequest['service'],
          "color": "teal",
          "isVerified": false,
          "salonId": FirebaseAuth.instance.currentUser!.uid,
          "status": "pending",
          "createdAt": FieldValue.serverTimestamp(),
        });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Auto-Approved: ${newRequest['customer']}"))
      );
    } else {
      setState(() {
        if (!_monthlyRequests.containsKey(day)) {
          _monthlyRequests[day] = [];
        }
        _monthlyRequests[day]!.add(newRequest);
      });
    }
  }  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Automation Settings", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Tailor how the app handles your business flow.", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const Divider(height: 40),


              _buildSettingToggle(
                title: "Instant Booking",
                description: "Automatically approve incoming requests if the time slot is currently empty.",
                value: _isAutoApproveEnabled,
                onChanged: (val) {
                  setModalState(() => _isAutoApproveEnabled = val);
                  setState(() => _isAutoApproveEnabled = val);
                },
              ),


            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingToggle({required String title, required String description, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: SwitchListTile(
        activeColor: Colors.teal,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(description, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
  void showEmergencyRequest(String name, String service, String time) async {
    // This pushes the screen on top of everything
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true, // Makes it feel like a system event
        builder: (context) => EmergencyRequestScreen(
          customerName: name,
          service: service,
          requestedTime: time,
        ),
      ),
    );

    if (result != null && result != "REJECTED") {
      // Logic to add to your schedule automatically!
      print("Accepted for: $result");
    }
  }
}

class DashboardHomeContent extends StatefulWidget {
  final bool isDarkMode, isExpanded;
  final VoidCallback onToggleExpand, onOpenCalendar, onOpenServiceEditor;
  final Function(Map<String, dynamic>) onVerified;
  final double currentEarnings, dailyTarget;
  final List<Map<String, dynamic>> bookings, salesHistory;
  final Function(double) onTargetChanged;

  const DashboardHomeContent({super.key, required this.isDarkMode, required this.isExpanded, required this.onToggleExpand, required this.onVerified, required this.onOpenCalendar, required this.onOpenServiceEditor, required this.currentEarnings, required this.bookings, required this.salesHistory, required this.dailyTarget, required this.onTargetChanged});

  @override
  State<DashboardHomeContent> createState() => _DashboardHomeContentState();
}

class _DashboardHomeContentState extends State<DashboardHomeContent> {
  String _selectedMainMetric = 'Revenue';

  Color _mapColor(String? colorName) {
    switch (colorName) {
      case "teal":
        return Colors.teal;
      case "purple":
        return Colors.purple;
      case "orange":
        return Colors.orange;
      case "blue":
        return Colors.blue;
      case "pink":
        return Colors.pink;
      default:
        return Colors.grey; // fallback
    }
  }

  void _verifyOTP(int index) {
    TextEditingController ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Verify ${widget.bookings[index]['customer']}"),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          maxLength: 4,
          decoration: const InputDecoration(hintText: "Enter any 4 digits (e.g. 1234)"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.length == 4) {
                setState(() {

                  widget.bookings[index]['isVerified'] = true;
                  FirebaseFirestore.instance
                      .collection('bookings')
                      .doc(widget.bookings[index]['id'])
                      .update({
                    'isVerified': true,
                    'status': 'in_progress',
                  });
                });
                Navigator.pop(context);


                widget.onVerified(widget.bookings[index]);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Verified! Moving to Active Session...")),
                );
              }
            },
            child: const Text("Verify"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : Colors.black;
    final cardColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isDarkMode
              ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
              : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SingleChildScrollView(
          child: Column(
            children: [

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Today's Flow",
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w300, letterSpacing: -1.5, color: textColor.withOpacity(0.9)),
                    ),
                    const SizedBox(height: 8),
                    Text("You have ${widget.bookings.length} sessions scheduled.",
                      style: TextStyle(fontSize: 16, color: Colors.grey[500], fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),


              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 180, height: 180,
                      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
                        BoxShadow(color: Colors.teal.withOpacity(0.1), blurRadius: 40, spreadRadius: 10),
                      ]),
                    ),
                    SizedBox(
                      width: 150, height: 150,
                      child: CircularProgressIndicator(
                        value: (widget.currentEarnings / widget.dailyTarget).clamp(0.0, 1.0),
                        strokeWidth: 4, color: Colors.teal, backgroundColor: Colors.grey[200],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("₹${widget.currentEarnings.toInt()}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text("of ₹${widget.dailyTarget.toInt()}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),


              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOutCubic,
                height: widget.isExpanded ? 550 : 180,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  children: [

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Today's Schedule", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                          Row(
                            children: [
                              IconButton(icon: const Icon(Icons.inventory_2_outlined, color: Colors.teal, size: 18), onPressed: widget.onOpenServiceEditor),
                              IconButton(icon: const Icon(Icons.calendar_month, color: Colors.teal, size: 18), onPressed: widget.onOpenCalendar),
                              IconButton(
                                icon: Icon(widget.isExpanded ? Icons.close_fullscreen_rounded : Icons.open_in_full_rounded, color: Colors.teal, size: 18),
                                onPressed: widget.onToggleExpand,
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    const Divider(indent: 20, endIndent: 20, height: 1),

                    Expanded(
                      child: widget.isExpanded
                          ? GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.1,
                        ),
                        itemCount: widget.bookings.length,
                        itemBuilder: (context, index) => _buildMiniGlassTile(widget.bookings[index], index, true),
                      )
                          : ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                        itemCount: widget.bookings.length,
                        itemBuilder: (context, index) => _buildMiniGlassTile(widget.bookings[index], index, false),
                      ),
                    ),
                  ],
                ),
              ),


              if (!widget.isExpanded) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _viewChip("Revenue", Icons.bar_chart),
                      _viewChip("Activity", Icons.pie_chart),
                      _viewChip("History", Icons.history),
                    ],
                  ),
                ),
                SizedBox(
                  height: 300,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildSelectedView(textColor, cardColor),
                  ),
                ),
              ],

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildMiniGlassTile(Map<String, dynamic> booking, int index, bool isGrid) {
    return GestureDetector(
      onTap: () => _showBookingDetails(context, booking, index),
      child: Container(
        width: isGrid ? null : 140,
        margin: isGrid ? EdgeInsets.zero : const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: widget.isDarkMode ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(width: 6, height: 6, decoration: BoxDecoration(color: _mapColor(booking['color'] as String?), shape: BoxShape.circle),),
                const SizedBox(width: 6),
                Text(
                    booking['time']?.toString() ?? '',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: widget.isDarkMode ? Colors.white70 : Colors.black54
                    )
                ),
              ],
            ),
            const Spacer(),
            Flexible(
              child: Text(
                booking['customer']?.toString() ?? 'Customer',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.isDarkMode ? Colors.white : Colors.black87
                ),
              ),
            ),
            Flexible(
              child: Text(
                booking['service']?.toString() ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    height: 1.2
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildGlassBookingCard(Map<String, dynamic> booking, int index) {
    return GestureDetector(
      onTap: () => _showBookingDetails(context, booking, index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _mapColor(booking['color'] as String?),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
              color: _mapColor(booking['color'] as String?).withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2
                  )
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booking['customer'],
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                        color: widget.isDarkMode ? Colors.white : Colors.black87
                    ),
                  ),
                  Text(
                    booking['service'],
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w400
                    ),
                  ),
                ],
              ),
            ),
            Text(
              booking['time'],
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  color: widget.isDarkMode ? Colors.white70 : Colors.black54
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTargetEditor() {
    TextEditingController targetCtrl = TextEditingController(text: widget.dailyTarget.toStringAsFixed(0));
    showDialog(context: context, builder: (context) => AlertDialog(
      title: const Text("Set Goal"),
      content: TextField(controller: targetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(prefixText: "₹ ")),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")), ElevatedButton(onPressed: () { widget.onTargetChanged(double.parse(targetCtrl.text)); Navigator.pop(context); }, child: const Text("Save"))],
    ));
  }

  Widget _viewChip(String label, IconData icon) {
    bool isSel = _selectedMainMetric == label;
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: ChoiceChip(avatar: Icon(icon, size: 14, color: isSel ? Colors.white : Colors.teal), label: Text(label, style: TextStyle(color: isSel ? Colors.white : (widget.isDarkMode ? Colors.white : Colors.black))), selected: isSel, selectedColor: Colors.teal, onSelected: (v) => setState(() => _selectedMainMetric = label)));
  }

  Widget _buildSelectedView(Color textColor, Color cardColor) {
    switch (_selectedMainMetric) {
      case 'Revenue':
        return _buildRevenueWave(textColor);
      case 'Activity':
        return _buildActivityView(textColor);
      default:
        return const Center(child: Text("History coming soon..."));
    }
  }
  Widget _buildActivityView(Color textColor) {
    return Center(
      child: Text("Activity Map coming soon...",
          style: TextStyle(color: textColor.withOpacity(0.5))),
    );
  }
  Widget _buildRevenueWave(Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Weekly Growth",
                style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600)),
            const Text("+12.5%",
                style: TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: SfCartesianChart(
            plotAreaBorderWidth: 0,
            margin: EdgeInsets.zero,

            primaryXAxis: const CategoryAxis(
              isVisible: false,
              majorGridLines: MajorGridLines(width: 0),
            ),
            primaryYAxis: const NumericAxis(
              isVisible: false,
              majorGridLines: MajorGridLines(width: 0),
            ),
            series: <CartesianSeries<ChartData, String>>[
              SplineAreaSeries<ChartData, String>(
                dataSource: _getWaveData(),
                xValueMapper: (ChartData data, _) => data.x,
                yValueMapper: (ChartData data, _) => data.y,

                gradient: LinearGradient(
                  colors: [
                    Colors.teal.withOpacity(0.4),
                    Colors.teal.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderColor: Colors.teal,
                borderWidth: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pieChart(Color textColor) {

    Map<String, int> counts = {};
    for (var sale in widget.salesHistory) {
      counts[sale['service']] = (counts[sale['service']] ?? 0) + 1;
    }

    if (counts.isEmpty) return const Center(child: Text("Finish a session to see stats"));


    var sortedEntries = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    String topServiceName = sortedEntries.first.key;
    int topServiceCount = sortedEntries.first.value;
    double total = widget.salesHistory.length.toDouble();


    List<Color> palette = [Colors.teal, Colors.purple, Colors.orange, Colors.blue];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("SERVICE ACTIVITY", style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold, fontSize: 10, color: Colors.teal.withOpacity(0.8))),
        const SizedBox(height: 20),
        Expanded(
          child: Row(
            children: [

              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 130,
                    height: 130,
                    child: CircularProgressIndicator(
                      value: (topServiceCount / total),
                      strokeWidth: 14,
                      color: palette[0],
                      backgroundColor: palette[0].withOpacity(0.1),
                      strokeCap: StrokeCap.round,
                    ),
                  ),

                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(topServiceName, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14)),
                      Text("$topServiceCount Sales", style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 25),

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: sortedEntries.asMap().entries.map((entry) {
                    int idx = entry.key;
                    var e = entry.value;

                    return _buildLegendItem(e.key, e.value, total, textColor, palette[idx % palette.length]);
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String title, int count, double total, Color textColor, Color dotColor) {
    int percent = ((count / total) * 100).toInt();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: textColor.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
          Text("$percent%", style: TextStyle(color: dotColor, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _historyList(Color textColor) {
    if (widget.salesHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 40, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 10),
            const Text("No recent activity", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }


    final recentSales = widget.salesHistory.reversed.take(5).toList();

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: recentSales.length,
      itemBuilder: (context, i) {
        final sale = recentSales[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [

              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: Colors.teal, shape: BoxShape.circle),
                  ),
                  if (i != recentSales.length - 1)
                    Container(width: 2, height: 30, color: Colors.teal.withOpacity(0.1)),
                ],
              ),
              const SizedBox(width: 15),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sale['customer'], style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(sale['service'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("₹${sale['price']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14)),
                  const Text("Completed", style: TextStyle(color: Colors.grey, fontSize: 9)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _lineChart(Color textColor, Color cardColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("REVENUE TREND", style: TextStyle(letterSpacing: 1.2, fontWeight: FontWeight.bold, fontSize: 10, color: Colors.teal.withOpacity(0.8))),
                Text("₹${widget.currentEarnings}", style: TextStyle(color: textColor, fontSize: 28, fontWeight: FontWeight.bold)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.arrow_upward, size: 12, color: Colors.green),
                  Text(" 12%", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          ],
        ),
        const SizedBox(height: 30),
        Expanded(
          child: Stack(
            children: [

              Padding(
                padding: const EdgeInsets.fromLTRB(5, 20, 5, 40),
                child: CustomPaint(
                  size: Size.infinite,
                  painter: CurvePainter(
                    dataPoints: [0.3, 0.4, 0.7, 0.5, 0.8, 0.6, 0.9],
                    lineColor: Colors.teal,
                  ),
                ),
              ),


              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ["M", "T", "W", "T", "F", "S", "S"]
                        .map((d) => Text(d, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  void _showBookingDetails(BuildContext context, Map<String, dynamic> booking, int index) {
    final status = booking['status'] ?? 'pending';
    final isEmergency = booking['isEmergency'] == true; // future use

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Expanded(
              child: Text(
                booking['customer'] ?? 'Customer',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            // Emergency badge — ready for future use
            if (isEmergency)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "EMERGENCY",
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _detailRow(Icons.bolt, "Service", booking['service'] ?? ''),
            _detailRow(Icons.calendar_today, "Date", booking['date'] ?? 'Walk-in'),
            _detailRow(Icons.access_time, "Time", booking['time'] ?? ''),
            _detailRow(
              Icons.info_outline,
              "Status",
              status == 'confirmed'
                  ? "✅ Confirmed"
                  : status == 'cancelled'
                  ? "❌ Cancelled"
                  : "⏳ Pending",
            ),
            _detailRow(
              Icons.verified_user,
              "Check-in",
              booking['isVerified'] == true ? "Verified" : "Not yet",
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),

          // EMERGENCY: approve/decline — shown only for emergency bookings (future)
          if (isEmergency && status == 'pending') ...[
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(booking['id'])
                    .update({'status': 'cancelled'});
                Navigator.pop(context);
              },
              child: const Text("Decline"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('bookings')
                    .doc(booking['id'])
                    .update({'status': 'confirmed'});
                Navigator.pop(context);
              },
              child: const Text("Approve"),
            ),
          ],

          // NORMAL: only verify & start when customer arrives
          if (!isEmergency && booking['isVerified'] != true)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                _verifyOTP(index);
              },
              child: const Text("Verify & Start"),
            ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.teal),
          const SizedBox(width: 10),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }
}


class ProfessionalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.teal..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    var points = [Offset(0, size.height * 0.8), Offset(size.width * 0.3, size.height * 0.5), Offset(size.width * 0.6, size.height * 0.7), Offset(size.width, size.height * 0.2)];
    var path = Path()..moveTo(points[0].dx, points[0].dy);
    for (var p in points) path.lineTo(p.dx, p.dy);
    canvas.drawPath(path, paint);
    for (var p in points) canvas.drawCircle(p, 4, Paint()..color = Colors.teal);
  }
  @override bool shouldRepaint(covariant CustomPainter old) => false;
}

class ProfessionalPiePainter extends CustomPainter {
  final Map<String, int> data;
  final bool isDarkMode;
  ProfessionalPiePainter(this.data, this.isDarkMode);
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2.5;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 30..strokeCap = StrokeCap.round;
    if (data.isEmpty) { paint.color = Colors.grey.withOpacity(0.2); canvas.drawCircle(center, radius, paint); return; }
    double total = data.values.fold(0, (sum, item) => sum + item);
    double startAngle = -pi / 2;
    List<Color> colors = [Colors.indigo, Colors.teal, Colors.orange, Colors.purple];
    int colorIndex = 0;
    data.forEach((key, value) {
      final sweepAngle = (value / total) * 2 * pi;
      paint.color = colors[colorIndex % colors.length];
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle - 0.1, false, paint);
      startAngle += sweepAngle;
      colorIndex++;
    });
    final tp = TextPainter(text: TextSpan(text: "${total.toInt()}", style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 24)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }
  @override bool shouldRepaint(covariant CustomPainter old) => true;
}


class ActiveSessionPage extends StatefulWidget {
  final bool isDarkMode;
  final Map<String, dynamic>? sessionData;
  final VoidCallback onClear;
  final List<Map<String, dynamic>> bookings;
  const ActiveSessionPage({super.key, required this.isDarkMode, this.sessionData, required this.onClear, required this.bookings,});
  @override
  State<ActiveSessionPage> createState() => _ActiveSessionPageState();
}
class _ActiveSessionPageState extends State<ActiveSessionPage> {
  bool _isZenMode = false;
  Widget _buildZenLayout() {
    final textColor = widget.isDarkMode ? Colors.white : Colors.black;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.sessionData?['customer']?.toUpperCase() ?? "",
            style: TextStyle(
                fontSize: 42,
                letterSpacing: 8,
                fontWeight: FontWeight.w200, // Ultra-thin "Jobs" style
                color: textColor
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.sessionData?['service'] ?? "",
            style: const TextStyle(color: Colors.teal, letterSpacing: 4),
          ),
          // Add a long-press gesture to exit Zen Mode
          IconButton(
            icon: const Icon(Icons.close_fullscreen, size: 16, color: Colors.grey),
            onPressed: () => setState(() => _isZenMode = false),
          )
        ],
      ),
    );
  }
  Widget _buildPulseGhostCard(bool isDarkMode, List<Map<String, dynamic>> allBookings, Map<String, dynamic>? currentSession) {
    // 1. Find the index of the current session to identify who is "Next"
    int currentIndex = allBookings.indexWhere((b) => b['customer'] == currentSession?['customer']);

    // 2. Grab the next person in the list
    final nextBooking = (currentIndex != -1 && currentIndex + 1 < allBookings.length)
        ? allBookings[currentIndex + 1]
        : null;

    if (nextBooking == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          // THE SHOP PULSE DOT
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Logic: If they are checked in, show Teal, otherwise Grey
              color: nextBooking['isVerified'] == true ? Colors.teal : Colors.grey,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("UP NEXT", style: TextStyle(fontSize: 10, letterSpacing: 1, color: Colors.grey, fontWeight: FontWeight.bold)),
                Text(nextBooking['customer'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
              ],
            ),
          ),
          Text(nextBooking['service'], style: const TextStyle(color: Colors.teal, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
  Widget _buildActiveHeader(Map<String, dynamic>? session, Color textColor) {
    if (session == null) return const Center(child: Text("No Active Session"));
    return GestureDetector(
      // TESTING TRIGGER: Long press the name to simulate an emergency
        onLongPress: () => _triggerTestEmergency(context),
        child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: Icon(Icons.visibility_off_outlined, color: textColor.withOpacity(0.3)),
                onPressed: () {
                  setState(() {
                    _isZenMode = true;
                  });
                },
              ),
            ],
          ),
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.teal.withOpacity(0.1),
            child: Icon(Icons.person, size: 50, color: Colors.teal),
          ),
          const SizedBox(height: 20),
          Text(
            session['customer']?.toString() ?? '',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor),
          ),
          Text(
            session['service']?.toString() ?? '',
            style: TextStyle(fontSize: 18, color: Colors.teal, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ),
    );
  }
  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : Colors.black;
    final nextBooking = widget.bookings.length > 1 ? widget.bookings[1] : null;
    final auraColor = _getAuraColor(nextBooking);
    return AnimatedContainer(
      duration: const Duration(seconds: 2), // The slow Jobs-style breath
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [
            auraColor,
            widget.isDarkMode ? const Color(0xFF121212) : Colors.white
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent, // Keeps the Aura visible
        body: _isZenMode
            ? _buildZenLayout() // If Zen is on, show the minimalist view
            : Column(           // If Zen is off, show your EXACT existing code
          children: [
            const SizedBox(height: 60),
            _buildActiveHeader(widget.sessionData, textColor),
            const Spacer(),
            _buildPulseGhostCard(widget.isDarkMode, widget.bookings, widget.sessionData),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: widget.onClear,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                ),
                child: const Text("FINISH SESSION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
  Color _getAuraColor(Map<String, dynamic>? nextBooking) {
    if (nextBooking == null) return Colors.transparent;


    if (nextBooking['isVerified'] == true) {
      return Colors.teal.withOpacity(0.15);
    }


    return Colors.transparent;
  }
}

class FullCalendarPage extends StatefulWidget {
  final Map<int, List<Map<String, dynamic>>> requests;
  final bool isDarkMode;
  final Function(int, int) onApprove;

  const FullCalendarPage({
    super.key,
    required this.requests,
    required this.isDarkMode,
    required this.onApprove,
  });

  @override
  State<FullCalendarPage> createState() => _FullCalendarPageState();
}

class _FullCalendarPageState extends State<FullCalendarPage> {
  int _selectedDay = DateTime.now().day;


  double _calculatePotentialRevenue() {
    double total = 0;
    widget.requests.forEach((day, list) {
      for (var req in list) {
        total += (req['price'] ?? 0).toDouble();
      }
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : Colors.black;
    final cardColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

    return Column(
      children: [

        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              _buildStatCard("Total", "${widget.requests.length}", Colors.blue),
              _buildStatCard("Potential", "₹${_calculatePotentialRevenue().toInt()}", Colors.green),
              _buildStatCard("Month", "March", Colors.orange),
            ],
          ),
        ),


        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: 31,
            itemBuilder: (context, index) {
              int day = index + 1;
              bool isSelected = _selectedDay == day;
              bool hasBookings = widget.requests.containsKey(day);

              return GestureDetector(
                onTap: () => setState(() => _selectedDay = day),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.teal : (widget.isDarkMode ? Colors.grey[900] : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected ? Border.all(color: Colors.tealAccent, width: 2) : null,
                  ),
                  child: Center(
                    child: Text("$day", style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : textColor)),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),


        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("March $_selectedDay Requests", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                const Text("Swipe Right to Approve • Swipe Left to Decline", style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 15),
                Expanded(child: _buildSwipableList(_selectedDay)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildSwipableList(int day) {
    final dayRequests = widget.requests[day] ?? [];
    if (dayRequests.isEmpty) {
      return const Center(child: Text("No pending requests.", style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      itemCount: dayRequests.length,
      itemBuilder: (context, i) {
        final item = dayRequests[i];
        return Dismissible(
          key: Key(item['customer'] + i.toString()),
          background: _swipeBackground(Alignment.centerLeft, Colors.green, Icons.check, "APPROVE"),
          secondaryBackground: _swipeBackground(Alignment.centerRight, Colors.red, Icons.close, "DECLINE"),
          onDismissed: (direction) {
            if (direction == DismissDirection.startToEnd) {
              widget.onApprove(day, i);
            } else {
              setState(() => widget.requests[day]!.removeAt(i));
            }
          },
          child: Card(
            color: widget.isDarkMode ? Colors.black26 : Colors.white,
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.teal, child: Icon(Icons.person, color: Colors.white, size: 16)),
              title: Text(item['customer'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${item['service']} at ${item['time']}"),
              trailing: Text("₹${item['price']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ),
          ),
        );
      },
    );
  }

  Widget _swipeBackground(Alignment align, Color color, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: align,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (align == Alignment.centerLeft) Icon(icon, color: Colors.white),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          if (align == Alignment.centerRight) Icon(icon, color: Colors.white),
        ],
      ),
    );
  }
}

class InsightsPage extends StatefulWidget {
  final List<Map<String, dynamic>> salesHistory;
  final bool isDarkMode;

  const InsightsPage({super.key, required this.salesHistory, required this.isDarkMode});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDarkMode ? Colors.white : Colors.black;
    final cardColor = widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;


    Map<String, int> serviceCounts = {};
    double totalRevenue = 0;
    for (var sale in widget.salesHistory) {
      serviceCounts[sale['service']] = (serviceCounts[sale['service']] ?? 0) + 1;
      totalRevenue += (sale['price'] ?? 0);
    }


    final filteredHistory = widget.salesHistory.where((s) {
      final name = s['customer'].toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Business Insights", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 20),


          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: "Search customer history...",
              prefixIcon: const Icon(Icons.search, color: Colors.teal),
              filled: true,
              fillColor: cardColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 25),


          Row(
            children: [
              _buildMetricCard("Total Revenue", "₹${totalRevenue.toInt()}", Icons.payments, Colors.green, cardColor),
              _buildMetricCard("Avg/Service", "₹${widget.salesHistory.isEmpty ? 0 : (totalRevenue / widget.salesHistory.length).toInt()}", Icons.trending_up, Colors.blue, cardColor),
            ],
          ),
          const SizedBox(height: 25),


          Text(_searchQuery.isEmpty ? "Top Customers" : "Search Results",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 10),


          _searchQuery.isEmpty
              ? _buildTopCustomersList(cardColor, textColor)
              : _buildFilteredResults(filteredHistory, cardColor, textColor),

          const SizedBox(height: 25),


          Text("Service Popularity", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 10),
          _buildServiceBars(serviceCounts, cardColor, textColor),
        ],
      ),
    );
  }



  Widget _buildMetricCard(String title, String val, IconData icon, Color color, Color cardBg) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.2))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCustomersList(Color cardBg, Color textColor) {
    Map<String, int> customerVisits = {};
    for (var sale in widget.salesHistory) {
      customerVisits[sale['customer']] = (customerVisits[sale['customer']] ?? 0) + 1;
    }
    var sorted = customerVisits.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20)),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sorted.length > 3 ? 3 : sorted.length,
        itemBuilder: (context, i) => ListTile(
          leading: CircleAvatar(backgroundColor: Colors.teal.withOpacity(0.1), child: Text("${i + 1}")),
          title: Text(sorted[i].key, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          trailing: Text("${sorted[i].value} Visits"),
        ),
      ),
    );
  }

  Widget _buildFilteredResults(List<Map<String, dynamic>> results, Color cardBg, Color textColor) {
    if (results.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No customers found.")));
    return Container(
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20)),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: results.length,
        itemBuilder: (context, i) => ListTile(
          title: Text(results[i]['customer'], style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          subtitle: Text("${results[i]['service']} • ID: ${results[i]['phone'] ?? 'Walk-in'}"),
          trailing: Text("₹${results[i]['price']}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildServiceBars(Map<String, int> counts, Color cardBg, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: counts.entries.map((entry) {
          double percentage = (entry.value / widget.salesHistory.length);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(entry.key, style: TextStyle(color: textColor)),
                  Text("${(percentage * 100).toStringAsFixed(0)}%"),
                ]),
                const SizedBox(height: 5),
                LinearProgressIndicator(value: percentage, backgroundColor: Colors.grey[300], color: Colors.teal),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
class CurvePainter extends CustomPainter {
  final List<double> dataPoints;
  final Color lineColor;
  CurvePainter({required this.dataPoints, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()..color = Colors.grey.withOpacity(0.1)..strokeWidth = 1;
    final linePaint = Paint()..color = lineColor..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round;
    final dotPaint = Paint()..color = lineColor;
    final dotOutline = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2;

    for (int i = 0; i <= 4; i++) {
      double y = size.height - (i * size.height / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final path = Path();
    double dx = size.width / (dataPoints.length - 1);
    path.moveTo(0, size.height - (dataPoints[0] * size.height));
    for (int i = 0; i < dataPoints.length - 1; i++) {
      double x1 = i * dx;
      double y1 = size.height - (dataPoints[i] * size.height);
      double x2 = (i + 1) * dx;
      double y2 = size.height - (dataPoints[i + 1] * size.height);
      path.cubicTo(x1 + dx / 4, y1, x2 - dx / 4, y2, x2, y2);
    }
    canvas.drawPath(path, linePaint);
    for (int i = 0; i < dataPoints.length; i++) {
      double x = i * dx;
      double y = size.height - (dataPoints[i] * size.height);
      canvas.drawCircle(Offset(x, y), 5, dotPaint);
      canvas.drawCircle(Offset(x, y), 5, dotOutline);
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
class ChartData {
  ChartData(this.x, this.y);
  final String x;
  final double y;
}


List<ChartData> _getWaveData() {
  return [
    ChartData('Mon', 1200),
    ChartData('Tue', 1900),
    ChartData('Wed', 1500),
    ChartData('Thu', 2800),
    ChartData('Fri', 2200),
    ChartData('Sat', 3500),
    ChartData('Sun', 3100),
  ];
}
void _triggerTestEmergency(BuildContext context) async {
  // We import the screen we just made
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => const EmergencyRequestScreen(
        customerName: "Ishan (Test)",
        service: "Emergency Fade",
        requestedTime: "NOW",
      ),
    ),
  );

  if (result != null) {
    debugPrint("Emergency Screen Result: $result");
    // Show a small toast to confirm the choice worked
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Action: $result"),
        backgroundColor: Colors.teal,
      ),
    );
  }
}


