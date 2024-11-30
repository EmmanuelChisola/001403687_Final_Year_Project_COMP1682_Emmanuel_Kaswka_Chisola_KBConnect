import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:just_audio/just_audio.dart';
import 'package:kbconnect/features/user_auth/presentation/pages/announcement_details.dart';
import 'package:kbconnect/features/user_auth/presentation/pages/calendar.dart';
import 'package:kbconnect/features/user_auth/presentation/pages/edit_profile.dart';
import 'package:kbconnect/features/user_auth/presentation/pages/form_submissions.dart';
import 'package:kbconnect/features/user_auth/presentation/pages/login_pg.dart';
import 'package:kbconnect/features/user_auth/presentation/pages/members.dart';
import 'package:kbconnect/features/user_auth/presentation/pages/ministry_screen.dart';
import 'package:kbconnect/features/user_auth/presentation/pages/sermon_details.dart';
import 'package:kbconnect/forms.dart';
import 'package:url_launcher/url_launcher.dart';

class Announcements {
  final String id;
  final String title;
  final String details;

  Announcements({
    required this.id,
    required this.title,
    required this.details,
  });
}

class ChurchHomePage extends StatefulWidget {
  ChurchHomePage({super.key});

  @override
  _ChurchHomePageState createState() => _ChurchHomePageState();
}

