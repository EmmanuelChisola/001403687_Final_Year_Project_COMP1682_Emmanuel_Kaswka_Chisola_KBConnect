import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AddMember(),
    );
  }
}

class AddMember extends StatefulWidget {
  const AddMember({super.key});

  @override
  _AddMemberState createState() => _AddMemberState();
}

class _AddMemberState extends State<AddMember> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _gender = 'Male'; // Default value for gender
  String _occupationStatus = 'Student';
  final TextEditingController _occupationController = TextEditingController();
  String _maritalStatus = 'Single'; // Default value for marital status
  File? _image; // To store the selected image

  final List<String> _ministries = [
    'Children\'s Ministry',
    'Campus Outreach Ministry',
    'Conference Ministry',
    'Electronic Media Ministry',
    'Hope Ministry',
    'Library Ministry',
    'Publishing Ministry',
    'Marriage Ministry',
    'Music Ministry',
    'Preacher\'s College',
    'Women\'s Ministry',
    'Men\'s Ministry',
    'Youth Ministry - Junior',
    'Youth Ministry - Intermediate',
    'Youth Ministry - Senior'
  ];

  Map<String, bool> _selectedMinistries = {
    'Children\'s Ministry': false,
    'Campus Outreach Ministry': false,
    'Conference Ministry': false,
    'Electronic Media Ministry': false,
    'Hope Ministry': false,
    'Library Ministry': false,
    'Publishing Ministry': false,
    'Marriage Ministry': false,
    'Music Ministry': false,
    'Preacher\'s College': false,
    'Women\'s Ministry': false,
    'Men\'s Ministry': false,
    'Youth Ministry - Junior': false,
    'Youth Ministry - Intermediate': false,
    'Youth Ministry - Senior': false,
  };

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final selectedMinistries = _selectedMinistries.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      // Upload the image to Firebase Storage
      String? imageUrl;
      if (_image != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('member_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        await storageRef.putFile(_image!);
        imageUrl = await storageRef.getDownloadURL();
      }

      final memberData = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'gender': _gender,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'ministries': selectedMinistries,
        'occupationStatus': _occupationStatus,
        'occupation': _occupationController.text,
        'maritalStatus': _maritalStatus,
        'imageUrl': imageUrl,
        'timestamp': Timestamp.now(),
        'isPasswordSet': false,
      };

      // Save the member data to Firestore
      await FirebaseFirestore.instance.collection('members').add(memberData);
      // Clear the form
      _formKey.currentState!.reset();
      _firstNameController.clear();
      _lastNameController.clear();
      _emailController.clear();
      _phoneController.clear();
      _occupationController.clear();
      setState(() {
        _gender = 'Male';
        _occupationStatus = 'Student';
        _maritalStatus = 'Single';
        _selectedMinistries.updateAll((key, value) => false);
        _image = null; // Reset the image
      });
      // Show a success message or navigate back
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Member added successfully!'))
      );
      Navigator.pop(context); // Optionally go back after adding
    }
  }

  void _cancelAdd() {
    Navigator.pop(context); // Simply pop the current screen to go back
  }

  List<Widget> _buildMinistryCheckboxes() {
    return _ministries.map((ministry) {
      return CheckboxListTile(
        title: Text(ministry),
        value: _selectedMinistries[ministry],
        onChanged: (bool? value) {
          setState(() {
            _selectedMinistries[ministry] = value!;
          });
        },
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add a new member'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 50.0,
                    backgroundColor: Colors.blueAccent,
            backgroundImage: _image != null ? FileImage(_image!) : null,
            child: _image == null
                ? const Text(
              'M',
                      style: TextStyle(
                        fontSize: 40.0,
                        color: Colors.white,
                      ),
                    )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 130,
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
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter first name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter last name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              const Text(
                'Gender',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile(
                      title: const Text("Male"),
                      value: "Male",
                      groupValue: _gender,
                      onChanged: (value) {
                        setState(() {
                          _gender = value.toString();
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile(
                      title: const Text("Female"),
                      value: "Female",
                      groupValue: _gender,
                      onChanged: (value) {
                        setState(() {
                          _gender = value.toString();
                        });
                      },
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter phone number';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _occupationStatus,
                decoration: const InputDecoration(labelText: 'Occupation Status'),
                items: ['Student', 'Unemployed', 'Employed'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _occupationStatus = newValue!;
                  });
                },
              ),
              if (_occupationStatus != 'Unemployed')
                TextFormField(
                  controller: _occupationController,
                  decoration: const InputDecoration(labelText: 'Place of occupation'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter place of occupation';
                    }
                    return null;
                  },
                ),
              DropdownButtonFormField<String>(
                value: _maritalStatus,
                decoration: const InputDecoration(labelText: 'Marital Status'),
                items: ['Single', 'Married'].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _maritalStatus = newValue!;
                  });
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Select the ministries they are part of:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Column(
                children: _buildMinistryCheckboxes(),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Submit'),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _cancelAdd,
                    child: const Text('Cancel'),
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
