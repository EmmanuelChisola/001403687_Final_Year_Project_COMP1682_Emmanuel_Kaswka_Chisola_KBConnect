import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kbconnect/features/user_auth/presentation/pages/add_ministry.dart';

class Ministry {
  String id;
  String name;
  String description;

  Ministry({
    required this.id,
    required this.name,
    required this.description,
  });

  factory Ministry.fromMap(Map<String, dynamic> data, String id) {
    return Ministry(
      id: id,
      name: data['name'] as String,
      description: data['description'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
    };
  }
}

class MinistriesPage extends StatefulWidget {
  @override
  State<MinistriesPage> createState() => _MinistriesPageState();
}

class _MinistriesPageState extends State<MinistriesPage> {
  bool isAdmin = false;
  List<Ministry> ministries = [];

  void _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email == 'testuser@gmail.com') {
      setState(() {
        isAdmin = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchMinistriesFromDatabase();
    _checkAdminStatus();
  }

  void _editMinistry(BuildContext context, Ministry ministry) {
    final TextEditingController _nameController = TextEditingController(text: ministry.name);
    final TextEditingController _descriptionController = TextEditingController(text: ministry.description);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit ${ministry.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final updatedMinistry = Ministry(
                  id: ministry.id,
                  name: _nameController.text,
                  description: _descriptionController.text,
                );
                final firestore = FirebaseFirestore.instance;
                await firestore.collection('ministries').doc(updatedMinistry.id).update(updatedMinistry.toMap());
                _fetchMinistriesFromDatabase();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _deleteMinistry(BuildContext context, Ministry ministry) async {
    final confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Ministry'),
          content: Text('Are you sure you want to delete ${ministry.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancel delete
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirm delete
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );

    if (confirmDelete != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Deleting ministry..."),
              ],
            ),
          ),
        );
      },
    );

    try {
      final firestore = FirebaseFirestore.instance;
      await firestore.collection('ministries').doc(ministry.id).delete();

      // Fetch updated ministries
      await _fetchMinistriesFromDatabase();

      // Close the loading dialog
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green[600],
          content: Text('${ministry.name} deleted successfully!'),
        ),
      );

    } catch (e) {
      // Close the loading dialog
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Failed to delete ministry: $e'),
        ),
      );
    }
  }



  Future<void> _fetchMinistriesFromDatabase() async {
    final firestore = FirebaseFirestore.instance;
    final querySnapshot = await firestore.collection('ministries').get();
    setState(() {
      ministries = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Ministry.fromMap(data, doc.id);
      }).toList();
    });
  }

  Future<void> _addMinistryToDatabase(Ministry ministry) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('ministries').add(ministry.toMap());
  }

  void _addMinistry() {
    showDialog(
      context: context,
      builder: (context) => AddMinistryDialog(
        onMinistryAdded: (ministry) async {
          await _addMinistryToDatabase(ministry as Ministry);
          _fetchMinistriesFromDatabase();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Church Ministries'),
        backgroundColor: Colors.brown,
      ),
      body: ListView.builder(
        itemCount: ministries.length,
        itemBuilder: (context, index) {
          final ministry = ministries[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            elevation: 5.0, // Add shadow for depth
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // Rounded corners
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListTile(
                title: Text(
                  ministry.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                    color: Colors.brown[800],
                  ),
                ),
                subtitle: Text(
                  ministry.description,
                  style: TextStyle(
                    color: Colors.brown[600],
                  ),
                ),
                trailing: isAdmin
                    ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.brown),
                      onPressed: () => _editMinistry(context, ministry),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteMinistry(context, ministry),
                    ),
                  ],
                )
                    : null,
              ),
            ),
          );
        },
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
        onPressed: _addMinistry,
         child: const Icon(Icons.add),
        backgroundColor: Colors.brown,
        tooltip: 'Add Ministry',
      )
          : null,
    );
  }
}
