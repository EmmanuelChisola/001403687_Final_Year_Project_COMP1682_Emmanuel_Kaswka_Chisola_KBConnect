import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnnouncementDetailsPage extends StatefulWidget {
  @override
  _AnnouncementDetailsPageState createState() => _AnnouncementDetailsPageState();
}

class _AnnouncementDetailsPageState extends State<AnnouncementDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  // Function to show the dialog for adding or editing announcements
  void _showAnnouncementDialog({Map<String, dynamic>? announcement, bool isEdit = false, String? announcementId}) {
    if (isEdit && announcement != null) {
      _titleController.text = announcement['title'] ?? '';
      _detailsController.text = announcement['details'] ?? '';
    } else {
      _titleController.clear();
      _detailsController.clear();
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Announcement' : 'Add Announcement'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Announcement Title'),
                ),
                TextField(
                  controller: _detailsController,
                  decoration: InputDecoration(labelText: 'Announcement Details'),
                  maxLines: null, // Allow multi-line input
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final String title = _titleController.text.trim();
                final String details = _detailsController.text.trim();

                if (title.isEmpty || details.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.red,
                      content: Text('Please fill out both fields.'),
                    ),
                  );
                  return;
                }

                // Add or update the announcement data
                if (isEdit && announcementId != null) {
                  await _updateAnnouncementInDatabase(
                    announcementId,  // Pass the announcementId for update
                    title,
                    details,
                  );
                } else {
                  await _addAnnouncementToDatabase(title, details);
                }
                Navigator.pop(context);
              },
              child: Text(isEdit ? 'Save Changes' : 'Add Announcement'),
            ),
          ],
        );
      },
    );
  }

  // Function to add a new announcement to Firestore
  Future<void> _addAnnouncementToDatabase(String title, String details) async {
    try {
      await _firestore.collection('announcements').add({
        'title': title,
        'details': details,
        'created_at': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.green,
            content: Text('Announcement added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to add announcement.')),
      );
    }
  }

  // Function to update an existing announcement in Firestore
  Future<void> _updateAnnouncementInDatabase(String announcementId, String title, String details) async {
    try {
      await _firestore.collection('announcements').doc(announcementId).update({
        'title': title,
        'details': details,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.green,
            content: Text('Announcement updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to update announcement.')),
      );
    }
  }

  // Function to delete an announcement from Firestore
  Future<void> _deleteAnnouncement(String announcementId) async {
    try {
      await _firestore.collection('announcements').doc(announcementId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.green,
            content: Text('Announcement deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to delete announcement.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Announcement Details'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('announcements')
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No announcements available.'));
          }
          var announcements = snapshot.data!.docs;
          return ListView.builder(
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              var announcement = announcements[index].data() as Map<String, dynamic>; // Convert the data to a map
              String announcementId = announcements[index].id; // Get the document ID

              return Card(
                margin: EdgeInsets.all(10),
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExpansionTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Ensures spacing between the title and the icons
                          children: [
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Title: ', // This part is not bold
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.blue[900],
                                        fontWeight: FontWeight.bold, // Accent color for title
                                      ),
                                    ),
                                    TextSpan(
                                      text: '${announcement['title'] ?? 'No title'}', // This part is not bold
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.black, // Default color for the title
                                      ),
                                    ),
                                  ],
                                ),
                                overflow: TextOverflow.ellipsis, // Handle overflow with ellipsis if necessary
                                softWrap: true, // Allow the text to wrap to the next line
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteAnnouncement(announcementId),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showAnnouncementDialog(
                                    announcement: announcement,
                                    isEdit: true,
                                    announcementId: announcementId,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            child: Text(
                              'Details: ${announcement['details'] ?? 'No details available'}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[800],
                                fontStyle: FontStyle.italic, // Make the text a bit softer
                                height: 1.5, // Add some line height to make the text more readable
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAnnouncementDialog(isEdit: false),
        child: Icon(Icons.add),
      ),
    );
  }
}
