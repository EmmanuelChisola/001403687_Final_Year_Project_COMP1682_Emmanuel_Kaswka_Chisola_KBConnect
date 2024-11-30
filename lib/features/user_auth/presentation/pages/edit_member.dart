import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class EditMember extends StatefulWidget {
  final String? memberId;

  const EditMember({Key? key, this.memberId}) : super(key: key);

  @override
  _EditMemberState createState() => _EditMemberState();
}

class _EditMemberState extends State<EditMember> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _gender = 'Male';  //Default value
  String _occupationStatus = 'Student'; //Default value
  final TextEditingController _occupationController = TextEditingController();
  String _maritalStatus = 'Single'; // Default value
  File? _image;
  bool _isLoading = false;


  final List<String> _ministries = [
    'Campus Outreach Ministry',
    'Children\'s Ministry',
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

  @override
  void initState() {
    super.initState();
    if (widget.memberId != null) {
      _loadMemberData(widget.memberId!);
    }
  }
  Future<void> _loadMemberData(String memberId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final memberDoc =
      await FirebaseFirestore.instance.collection('members').doc(memberId).get();
      if (memberDoc.exists) {
        final memberData = memberDoc.data()!;
        setState(() {
          _firstNameController.text = memberData['firstName'] ?? '';
          _lastNameController.text = memberData['lastName'] ?? '';
          _gender = memberData['gender'] ?? 'Male';
          _emailController.text = memberData['email'] ?? '';
          _phoneController.text = memberData['phone'] ?? '';
          _occupationStatus = memberData['occupationStatus'] ?? 'Student';
          _occupationController.text = memberData['occupation'] ?? '';
          _maritalStatus = memberData['maritalStatus'] ?? 'Single';
          _selectedMinistries = Map<String, bool>.fromIterable(_ministries,
              key: (ministry) => ministry,
              value: (ministry) =>
                  (memberData['ministries'] ?? []).contains(ministry));

          String? imageUrl = memberData['imageUrl'];
          if (imageUrl != null && imageUrl.isNotEmpty) {
            _image = null;
          }
        });
      }
    } catch (e) {
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
        try {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('member_images')
              .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

          await storageRef.putFile(_image!);
          imageUrl = await storageRef.getDownloadURL();
        } catch (e) {
          print('Image upload failed: $e');
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  backgroundColor: Colors.red,
                  content: Text('Image upload failed! Please try again.')));
          return;
        }
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
        'imageUrl': imageUrl, // Store the image URL instead of the path
        'timestamp': Timestamp.now(), // Update timestamp field
      };

      if (widget.memberId != null) {
        // Update existing member document
        await FirebaseFirestore.instance.collection('members').doc(widget.memberId).update(memberData);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                backgroundColor: Colors.green,
                content: Text('Member updated successfully!')));
      }
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
        _image = null;
      });
      Navigator.pop(context);
    }
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
        title: Text(widget.memberId != null ? 'Edit Member' : 'Edit Member'),
      ),
      body: _isLoading ? Container(
        color: Colors.white,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      )  :Padding(
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
                        ? Text(
                      '${_firstNameController.text.isNotEmpty ? _firstNameController.text[0] : ''}'
                          '${_lastNameController.text.isNotEmpty ? _lastNameController.text[0] : ''}',
                      style: const TextStyle(
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
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a first name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a last name';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _gender,
                onChanged: (String? newValue) {
                  setState(() {
                    _gender = newValue!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Gender'),
                items: <String>['Male', 'Female']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone Number'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a phone number';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _occupationStatus,
                onChanged: (String? newValue) {
                  setState(() {
                    _occupationStatus = newValue!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Occupation Status'),
                items: <String>[
                  'Student',
                  'Employed',
                  'Unemployed',
                  'Self-employed',
                  'Retired',
                  'Others',
                ].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              TextFormField(
                controller: _occupationController,
                decoration: const InputDecoration(labelText: 'Occupation'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an occupation';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _maritalStatus,
                onChanged: (String? newValue) {
                  setState(() {
                    _maritalStatus = newValue!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Marital Status'),
                items: <String>['Single', 'Married']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16.0),
              const Text(
                'Select Ministries:',
                style: TextStyle(fontSize: 16.0),
              ),
              ..._buildMinistryCheckboxes(),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: _submitForm,
                    child: const Text('Update'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      )

    );
  }
}
