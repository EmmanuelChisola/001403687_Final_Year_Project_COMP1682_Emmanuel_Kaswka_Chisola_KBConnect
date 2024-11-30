import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kbconnect/home.dart';

class EditProfilePage extends StatefulWidget {
  final User? user;
  EditProfilePage({this.user});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  File? _image;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: widget.user?.displayName ?? '');
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        await widget.user?.updateProfile(displayName: _displayNameController.text);
        await widget.user?.reload(); // Reload the user to reflect changes
        User? updatedUser = FirebaseAuth.instance.currentUser;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.green,
            content: Text('Profile updated successfully!'),
          ),
        );
        Navigator.pop(context, updatedUser); // Return updated user to previous screen
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to update profile: $e'),
          ),
        );
      }
    }
  }

  void _cancelUpdate() {
    Navigator.pop(context); // To go back to the previous screen
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    String? photoURL = widget.user?.photoURL;
    String firstLetter = widget.user?.email?.isNotEmpty == true
        ? widget.user!.email![0].toUpperCase()
        : 'U'; // Default to 'U' if email is empty or null

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Colors.blueGrey,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                  backgroundColor: Colors.blueGrey,
                  child: photoURL == null
                      ? Text(
                    firstLetter,
                    style: const TextStyle(fontSize: 40, color: Colors.white),
                  )
                      : null,
                ),
              ),
              Center(
                  child: InkWell(
                    onTap: _pickImage, // Trigger image picker on tap
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(2.0),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.blueAccent,
                        size: 24.0,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                'Email',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.user?.email ?? 'N/A',
                  style: TextStyle(fontSize: 18.0, color: Colors.blueGrey[900]),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30.0),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: _updateProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 20), // Space between buttons
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ChurchHomePage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[500],
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