class _ChurchHomePageState extends State<ChurchHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedIndex = 0;
  int unseenFormsCount = 0;

  List<Map<String, String>> sermonLinks = [];
  List<Announcements> announcements = [];
  ThemeMode _themeMode = ThemeMode.system;
  bool isMember = false;
  bool isAdmin = false;
  bool isLoading = true;
  final AudioPlayer _audioPlayer = AudioPlayer();

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
  void _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email == 'testuser@gmail.com') {
      setState(() {
        isAdmin = true;
      });
    }
  }

  _fetchUnseenFormsCount() async {
    try {

      List<String> collections = [
        'marriageFormSubmissions',
        'baptismFormSubmission',
        'membershipFormSubmissions',
        'leaveFormSubmissions',
      ];

      int totalUnseenForms = 0;

      for (String collection in collections) {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection(collection)
            .where('isSeen', isEqualTo: false)
            .get();

        totalUnseenForms += querySnapshot.size; // Add the count of unseen forms
      }
      // Update the state with the total count
      setState(() {
        unseenFormsCount = totalUnseenForms;
      });
    } catch (error) {
      print("Error fetching unseen forms: $error");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchAnnouncementsFromFirestore();
    _checkAdminStatus();
    _fetchUnseenFormsCount();
    checkIfUserIsMember().then((isMemberStatus) {
      setState(() {
        isMember = isMemberStatus;
      });
    });
  }

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    String email = user?.email ?? 'User';
    String firstLetter = email.isNotEmpty ? email[0].toUpperCase() : 'U';
    String? photoURL = user?.photoURL;

    return MaterialApp(
        themeMode: _themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: Scaffold(
          key: _scaffoldKey,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('KBConnect'),
            backgroundColor: Colors.blueGrey[500],
            centerTitle: true,
            actions: [
              GestureDetector(
                onTap: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: CircleAvatar(
                    backgroundImage:
                        photoURL != null ? NetworkImage(photoURL) : null,
                    backgroundColor: Colors.brown[100],
                    child: photoURL == null
                        ? Text(
                            firstLetter,
                            style: const TextStyle(
                                fontSize: 20.0, color: Colors.brown),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
          drawer: _buildDrawer(context, user, email, firstLetter, photoURL),
          body: _buildPageContent(_selectedIndex),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: Colors.brown[600],
            type: BottomNavigationBarType.fixed,
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            items: <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              //if(isAdmin)
              BottomNavigationBarItem(
                icon: Icon(Icons.event),
                label: 'Calendar',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.dynamic_form_sharp),
                label: 'Forms',
              ),
              if (isMember || isAdmin)
                BottomNavigationBarItem(
                  icon: Icon(Icons.import_contacts_rounded),
                  label: 'Members',
                ),
            ],
            selectedItemColor: Colors.blueGrey[200],
          ),
        ));
  }

  Drawer _buildDrawer(BuildContext context, User? user, String email,
      String firstLetter, String? photoURL) {
    return Drawer(
      backgroundColor: Colors.blueGrey[200],
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(email),
            accountEmail: Text(email),
            currentAccountPicture: CircleAvatar(
              backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
              backgroundColor: Colors.white,
              child: photoURL == null
                  ? Text(
                      firstLetter,
                      style:
                          const TextStyle(fontSize: 40.0, color: Colors.blue),
                    )
                  : null,
            ),
            decoration: const BoxDecoration(
              color: Colors.brown,
            ),
            otherAccountsPictures: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProfilePage(user: user),
                    ),
                  );
                },
                child: const Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 35,
                ),
              ),
            ],
          ),
          Center(
            child: const Text(
              'Navigation menu bar',
              style: TextStyle(fontSize: 17.0, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: Icon(_themeMode == ThemeMode.light
                ? Icons.dark_mode
                : Icons.light_mode),
            title: const Text('Theme Mode'),
            onTap: () {
              _toggleTheme();
            },
          ),

          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14.0, // Reduced font size for the entire text
                    color: Colors.black, // Default color for the text
                  ),
                  children: [
                    const TextSpan(text: "Form Submissions ("),
                    TextSpan(
                      text: "$unseenFormsCount",
                      style: TextStyle(
                        color: Colors.brown, // Brown color for the count
                        fontWeight: FontWeight.bold, // Optional: Make it bold for emphasis
                      ),
                    ),
                    const TextSpan(text: ")"),
                  ],
                ),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FormSubmissions(),
                  ),
                );
              },
            ),

          if(!isAdmin)
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('Notifications'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPg()),
                (route) => false,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.green,
                  content: const Text("Account logged out successfully"),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent(int index) {
    switch (index) {
      case 0:
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildWelcomeSection(),
              _buildAnnouncementsSection(),
              _buildUpcomingEventsSection(),
              _buildMinistriesSection(),
              _buildSermonSection(),
              _buildContactUsSection(),
            ],
          ),
        );
      case 1:
        return const Center(
          child: Calendar(),
        );
      case 2:
        return const Center(
          child: FormsPage(),
        );
      case 3:
        return Center(child: MembersPage());
      default:
        return Container();
    }
  }

  Widget _buildWelcomeSection() {
    return Container(
      color: Colors.brown,
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'Welcome to Kabwata Baptist\'s App!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10.0),
          Text(
            'Join us for worship every Sunday at 10:00 AM.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.0,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchAnnouncementsFromFirestore() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('announcements').get();
      List<Announcements> fetchedAnnouncements = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;

        return Announcements(
          id: doc.id,
          title: data['title'] ?? 'N/A',
          details: data['details'] ?? 'N/A',
        );
      }).toList();

      setState(() {
        announcements = fetchedAnnouncements;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error fetching announcement: $e"),
        ),
      );
    }
  }

  void _editAnnouncementDialog(String id, String currentTitle, String currentDetails) {
    String title = currentTitle;
    String details = currentDetails;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Announcement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                onChanged: (value) {
                  title = value;
                },
                decoration: const InputDecoration(
                  hintText: 'Title',
                ),
                controller: TextEditingController(text: title),
              ),
              TextField(
                onChanged: (value) {
                  details = value;
                },
                decoration: const InputDecoration(
                  hintText: 'Details',
                ),
                controller: TextEditingController(text: details),
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Update'),
              onPressed: () {
                if (title.isNotEmpty && details.isNotEmpty) {
                  _updateAnnouncement(id, title, details);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all fields.'),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateAnnouncement(String id, String title, String details) async {
    try {
      await FirebaseFirestore.instance.collection('announcements').doc(id).update({
        'title': title,
        'details': details,
      });
      _fetchAnnouncementsFromFirestore();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating announcement: $e"),
        ),
      );
    }
  }

  Future<void> _deleteAnnouncement(String id) async {
    try {
      await FirebaseFirestore.instance.collection('announcements').doc(id).delete();
      _fetchAnnouncementsFromFirestore();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error deleting announcement: $e"),
        ),
      );
    }
  }

  Widget _buildAnnouncementsSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Announcements',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isAdmin)
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AnnouncementDetailsPage()),
                    );
                  },
                  child: const Icon(Icons.add_outlined),
                ),
            ],
          ),
          const SizedBox(height: 10.0),

          announcements.isEmpty
              ? const Center(child: Text('No announcements added',style: TextStyle(color: Colors.grey,
              fontWeight: FontWeight.bold,  fontSize: 16.0),))
              : Column(
            children: announcements
                .map((announcement) => _buildAnnouncementsCard(
              announcement.title,
              announcement.details,
              announcement.id,
            ))
                .toList(),
          ),
        ],
      ),
    );
  }


  Widget _buildAnnouncementsCard(String title, String announcement, String id) {
    return Card(
      color: Color(0xFFEFEBE9),
      child: ExpansionTile(
        iconColor: Colors.blueGrey,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text('Title: $title')),
            if (isAdmin) // Check if the current user is the admin
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      _editAnnouncementDialog(id, title, announcement);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _deleteAnnouncement(id);
                    },
                  ),
                ],
              ),
          ],
        ),
         // Shows only the first sentence
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Details: $announcement ', // Full announcement
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventsSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Events',
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10.0),
          FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('events')
                .where('date', isGreaterThanOrEqualTo: DateTime.now())
                .orderBy('date')
                .limit(5)
                .get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Text("Error loading events");
              } else if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    "No scheduled events.",
                    style:
                        TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold,color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                );
              } else {
                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    DateTime eventDate = (data['date'] as Timestamp).toDate();
                    String title = data['title'];

                    return _buildEventCard(
                      title,
                      "${eventDate.toLocal().toString().split(' ')[0]}", // Format as YYYY-MM-DD
                    );
                  }).toList(),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(String title, String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: ListTile(
          leading: const Icon(
            Icons.event,
            color: Colors.blueAccent,
            size: 30.0,
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            "Date: $date",
            style: const TextStyle(
              fontSize: 14.0,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

// Fetch ministries from Firestore
  Future<List<String>> _fetchMinistries() async {
    try {
      // Reference to the Firestore collection
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('ministries')
          .limit(3) // Fetch only the first 3 documents
          .get();

      // Extract the ministry names
      List<String> ministries = [];
      for (var doc in querySnapshot.docs) {
        ministries.add(doc['name']);  // Assuming 'name' is the field for ministry name
      }

      return ministries;
    } catch (e) {
      print("Error fetching ministries: $e");
      return [];  // Return an empty list if there's an error
    }
  }

  Widget _buildMinistriesSection() {
    return Container(
      color: Colors.brown,
      padding: const EdgeInsets.all(20.0),
      child: FutureBuilder<List<String>>(
        future: _fetchMinistries(), // Fetch ministries when this widget is built
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error fetching ministries'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No ministries currently'));
          }

          // Extract the ministry names
          List<String> ministries = snapshot.data!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ministries',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // Navigate to the all ministries page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MinistriesPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'View Ministries',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 18.0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10.0),
              // Create a card for each ministry
              ...ministries.map((ministryName) => _buildMinistryCard(ministryName, Icons.group)).toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMinistryCard(String title, IconData icon) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
      ),
    );
  }

  bool _isPlaying = false;

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
      print('Error pausing audio: $e');
    }
  }

  // Function to toggle play/pause
  void _togglePlayPause(String filePath) {
    if (_isPlaying) {
      _pauseAudio();
    } else {
      _playAudio(filePath);
    }
  }

  Widget _buildSermonSection() {
    final User? user = FirebaseAuth.instance.currentUser;

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Past Sermons',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isAdmin) // Check if the current user is admin
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SermonDetailsPage()),
                    );
                  },
                  child: const Icon(Icons.add_outlined),
                ),
            ],
          ),
          const SizedBox(height: 20),
          StreamBuilder(
            stream: FirebaseFirestore.instance.collection('sermons').snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Text(
                  'No sermons available',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                );
              }

              final sermons = snapshot.data!.docs;

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sermons.length,
                itemBuilder: (context, index) {
                  final sermon = sermons[index];

                  return Card(
                    margin: const EdgeInsets.all(10),
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
                                'Title: ${sermon['title'] ?? 'No title'}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Preacher: ${sermon['preacher'] ?? 'Unknown'}',
                            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 10),
                          sermon['file'] != null && sermon['file'] != ''
                              ? GestureDetector(
                            onTap: () => _togglePlayPause(sermon['file']),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.blueGrey[200],
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 15),
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
                                  const SizedBox(width: 10),
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
                              : const SizedBox(),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }


  Widget _buildContactUsSection() {
    return Container(
      color: Colors.blueGrey[400],
      padding: const EdgeInsets.all(20.0),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Us',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10.0),
          Text(
            'Email: pastoroffice@kabwatabaptistchurch.com',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          Text(
            'Phone: +260 123 456 789',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
