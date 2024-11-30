import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';


class ProfileScreen extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _homeAddressController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  String _status = 'Single';
  String _occupation = 'Student';
  bool _isEditing = false;
  File? _image;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        log('No image selected.');
      }
    });
  }

  Future<void> _takePicture() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        log('No image selected.');
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            'Profile page'
          ),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 35.0,
          color: Colors.black,

        ),
        backgroundColor: Colors.brown[600],
        centerTitle: true,
        elevation: 0.0,
      ),
      // bottomNavigationBar: followButton(),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      backgroundImage: _image != null
                          ? FileImage(_image!)
                          : const AssetImage('assets/ninja.jpeg') as ImageProvider,
                      radius: 40.0,
                    ),
                    Positioned(
                      right: -15,
                      bottom: -9,
                      child: PopupMenuButton<int>(
                        icon: const Icon(Icons.camera_alt, color: Colors.black),
                        onSelected: (int result) {
                          if (result == 0) {
                            _pickImage();
                          } else if (result == 1) {
                            _takePicture();
                          }
                        },
                        itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<int>>[
                          const PopupMenuItem<int>(
                            value: 0,
                            child: Text('Select from gallery'),
                          ),
                          const PopupMenuItem<int>(
                            value: 1,
                            child: Text('Take a picture'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(
                height: 35.0,
                color: Colors.white60,
              ),
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: Colors.black.withOpacity(0.6)),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                style: const TextStyle(color: Colors.black),
                enabled: _isEditing,
              ),
              const SizedBox(height: 10.0),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name',
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: Colors.black.withOpacity(0.6)),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                style: const TextStyle(color: Colors.black),
                enabled: _isEditing,
              ),
              const SizedBox(height: 10.0),
              TextFormField(
                controller: _homeAddressController,
                decoration: InputDecoration(
                  labelText: 'Home Address',
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: Colors.black.withOpacity(0.6)),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                style: const TextStyle(color: Colors.black),
                enabled: _isEditing,
              ),
              const SizedBox(height: 10.0),
              TextFormField(
                controller: _phoneNumberController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: Colors.black.withOpacity(0.6)),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                style: const TextStyle(color: Colors.black),
                enabled: _isEditing,
              ),
              const SizedBox(height: 10.0),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: Colors.black.withOpacity(0.6)),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                style: const TextStyle(color: Colors.black),
                enabled: _isEditing,
              ),
              const SizedBox(height: 10.0),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: Colors.black.withOpacity(0.6)),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                items: ['Single', 'Married'].map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(
                      status,
                      style: const TextStyle(color: Colors.black), // Set text color
                    ),
                  );
                }).toList(),
                onChanged: _isEditing
                    ? (String? newValue) {
                  setState(() {
                    _status = newValue!;
                  });
                }
                    : null,
              ),
              const SizedBox(height: 10.0),
              DropdownButtonFormField<String>(
                value: _occupation,
                decoration: InputDecoration(
                  labelText: 'Occupation',
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: Colors.black.withOpacity(0.6)),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                items: ['Student', 'Employed', 'Working'].map((String occupation) {
                  return DropdownMenuItem<String>(
                    value: occupation,
                    child: Text(
                      occupation,
                      style: const TextStyle(color: Colors.black), // Set text color
                    ),
                  );
                }).toList(),
                onChanged: _isEditing
                    ? (String? newValue) {
                  setState(() {
                    _occupation = newValue!;
                  });
                }
                    : null,
              ),
              const SizedBox(height: 10.0),
              TextFormField(
                controller: _placeController,
                decoration: InputDecoration(
                  labelText: 'Place',
                  border: const OutlineInputBorder(),
                  labelStyle: TextStyle(color: Colors.black.withOpacity(0.6)),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                style: const TextStyle(color: Colors.black),
                enabled: _isEditing,
              ),
              const SizedBox(height: 20.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isEditing = !_isEditing;
                      });
                    },
                    child: Text(_isEditing ? 'Update' : 'Edit'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Save form data
                        setState(() {
                          _isEditing = false;
                        });
                      }
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GetClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0.0, size.height / 2.2);
    path.lineTo(size.width + 125.0, 0.0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return true;
  }
}