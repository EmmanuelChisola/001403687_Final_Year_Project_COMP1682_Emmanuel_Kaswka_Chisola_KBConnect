import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';

class FormSubmission {
  static Future<void> submitForm({
    required String collectionName,
    required Map<String, dynamic> formData,
    PlatformFile? attachment,

    required BuildContext context,

  }) async {

    try {

      DocumentReference docRef = await FirebaseFirestore.instance
          .collection(collectionName)
          .add(formData);

      String? fileUrl;

      // If there is an attachment, upload it
      if (attachment != null) {
        try {
          // Create a reference for the file to be uploaded
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('$collectionName/${attachment.name}'); // Using the document ID for storage path

          // Convert PlatformFile to File
          File file = File(attachment.path!);
          // Upload the file directly using 'putFile'
          await storageRef.putFile(file);
          // Get the download URL after the upload completes
          fileUrl = await storageRef.getDownloadURL();

          await docRef.update({'fileUrl': fileUrl});
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading attachment: $e')),
          );
        }

      }

      // Success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.green[600],
            content: Text('Form submitted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.red[400],
            content: Text('Error submitting form: $e')),
      );
    }
  }
}

String? validateNotEmpty(String? value, String fieldName) {
  if (value == null || value.trim().isEmpty) {
    return '\$fieldName cannot be empty';
  }
  return null;
}

String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Email cannot be empty';
  }
  final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}\$');
  if (!emailRegex.hasMatch(value)) {
    return 'Enter a valid email address';
  }
  return null;
}

String? validatePhoneNumber(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Contact Number cannot be empty';
  }
  final phoneRegex = RegExp(r'^\d{10,15}\$');
  if (!phoneRegex.hasMatch(value)) {
    return 'Enter a valid phone number';
  }
  return null;
}

String? validateDate(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Date cannot be empty';
  }
  try {
    DateTime.parse(value);
  } catch (_) {
    return 'Enter a valid date (YYYY-MM-DD)';
  }
  return null;
}

class FormsPage extends StatefulWidget {
  const FormsPage({Key? key});

  @override
  _FormsPageState createState() => _FormsPageState();
}

class _FormsPageState extends State<FormsPage> {
  PlatformFile? _baptismFile;
  PlatformFile? _membershipFile;
  bool _isMarried = false;
  bool _isLoading = false;
  bool _hideBaptismForm = false;
  bool _hideMembershipForm = false;
  bool _canAccessLeaveForm = false;

  final Map<String, Map<String, TextEditingController>> _formControllers = {
    'baptismFormSubmission': {
      'fullName': TextEditingController(),
      'dob': TextEditingController(),
      'email': TextEditingController(),
      'contactNumber': TextEditingController(),
    },
    'membershipFormSubmissions': {
      'fullName': TextEditingController(),
      'address': TextEditingController(),
      'email': TextEditingController(),
      'contactNumber': TextEditingController(),
      'dateOfApplication': TextEditingController(),
    },
    'marriageFormSubmissions': {
      'fullName': TextEditingController(),
      'spouseName': TextEditingController(),
      'weddingDate': TextEditingController(),
      'email': TextEditingController(),
      'contactNumber': TextEditingController(),
    },
    'leaveFormSubmissions': {
      'fullName': TextEditingController(),
      'reasonLeave': TextEditingController(),
      'startDateLeave': TextEditingController(),
      'endDateLeave': TextEditingController(),
      'email': TextEditingController(),
      'contactNumber': TextEditingController(),
    },
  };

  @override
  void initState() {
    super.initState();
    _checkMaritalStatus();
    _checkUserEmail();
    _checkUserPermissions();
  }

