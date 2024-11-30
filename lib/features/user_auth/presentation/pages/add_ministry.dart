// ignore_for_file: unused_import

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Ministry {
  final String name;
  final String description;

  Ministry({required this.name, required this.description});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
    };
  }

  factory Ministry.fromMap(Map<String, dynamic> map) {
    return Ministry(
      name: map['name'],
      description: map['description'],
    );
  }
}

class AddMinistryDialog extends StatefulWidget {
  final void Function(Ministry) onMinistryAdded;

  AddMinistryDialog({required this.onMinistryAdded});

  @override
  _AddMinistryDialogState createState() => _AddMinistryDialogState();
}

class _AddMinistryDialogState extends State<AddMinistryDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  void _submit() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isNotEmpty && description.isNotEmpty) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissal by tapping outside
        builder: (BuildContext context) {
          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("Adding ministry..."),
                ],
              ),
            ),
          );
        },
      );

      try {
        // Add the new ministry to the Firestore 'ministries' collection
        await FirebaseFirestore.instance.collection('ministries').add({
          'name': name,
          'description': description,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Close the loading dialog
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green[600],
            content: Text('Ministry added successfully!'),
          ),
        );

        // Call the onMinistryAdded callback if it's necessary
        final newMinistry = Ministry(name: name, description: description);
        widget.onMinistryAdded(newMinistry);

        Navigator.of(context).pop();
      } catch (e) {
        // Close the loading dialog
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: Colors.red,
              content: Text('Failed to add ministry: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Please fill in all fields.'),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Ministry'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Ministry Name'),
          ),
          Container(
            height: 100.0,
            child: TextField(
              onChanged: (value) {
                _descriptionController.text = value;
              },
              decoration: const InputDecoration(
                hintText: 'Ministry Details',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
            ),
          ),

        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
