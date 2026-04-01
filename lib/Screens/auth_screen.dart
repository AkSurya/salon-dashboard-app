import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {

  List<String> _selectedServices = [];

  final Map<String, List<String>> _serviceCategories = {
    'Hair Services': ['Cutting', 'Styling (Blowouts)', 'Coloring', 'Extensions', 'Treatments'],
    'Skin Care & Facials': ['Facials', 'Cleansing', 'Detan', 'Acne Treatments'],
    'Hair Removal': ['Waxing', 'Threading', 'Sugaring'],
    'Nail Services': ['Manicures', 'Pedicures', 'Gel Nails', 'Nail Art'],
    'Makeup & Beauty': ['Bridal', 'Evening Makeup', 'Eyelash Application', 'Eyebrow Tinting'],
    'Body & Spa': ['Massages', 'Body Polishing', 'Aromatherapy'],
  };

  PageController _pageController = PageController();
  int _currentStep = 0;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _salonNameController = TextEditingController();

  void _nextStep() {
    _pageController.nextPage(
        duration: Duration(milliseconds: 300), curve: Curves.easeIn);
  }

  void _prevStep() {
    _pageController.previousPage(
        duration: Duration(milliseconds: 300), curve: Curves.easeIn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: _prevStep,
        )
            : null,
      ),
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        onPageChanged: (int page) {
          setState(() {
            _currentStep = page;
          });
        },
        children: [
          _buildLoginLanding(),
          _buildEmailPhoneStep(),
          _buildSalonTypeStep(),
          _buildSalonDetailsStep(),
          _buildServiceSelectionStep(),
        ],
      ),
    );
  }

  Widget _buildLoginLanding() {
    return Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cut, size: 80, color: Colors.teal),
          SizedBox(height: 20),
          Text("Salon Manager", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          SizedBox(height: 40),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              side: BorderSide(color: Colors.grey.shade300),
            ),
            icon: Icon(Icons.login),
            label: Text("Sign in with Google"),
            onPressed: _nextStep,
          ),
          SizedBox(height: 15),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50), backgroundColor: Colors.teal),
            child: Text("Sign Up with Email", style: TextStyle(color: Colors.white)),
            onPressed: _nextStep,
          ),
        ],
      ),
    );
  }

  Widget _buildEmailPhoneStep() {
    return Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Account Details", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          TextField(decoration: InputDecoration(labelText: "Email Address", border: OutlineInputBorder())),
          SizedBox(height: 15),
          TextField(decoration: InputDecoration(labelText: "Phone Number", border: OutlineInputBorder())),
          Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50), backgroundColor: Colors.teal),
            child: Text("Next", style: TextStyle(color: Colors.white)),
            onPressed: _nextStep,
          ),
        ],
      ),
    );
  }

  Widget _buildSalonTypeStep() {
    return Padding(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Select Salon Type", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 30),
          _typeBox("Male Only", Icons.man),
          _typeBox("Female Only", Icons.woman),
          _typeBox("Unisex", Icons.wc),
        ],
      ),
    );
  }

  Widget _typeBox(String title, IconData icon) {
    return GestureDetector(
      onTap: _nextStep,
      child: Container(
        margin: EdgeInsets.only(bottom: 15),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.teal.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.teal, size: 30),
            SizedBox(width: 20),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSalonDetailsStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Salon Details", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          TextField(decoration: InputDecoration(labelText: "Salon Name *", border: OutlineInputBorder())),
          SizedBox(height: 15),
          TextField(decoration: InputDecoration(labelText: "Salon Phone *", border: OutlineInputBorder())),
          SizedBox(height: 15),
          TextField(maxLines: 3, decoration: InputDecoration(labelText: "Salon Address *", border: OutlineInputBorder())),
          SizedBox(height: 20),
          Text("Photos (Optional)", style: TextStyle(color: Colors.grey)),
          SizedBox(height: 10),
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.add_a_photo, color: Colors.grey),
          ),
          SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50), backgroundColor: Colors.teal),
            child: Text("Continue to Services", style: TextStyle(color: Colors.white)),
            onPressed: () {
              _nextStep();
            },
          ),
        ],
      ),
    );
  }


  Widget _buildServiceSelectionStep() {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("Select Your Services", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        Container(
          height: 80,
          width: double.infinity,
          color: Colors.teal.withOpacity(0.05),
          child: _selectedServices.isEmpty
              ? Center(child: Text("No services selected yet", style: TextStyle(color: Colors.grey)))
              : ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            children: _selectedServices.map((service) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ActionChip(
                  backgroundColor: Colors.teal,
                  label: Text(service, style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    setState(() {
                      _selectedServices.remove(service);
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: ListView(
            children: _serviceCategories.keys.map((category) {
              return ExpansionTile(
                title: Text(category, style: TextStyle(fontWeight: FontWeight.bold)),
                children: _serviceCategories[category]!.map((service) {
                  bool isAdded = _selectedServices.contains(service);
                  return ListTile(
                    title: Text(service),
                    trailing: Icon(
                      isAdded ? Icons.remove_circle : Icons.add_circle,
                      color: isAdded ? Colors.red : Colors.teal,
                    ),
                    onTap: () {
                      setState(() {
                        if (isAdded) {
                          _selectedServices.remove(service);
                        } else {
                          _selectedServices.add(service);
                        }
                      });
                    },
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.teal),
            child: Text("Finish & Go to Dashboard", style: TextStyle(color: Colors.white)),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();

              await prefs.setBool('isLoggedIn', true);


              await prefs.setBool('showTutorial', true);

              await prefs.setStringList('userServices', _selectedServices);

              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => DashboardScreen()),
                    (route) => false,
              );
            },
          ),
        ),
      ],
    );
  }
}