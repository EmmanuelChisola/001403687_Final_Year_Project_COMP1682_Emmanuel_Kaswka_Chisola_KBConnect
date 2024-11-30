import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:just_audio/just_audio.dart';

class SermonDetailsPage extends StatefulWidget {
  @override
  _SermonDetailsPageState createState() => _SermonDetailsPageState();
}

class _SermonDetailsPageState extends State<SermonDetailsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AudioPlayer _audioPlayer = AudioPlayer(); // Audio player instance
  String _sermonFilePath = "";
  bool _isPlaying = false;
  bool _isUploading = false; // Uploading state

  // Function to play the audio
  Future<void> _playAudio(String filePath) async {
    try {
      await _audioPlayer.setUrl(filePath); // Set the audio file URL
      await _audioPlayer.play(); // Play the audio
      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      print('Error playing audio: $e');
    }
  }
  // Function to pause the audio
  Future<void> _pauseAudio() async {
    try {
      await _audioPlayer.pause();
      setState(() {
        _isPlaying = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error pausing audio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _togglePlayPause(String filePath) {
    if (_isPlaying) {
      _pauseAudio();
    } else {
      _playAudio(filePath);
    }
  }

  final TextEditingController _preacherController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  void _showSermonDialog({Map<String, dynamic>? sermon, bool isEdit = false}) {
    if (isEdit) {
      _preacherController.text = sermon?['preacher'] ?? '';
      _titleController.text = sermon?['title'] ?? '';
      _sermonFilePath = sermon?['file'] ?? '';
    } else {
      _preacherController.clear();
      _titleController.clear();
      _sermonFilePath = '';
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Edit Sermon' : 'Add Sermon'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: _preacherController,
                  decoration: InputDecoration(labelText: 'Preacher'),
                ),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: 'Sermon Title'),
                ),
                SizedBox(height: 10),
                GestureDetector(
                  onTap: _pickSermonFile,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    color: Colors.grey[200],
                    child: Row(
                      children: [
                        Icon(Icons.attach_file),
                        SizedBox(width: 10),
                        Text(_sermonFilePath.isEmpty
                            ? 'Upload sermon audio'
                            : _sermonFilePath.split('/').last),
                      ],
                    ),
                  ),
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
                final String preacher = _preacherController.text.trim();
                final String title = _titleController.text.trim();

                if (preacher.isEmpty || title.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.red,
                      content: Text('Please fill out both fields and upload a sermon file.'),
                    ),
                  );
                  return;
                }

                if (_sermonFilePath.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        backgroundColor: Colors.red,
                        content: Text('Please upload a sermon file.')),
                  );
                  return;
                }
                // Add or update the sermon data
                if (isEdit) {
                  await _updateSermonInDatabase(
                    sermon?['id'],
                    preacher,
                    title,
                    _sermonFilePath,
                  );
                } else {
                  await _addSermonToDatabase(
                    preacher,
                    title,
                    _sermonFilePath,
                  );
                }
                Navigator.pop(context);
              },
              child: Text(isEdit ? 'Save Changes' : 'Add Sermon'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickSermonFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null) {
      setState(() {
        _sermonFilePath = result.files.single.path ?? '';
      });
    }
  }

  // Function to add a new sermon to Firestore
  Future<void> _addSermonToDatabase(String preacher, String title, String sermonFile) async {
    try {
      await _firestore.collection('sermons').add({
        'preacher': preacher,
        'title': title,
        'file': sermonFile,
        'created_at': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.green,
            content: Text('Sermon added successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: Colors.red,
            content: Text('Failed to add sermon.')),
      );
    }
  }
  // Function to update an existing sermon in Firestore
  Future<void> _updateSermonInDatabase(String sermonId, String preacher,
      String title, String sermonFile) async {
    try {
      await _firestore.collection('sermons').doc(sermonId).update({
        'preacher': preacher,
        'title': title,
        'file': sermonFile,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sermon updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update sermon.')),
      );
    }
  }
  // Function to delete a sermon from Firestore
  Future<void> _deleteSermon(String sermonId) async {
    try {
      await _firestore.collection('sermons').doc(sermonId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sermon deleted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete sermon.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sermon Details'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF8B4513), Color(0xFFD2B48C)], // Gradient from saddle brown to tan
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('sermons')
              .orderBy('created_at', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No sermons available.'));
            }
            var sermons = snapshot.data!.docs;
            return ListView.builder(
              itemCount: sermons.length,
              itemBuilder: (context, index) {
                var sermon = sermons[index];
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Title: ${sermon['title'] ?? 'No title'}', // Adding "Title:" before the title
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteSermon(sermon.id),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Preacher: ${sermon['preacher'] ?? 'Unknown'}',
                          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                        SizedBox(height: 10),
                        sermon['file'] != null && sermon['file'] != ''
                            ? GestureDetector(
                          onTap: () => _togglePlayPause(sermon['file']),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.blue[100],
                            ),
                            padding: EdgeInsets.symmetric(vertical: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _isPlaying
                                      ? Icons.pause_circle_filled
                                      : Icons.play_circle_filled,
                                  size: 40,
                                  color: Colors.blue,
                                ),
                                SizedBox(width: 10),
                                // Display sermon title and preacher's name
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Title: ${sermon['title'] ?? 'No title'}', // Sermon title
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Preacher: ${sermon['preacher'] ?? 'Unknown'}', // Preacher's name
                                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                            : Container(),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSermonDialog(isEdit: false),
        child: Icon(Icons.add),
        backgroundColor: Colors.white,
      ),
    );
  }
}