  Future<void> _checkMaritalStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        setState(() {
          _isMarried = snapshot['status'] == 'married';
        });
      } catch (e) {
        print("Error fetching user marital status: $e");
      }
    }
  }

  Future<void> _checkUserEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Fetch user's email
        String userEmail = user.email ?? '';

        // Check if the email exists in the 'members' collection
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('members')
            .where('email', isEqualTo: userEmail)
            .get();

        // If the email exists, set the flags to hide the forms
        setState(() {
          _hideBaptismForm = snapshot.docs.isNotEmpty;
          _hideMembershipForm = snapshot.docs.isNotEmpty;
        });
      } catch (e) {
        print("Error checking email: $e");
      }
    }
  }

  Future<void> _checkUserPermissions() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Check if the user's email ends with '@kabwatabaptistchurch.com'
        if (user.email != null && user.email!.endsWith('@kabwatabaptistchurch.com')) {
          setState(() {
            _canAccessLeaveForm = true;  // Allow access to the leave form
          });
        } else {
          setState(() {
            _canAccessLeaveForm = false;  // Deny access to the leave form
          });
        }
      } catch (e) {
        print("Error checking user permissions: $e");
        setState(() {
          _canAccessLeaveForm = false;
        });
      }
    }
  }


  void _clearFormFields(String collectionName) {
    // Reset the form fields to empty
    if (collectionName == 'baptismFormSubmission') {
      _formControllers['baptismFormSubmission']!['fullName']!.clear();
      _formControllers['baptismFormSubmission']!['dob']!.clear();
      _formControllers['baptismFormSubmission']!['email']!.clear();
      _formControllers['baptismFormSubmission']!['contactNumber']!.clear();
      _baptismFile = null;
    } else if (collectionName == 'membershipFormSubmissions') {
      _formControllers['membershipFormSubmissions']!['fullName']!.clear();
      _formControllers['membershipFormSubmissions']!['address']!.clear();
      _formControllers['membershipFormSubmissions']!['email']!.clear();
      _formControllers['membershipFormSubmissions']!['contactNumber']!.clear();
      _formControllers['membershipFormSubmissions']!['dateOfApplication']!
          .clear();
      _membershipFile = null;
    } else if (collectionName == 'marriageFormSubmissions') {
      _formControllers['marriageFormSubmissions']!['fullName']!.clear();
      _formControllers['marriageFormSubmissions']!['spouseName']!.clear();
      _formControllers['marriageFormSubmissions']!['weddingDate']!.clear();
      _formControllers['marriageFormSubmissions']!['email']!.clear();
      _formControllers['marriageFormSubmissions']!['contactNumber']!.clear();
    } else if (collectionName == 'leaveFormSubmissions') {
      _formControllers['leaveFormSubmissions']!['fullName']!.clear();
      _formControllers['leaveFormSubmissions']!['reasonLeave']!.clear();
      _formControllers['leaveFormSubmissions']!['startDateLeave']!.clear();
      _formControllers['leaveFormSubmissions']!['endDateLeave']!.clear();
      _formControllers['leaveFormSubmissions']!['email']!.clear();
      _formControllers['leaveFormSubmissions']!['contactNumber']!.clear();
    }
  }

  Future<void> _submitForm(String collectionName, Map<String, dynamic> formData,
      PlatformFile? file) async {
    setState(() {
      _isLoading = true;
    });
    await FormSubmission.submitForm(
      collectionName: collectionName,
      formData: formData,
      attachment: file,
      context: context,
    );
    _clearFormFields(collectionName);

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kabwata Baptist Church Forms'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_hideBaptismForm) _buildFormSection('Baptism Form', _buildBaptismForm()),
            if (!_hideMembershipForm) _buildFormSection('Membership Form', _buildMembershipForm()),
            if (!_isMarried) _buildFormSection(
                'Marriage Form', _buildMarriageForm()),
            if (_canAccessLeaveForm) _buildFormSection(
                'Leave Form', _buildLeaveForm()),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection(String title, Widget form) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
              12),
        ),
        color: Color(0xFFEFEBE9),
        child: ExpansionTile(
          title: Text(
            title,
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Color(0xFF6D4C41),
            ),
          ),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: form,
            ),
          ],
        ),
      ),
    );
  }

  // Baptism form
  Widget _buildBaptismForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(_formControllers['baptismFormSubmission']!['fullName']!,
            'Full Name'),
        _buildTextField(
            _formControllers['baptismFormSubmission']!['dob']!, 'Date of Birth',
            isDate: true, isDateOfBirth: true),
        _buildTextField(
            _formControllers['baptismFormSubmission']!['email']!, 'Email'),
        _buildTextField(
            _formControllers['baptismFormSubmission']!['contactNumber']!,
            'Contact Number'),
        _buildBaptismFilePicker(
            _baptismFile, (file) => setState(() => _baptismFile = file)),
        _buildBaptismSubmitButton('baptismFormSubmission', _baptismFile,
            _formControllers['baptismFormSubmission']!),
      ],
    );
  }

  Widget _buildBaptismFilePicker(PlatformFile? file,
      Function(PlatformFile?) onFilePicked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Only show the "Attach Testimony" button if no file is attached
        if (file == null)
          ElevatedButton.icon(
            onPressed: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles();
              if (result != null && result.files.isNotEmpty) {
                onFilePicked(result.files.first);
              }
            },
            icon: const Icon(Icons.attach_file),
            label: const Text('Attach Testimony'),
          ),
        if (file != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Expanded(child: Text(file.name)),
                IconButton(
                  icon: const Icon(
                      Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () => onFilePicked(null), // Remove file
                ),
              ],
            ),
          ),
      ],
    );
  }

  // Membership form
  Widget _buildMembershipForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
            _formControllers['membershipFormSubmissions']!['fullName']!,
            'Full Name'),
        _buildTextField(
            _formControllers['membershipFormSubmissions']!['address']!,
            'Home Address'),
        _buildTextField(
            _formControllers['membershipFormSubmissions']!['email']!, 'Email'),
        _buildTextField(
            _formControllers['membershipFormSubmissions']!['contactNumber']!,
            'Contact Number'),
        _buildTextField(
            _formControllers['membershipFormSubmissions']!['dateOfApplication']!,
            'Date of Application', isDate: true),
        _buildMembershipFilePicker(
            _membershipFile, (file) => setState(() => _membershipFile = file)),
        _buildMembershipSubmitButton(
            'membershipFormSubmissions', _membershipFile,
            _formControllers['membershipFormSubmissions']!),
      ],
    );
  }

  Widget _buildMembershipFilePicker(PlatformFile? file,
      Function(PlatformFile?) onFilePicked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Only show the "Attach Membership Document" button if no file is attached
        if (file == null)
          ElevatedButton.icon(
            onPressed: () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles();
              if (result != null && result.files.isNotEmpty) {
                onFilePicked(result.files.first);
              }
            },
            icon: const Icon(Icons.attach_file),
            label: const Text('Attach Testimony'),
          ),
        if (file != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                Expanded(child: Text(file.name)),
                IconButton(
                  icon: const Icon(
                      Icons.remove_circle_outline, color: Colors.red),
                  onPressed: () => onFilePicked(null), // Remove file
                ),
              ],
            ),
          ),
      ],
    );
  }
  // Marriage form
  Widget _buildMarriageForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
            _formControllers['marriageFormSubmissions']!['fullName']!,
            'Full Name'),
        _buildTextField(
            _formControllers['marriageFormSubmissions']!['spouseName']!,
            'Spouse\'s Name'),
        _buildTextField(
            _formControllers['marriageFormSubmissions']!['weddingDate']!,
            'Wedding Date',
            isDate: true, isWeddingDate: true),
        _buildTextField(
            _formControllers['marriageFormSubmissions']!['email']!, 'Email'),
        _buildTextField(
            _formControllers['marriageFormSubmissions']!['contactNumber']!,
            'Contact Number'),
        _buildMarriageSubmitButton('marriageFormSubmissions', null,
            _formControllers['marriageFormSubmissions']!),
      ],
    );
  }
  // Leave form
  Widget _buildLeaveForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(_formControllers['leaveFormSubmissions']!['fullName']!,
            'Full Name'),
        _buildTextField(
            _formControllers['leaveFormSubmissions']!['reasonLeave']!,
            'Reason for Leave'),
        _buildTextField(
            _formControllers['leaveFormSubmissions']!['startDateLeave']!,
            'Start Date',
            isDate: true, isStartDate: true),
        _buildTextField(
            _formControllers['leaveFormSubmissions']!['endDateLeave']!,
            'End Date',
            isDate: true, isEndDate: true),
        _buildTextField(
            _formControllers['leaveFormSubmissions']!['email']!, 'Email'),
        _buildTextField(
            _formControllers['leaveFormSubmissions']!['contactNumber']!,
            'Contact Number'),
        _buildLeaveSubmitButton('leaveFormSubmissions', null,
            _formControllers['leaveFormSubmissions']!),
      ],
    );
  }

  // TextField builder for form fields
  Widget _buildTextField(TextEditingController controller, String label,
      {bool isDate = false, bool isApplicationDate = false, bool isDateOfBirth = false, bool isWeddingDate = false, bool isEndDate = false, bool isStartDate = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        readOnly: isDate || isApplicationDate,

        onTap: isDate
            ? () async {
          DateTime? pickedDate;

          if (isDateOfBirth) {
            pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
          }
          // For Wedding Date cannot select dates in the past
          else if (isWeddingDate || isEndDate || isStartDate) {
            pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(), // Allow only future dates
              lastDate: DateTime(2101), // Set a reasonable future date
            );
          } else {

            pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(), // Prevent past date selection
              lastDate: DateTime.now(), // Set a reasonable future date
            );
          }

          if (pickedDate != null) {
            controller.text = "${pickedDate.toLocal()}".split(' ')[0];
          }
        }
            : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        // Set the text for the application date automatically
        initialValue: isApplicationDate ? DateTime.now().toLocal()
            .toString()
            .split(' ')[0] : null,
      ),
    );
  }

  Widget _buildBaptismSubmitButton(String collectionName,
      PlatformFile? file,
      Map<String, TextEditingController> formControllers) {
    return ElevatedButton(
      onPressed: _isLoading
          ? null
          : () async {

        String fullName = formControllers['fullName']?.text ?? '';
        String dob = formControllers['dob']?.text ?? '';
        String email = formControllers['email']?.text ?? '';
        String contactNumber = formControllers['contactNumber']?.text ?? '';

        if (fullName.isEmpty || dob.isEmpty || email.isEmpty ||
            contactNumber.isEmpty) {

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'No empty fields allowed in the baptism form'),
              backgroundColor: Colors.red, // Red background for the Snackbar
            ),
          );
          return;
        }

        final formData = {
          'Full Name': fullName,
          'Date of Birth': dob,
          'Email': email,
          'Contact Number': contactNumber,
          'isSeen': false,
        };
        await _submitForm(collectionName, formData, file);
      },
      child: _isLoading
          ? const CircularProgressIndicator()
          : const Text('Submit Baptism Form'),
    );
  }

  Widget _buildMembershipSubmitButton(String collectionName,
      PlatformFile? file,
      Map<String, TextEditingController> formControllers) {
    return ElevatedButton(
      onPressed: _isLoading
          ? null
          : () async {

        String fullName = _formControllers['membershipFormSubmissions']!['fullName']
            ?.text ?? '';
        String address = _formControllers['membershipFormSubmissions']!['address']
            ?.text ?? '';
        String email = _formControllers['membershipFormSubmissions']!['email']
            ?.text ?? '';
        String contactNumber = _formControllers['membershipFormSubmissions']!['contactNumber']
            ?.text ?? '';
        String dateOfApplication = _formControllers['membershipFormSubmissions']!['dateOfApplication']
            ?.text ?? '';

        if (fullName.isEmpty || address.isEmpty || email.isEmpty ||
            contactNumber.isEmpty || dateOfApplication.isEmpty) {

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'No empty fields allowed in the membership form.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final formData = {
          'Full Name': fullName,
          'Home Address': address,
          'Email': email,
          'Contact Number': contactNumber,
          'Date of Application': dateOfApplication,
          'isSeen': false,
        };

        await _submitForm(collectionName, formData, file);
      },
      child: _isLoading
          ? const CircularProgressIndicator()
          : const Text('Submit Membership Form'),
    );
  }

  Widget _buildMarriageSubmitButton(String collectionName,
      PlatformFile? file,
      Map<String, TextEditingController> formControllers) {
    return ElevatedButton(
      onPressed: _isLoading
          ? null
          : () async {
        String fullName = _formControllers['marriageFormSubmissions']!['fullName']
            ?.text ?? '';
        String spouseName = _formControllers['marriageFormSubmissions']!['spouseName']
            ?.text ?? '';
        String weddingDate = _formControllers['marriageFormSubmissions']!['weddingDate']
            ?.text ?? '';
        String email = _formControllers['marriageFormSubmissions']!['email']
            ?.text ?? '';
        String contactNumber = _formControllers['marriageFormSubmissions']!['contactNumber']
            ?.text ?? '';

        if (fullName.isEmpty || spouseName.isEmpty || weddingDate.isEmpty ||
            email.isEmpty || contactNumber.isEmpty) {
          // Show a Snackbar with a red background if any field is empty
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'No empty fields allowed allowed in the marriage form'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final formData = {
          'Full Name': fullName,
          'Spouse\'s Name': spouseName,
          'Wedding Date': weddingDate,
          'Email': email,
          'Contact Number': contactNumber,
          'isSeen': false,
        };

        await _submitForm(collectionName, formData, file);
      },
      child: _isLoading
          ? const CircularProgressIndicator()
          : const Text('Submit Marriage Form'),
    );
  }

  Widget _buildLeaveSubmitButton(String collectionName,
      PlatformFile? file,
      Map<String, TextEditingController> formControllers) {
    return ElevatedButton(
      onPressed: _isLoading
          ? null
          : () async {
        String fullName = formControllers['fullName']?.text ?? '';
        String reasonLeave = formControllers['reasonLeave']?.text ?? '';
        String startDateLeave = formControllers['startDateLeave']?.text ?? '';
        String endDateLeave = formControllers['endDateLeave']?.text ?? '';
        String email = formControllers['email']?.text ?? '';
        String contactNumber = formControllers['contactNumber']?.text ?? '';

        if (fullName.isEmpty || reasonLeave.isEmpty || startDateLeave.isEmpty ||
            endDateLeave.isEmpty || email.isEmpty || contactNumber.isEmpty) {
          // Show a Snackbar with a red background if any field is empty
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No empty fields allowed in the leave form'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final formData = {
          'Full Name': fullName,
          'Reason for Leave': reasonLeave,
          'Start Date': startDateLeave,
          'End Date': endDateLeave,
          'Email': email,
          'Contact Number': contactNumber,
          'isSeen': false,
        };

        await _submitForm(collectionName, formData, file);
      },
      child: _isLoading
          ? const CircularProgressIndicator()
          : const Text('Submit Leave Form'),
    );
  }
}