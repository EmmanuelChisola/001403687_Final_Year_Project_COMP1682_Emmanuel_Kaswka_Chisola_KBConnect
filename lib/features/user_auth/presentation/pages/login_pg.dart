import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kbconnect/features/user_auth/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:kbconnect/features/user_auth/presentation/pages/password_reset.dart';
import 'package:kbconnect/features/user_auth/presentation/pages/sign_up_page.dart';
import 'package:kbconnect/features/user_auth/presentation/pages/widgets/form_container_widget.dart';
import 'package:kbconnect/home.dart';
class LoginPg extends StatefulWidget {
  const LoginPg({super.key});

  @override
  State<LoginPg> createState() => _LoginPgState();
}

class _LoginPgState extends State<LoginPg> {
  final _auth = FirebaseAuthServices();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLoading = false;
  bool isMember = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }
  Future<bool> checkIfUserIsMember() async {
    User? user = FirebaseAuth.instance.currentUser;
    String email = user?.email ?? '';
    try {
      // Query Firestore to check if the email exists in the "members" collection
      QuerySnapshot memberDocs = await FirebaseFirestore.instance
          .collection('members')
          .where('email', isEqualTo: email) // Query for email field
          .get();
      return memberDocs.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  _login() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    final user = await _auth.loginUserWithEmailAndPassword(
      _email.text,
      _password.text,
    );

    if (user != null) {
      // Show the Snackbar first
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green[400],
          content: const Text("User has logged in successfully"),
        ),
      );
      // Delay navigation to allow Snackbar to display
      await Future.delayed(const Duration(seconds: 1));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ChurchHomePage()),
      );
    } else {
      final email = _email.text.trim();

      // Check if the email exists in the 'members' collection
      final memberSnapshot = await FirebaseFirestore.instance
          .collection('members')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (memberSnapshot.docs.isEmpty) {
        // Email is not found in members collection
        log("Email not found in members collection");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red[300],
          content: const Text("User not found."),
        ));
      } else {
        // Email exists in the members collection, so set isMember to true
        setState(() {
          isMember = true;
        });

        // Check if the member has a password
        final memberData = memberSnapshot.docs.first.data();
        final passwordSet = memberData['passwordSet'] ?? false;

        if (!passwordSet) {
          log("Password not set for this member, navigating to set password page.");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SetPasswordPage(email: email),
            ),
          );
        } else {
          // If login fails for other reasons, show an error message
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.red[300],
            content: const Text("Login failed, please check your credentials"),
          ));
        }
      }
    }

    setState(() {
      _isLoading = false; // Stop loading
    });
  }


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF8B4513), // SaddleBrown
            Color(0xFFD2B48C), // Tan
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent, // Transparent AppBar
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              const Text(
                "Welcome!!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Login to your account",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 50),
              FormContainerWidget(
                hintText: "Email",
                isPasswordField: false,
                controller: _email,
              ),
              const SizedBox(height: 20),
              FormContainerWidget(
                hintText: "Password",
                isPasswordField: true,
                controller: _password,
              ),
              const SizedBox(height: 15),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ForgotPassword()),
                    );
                  },
                  child: const Text(
                    "Forgot password?",
                    style: TextStyle(
                      color: Colors.white70,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: _isLoading ? null : _login,
                child: Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.brown[700],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: _isLoading
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                        : const Text(
                      "Login",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account?",
                    style: TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => SignUpPage()),
                            (route) => false,
                      );
                    },
                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}



class SetPasswordPage extends StatefulWidget {
  final String email;


  const SetPasswordPage({super.key, required this.email});

  @override
  State<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool isMemeber = true;
  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _setPassword() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validate passwords
    if (newPassword != confirmPassword) {
      _showSnackBar("Passwords do not match", isError: true);
      return;
    }
    if (newPassword.length < 6) {
      _showSnackBar("Password must be at least 6 characters long", isError: true);
      return;
    }

    try {
      // Check if the user exists in Firestore members collection
      final memberSnapshot = await FirebaseFirestore.instance
          .collection('members')
          .where('email', isEqualTo: widget.email)
          .limit(1)
          .get();

      if (memberSnapshot.docs.isNotEmpty) {
        // User already exists in Firestore, so update their password
        final memberDoc = memberSnapshot.docs.first;
        final memberData = memberDoc.data();
        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          // If the user is logged in, update their password
          await user.updatePassword(newPassword);

          // Update Firestore document to set 'isPasswordSet' to true
          await FirebaseFirestore.instance
              .collection('members')
              .doc(widget.email)
              .update({'isPasswordSet': true});

          _showSnackBar("Password updated successfully");
          log("Password updated successfully for ${widget.email}");

          // Navigate to the login page
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        // Email does not exist in the Firestore members collection
        _showSnackBar("No member found with this email. Please sign up first.", isError: true);
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showSnackBar("Email is already in use. Try signing in.", isError: true);
      } else if (e.code == 'weak-password') {
        _showSnackBar("Password is too weak. Choose a stronger password.", isError: true);
      } else {
        _showSnackBar("Error: ${e.message}", isError: true);
      }
      log("FirebaseAuthException: ${e.code}");
    } catch (e) {
      log("Error setting password: $e");
      _showSnackBar("An error occurred. Please try again.", isError: true);
    }
  }

  Future<User?> _getUserByEmail(String email) async {
    try {
      final signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (signInMethods.isNotEmpty) {
        // User exists, return the user
        final User? user = FirebaseAuth.instance.currentUser;
        return user;
      }
    } catch (e) {
      log("Error fetching user: $e");
    }
    return null;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: isError ? Colors.red[300] : Colors.green[400],
      content: Text(message),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF8B4513), // SaddleBrown
            Color(0xFFD2B48C), // Tan
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Set a New Password",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                FormContainerWidget(
                  hintText: "New Password",
                  isPasswordField: true,
                  controller: _newPasswordController,
                ),
                const SizedBox(height: 10),
                FormContainerWidget(
                  hintText: "Confirm Password",
                  isPasswordField: true,
                  controller: _confirmPasswordController,
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _setPassword,
                  child: Container(
                    width: double.infinity,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.brown[700],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Center(
                      child: Text(
                        "Set Password",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}