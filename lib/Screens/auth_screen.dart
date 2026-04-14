import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dashboard_screen.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  List<String> _selectedServices = [];
  String _selectedSalonType = '';
  bool _isLoading = false;
  bool _obscurePassword = true;

  final Map<String, List<String>> _serviceCategories = {
    'Hair Services': ['Cutting', 'Styling (Blowouts)', 'Coloring', 'Extensions', 'Treatments'],
    'Skin Care & Facials': ['Facials', 'Cleansing', 'Detan', 'Acne Treatments'],
    'Hair Removal': ['Waxing', 'Threading', 'Sugaring'],
    'Nail Services': ['Manicures', 'Pedicures', 'Gel Nails', 'Nail Art'],
    'Makeup & Beauty': ['Bridal', 'Evening Makeup', 'Eyelash Application', 'Eyebrow Tinting'],
    'Body & Spa': ['Massages', 'Body Polishing', 'Aromatherapy'],
  };

  final PageController _pageController = PageController();
  int _currentStep = 0;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _salonNameController = TextEditingController();
  final TextEditingController _salonPhoneController = TextEditingController();
  final TextEditingController _salonAddressController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  void _nextStep() {
    _pageController.nextPage(
        duration: Duration(milliseconds: 300), curve: Curves.easeIn);
  }

  void _prevStep() {
    _pageController.previousPage(
        duration: Duration(milliseconds: 300), curve: Curves.easeIn);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ── Email/Password Sign Up ──────────────────────────────────────────────────
  Future<void> _signUpWithEmail() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showError('Please enter email and password');
      return;
    }
    if (_passwordController.text.trim().length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      setState(() => _isLoading = false);
      _nextStep(); // go to salon type step
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      if (e.code == 'email-already-in-use') {
        // Try signing in instead
        try {
          await _auth.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
          // Existing user — check if salon already set up
          await _checkExistingUser();
        } on FirebaseAuthException catch (e2) {
          _showError(e2.message ?? 'Sign in failed');
        }
      } else {
        _showError(e.message ?? 'Sign up failed');
      }
    }
  }

  // ── Google Sign In ──────────────────────────────────────────────────────────
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      setState(() => _isLoading = false);
      await _checkExistingUser();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Google Sign In failed. Try again.');
    }
  }

  // ── Check if user already has a salon set up ────────────────────────────────
  Future<void> _checkExistingUser() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final doc = await _firestore.collection('salons').doc(user.uid).get();
    if (doc.exists) {
      // Already registered — go straight to dashboard
      await _saveLocalPrefs(doc.data()!);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
            (route) => false,
      );
    } else {
      // New Google user — continue setup
      _nextStep();
    }
  }

  // ── Save salon data to Firestore ────────────────────────────────────────────
  Future<void> _saveAndFinish() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_salonNameController.text.trim().isEmpty ||
        _salonPhoneController.text.trim().isEmpty ||
        _salonAddressController.text.trim().isEmpty) {
      _showError('Please fill in all required salon details');
      return;
    }

    if (_selectedServices.isEmpty) {
      _showError('Please select at least one service');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final salonData = {
        'ownerId': user.uid,
        'ownerEmail': user.email,
        'ownerPhone': _phoneController.text.trim(),
        'name': _salonNameController.text.trim(),
        'phone': _salonPhoneController.text.trim(),
        'address': _salonAddressController.text.trim(),
        'salonType': _selectedSalonType,
        'services': _selectedServices,
        'rating': 0.0,
        'totalReviews': 0,
        'isOpen': true,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('salons').doc(user.uid).set(salonData);
      await _saveLocalPrefs(salonData);

      setState(() => _isLoading = false);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
            (route) => false,
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to save salon data. Try again.');
    }
  }

  Future<void> _saveLocalPrefs(Map<String, dynamic> data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setBool('showTutorial', true);
    await prefs.setString('salonName', data['name'] ?? '');
    await prefs.setStringList(
        'userServices', List<String>.from(data['services'] ?? []));
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
              setState(() => _currentStep = page);
            },
            children: [
              _buildLoginLanding(),
              _buildEmailPhoneStep(),
              _buildSalonTypeStep(),
              _buildSalonDetailsStep(),
              _buildServiceSelectionStep(),
            ],
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.4),
            child: Center(
              child: CircularProgressIndicator(color: Colors.teal),
            ),
          ),
      ],
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
          Text("Salon Manager",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
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
            onPressed: _signInWithGoogle,
          ),
          SizedBox(height: 15),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.teal),
            child:
            Text("Sign Up with Email", style: TextStyle(color: Colors.white)),
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
          Text("Account Details",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
                labelText: "Email Address", border: OutlineInputBorder()),
          ),
          SizedBox(height: 15),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
                labelText: "Phone Number", border: OutlineInputBorder()),
          ),
          SizedBox(height: 15),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: "Password",
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscurePassword
                    ? Icons.visibility_off
                    : Icons.visibility),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
          Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.teal),
            child: Text("Next", style: TextStyle(color: Colors.white)),
            onPressed: _signUpWithEmail,
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
          Text("Select Salon Type",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
      onTap: () {
        setState(() => _selectedSalonType = title);
        _nextStep();
      },
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
            Text(title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
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
          Text("Salon Details",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          TextField(
            controller: _salonNameController,
            decoration: InputDecoration(
                labelText: "Salon Name *", border: OutlineInputBorder()),
          ),
          SizedBox(height: 15),
          TextField(
            controller: _salonPhoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
                labelText: "Salon Phone *", border: OutlineInputBorder()),
          ),
          SizedBox(height: 15),
          TextField(
            controller: _salonAddressController,
            maxLines: 3,
            decoration: InputDecoration(
                labelText: "Salon Address *", border: OutlineInputBorder()),
          ),
          SizedBox(height: 20),
          Text("Photos (Optional)", style: TextStyle(color: Colors.grey)),
          SizedBox(height: 10),
          Container(
            height: 100,
            width: 100,
            decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.add_a_photo, color: Colors.grey),
          ),
          SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.teal),
            child: Text("Continue to Services",
                style: TextStyle(color: Colors.white)),
            onPressed: () {
              if (_salonNameController.text.trim().isEmpty ||
                  _salonPhoneController.text.trim().isEmpty ||
                  _salonAddressController.text.trim().isEmpty) {
                _showError('Please fill in all required fields');
                return;
              }
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
          child: Text("Select Your Services",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ),
        Container(
          height: 80,
          width: double.infinity,
          color: Colors.teal.withOpacity(0.05),
          child: _selectedServices.isEmpty
              ? Center(
              child: Text("No services selected yet",
                  style: TextStyle(color: Colors.grey)))
              : ListView(
            scrollDirection: Axis.horizontal,
            padding:
            EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            children: _selectedServices.map((service) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ActionChip(
                  backgroundColor: Colors.teal,
                  label: Text(service,
                      style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    setState(() => _selectedServices.remove(service));
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
                title: Text(category,
                    style: TextStyle(fontWeight: FontWeight.bold)),
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
            child: Text("Finish & Go to Dashboard",
                style: TextStyle(color: Colors.white)),
            onPressed: _saveAndFinish,
          ),
        ),
      ],
    );
  }
}