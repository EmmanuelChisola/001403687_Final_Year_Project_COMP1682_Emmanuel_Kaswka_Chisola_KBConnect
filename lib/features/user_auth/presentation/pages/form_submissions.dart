import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class FormSubmissions extends StatefulWidget {
  const FormSubmissions({super.key});

  @override
  State<FormSubmissions> createState() => _FormSubmissionsState();
}

class _FormSubmissionsState extends State<FormSubmissions> {
  final List<String> formNames = [
    'Membership Form Submission',
    'Leave Form Submission',
    'Baptism Form Submission',
    'Marriage Form Submission'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF6D4C41), // Brown color for the app bar
        title: const Text('Form Submissions'),
      ),
      body: ListView.builder(
        itemCount: formNames.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            elevation: 5, // Shadow for the card
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Rounded corners for the card
            ),
            color: Color(0xFFEFEBE9), // Light brown background color for the card
            child: ListTile(
              contentPadding: EdgeInsets.all(16),
              leading: const Icon(Icons.folder, color: Color(0xFF6D4C41)), // Brown color for the icon
              title: Text(
                formNames[index],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6D4C41), // Brown title text
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios, // Right arrow icon
                color: Color(0xFF6D4C41), // Brown color for the arrow
              ),
              onTap: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SubmissionsDetails(formName: formNames[index]),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class SubmissionsDetails extends StatelessWidget {
  final String formName;

  SubmissionsDetails({required this.formName});

  Future<List<Map<String, dynamic>>> fetchFormData(
      String collectionName) async {
    try {
      // Fetch data from the specified Firestore collection
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection(collectionName)
          .get();
      // Map the snapshot data to a List of Maps
      List<Map<String, dynamic>> data = snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();

      return data;
    } catch (e) {
      // Handle errors (e.g., no internet, permission issues, etc.)
      print("Error fetching data: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF6D4C41), // Brown color for the app bar
        title: Text('$formName'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchFormData(_getCollectionName(formName)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No submissions yet.'));
          }

          List<Map<String, dynamic>> submissions = snapshot.data!;

          return ListView.builder(
            itemCount: submissions.length,
            itemBuilder: (context, index) {
              if (formName == 'Leave Form Submission') {
                return _buildLeaveFormTile(submissions[index], context);
              } else if (formName == 'Membership Form Submission') {
                return _buildMembershipFormTile(submissions[index], context);
              } else if (formName == 'Baptism Form Submission') {
                return _buildBaptismFormTile(submissions[index], context);
              } else if (formName == 'Marriage Form Submission') {
                return _buildMarriageFormTile(submissions[index], context);
              } else {
                return const ListTile(title: Text('Unknown form type'));
              }
            },
          );
        },
      ),
    );
  }

  String _getCollectionName(String formName) {
    switch (formName) {
      case 'Membership Form Submission':
        return 'membershipFormSubmissions';
      case 'Leave Form Submission':
        return 'leaveFormSubmissions';
      case 'Baptism Form Submission':
        return 'baptismFormSubmission';
      case 'Marriage Form Submission':
        return 'marriageFormSubmissions';
      default:
        throw Exception('Unknown form type');
    }
  }

  Widget _buildLeaveFormTile(Map<String, dynamic> leaveFormSubmissions, BuildContext context) {
    return Card(
      elevation: 5,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Rounded corners for the card
      ),
      color: Color(0xFFEFEBE9), // Light brown background color for the card
      child: InkWell(
        onTap: () async {
          try {
            // Correct collection name: 'leaveFormSubmissions'
            var querySnapshot = await FirebaseFirestore.instance
                .collection('leaveFormSubmissions') // Corrected collection name
                .where('email', isEqualTo: leaveFormSubmissions['email']) // Query by email
                .get();

            if (querySnapshot.docs.isNotEmpty) {
              String docId = querySnapshot.docs.first.id; // Get the first matching document ID
              await FirebaseFirestore.instance
                  .collection('leaveFormSubmissions') // Ensure same collection for update
                  .doc(docId)
                  .update({'isSeen': true}); // Update isSeen field to true

              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Marked as Seen'),
              ));
            } else {
              print('No document found for email: ${leaveFormSubmissions['email']}');
            }
          } catch (e) {
            print('Error updating isSeen field: $e');
          }
        },
        child: ExpansionTile(
          leading: Icon(
            Icons.work, // Icon for leave
            color: Color(0xFF6D4C41), // Brown color for the icon
          ),
          title: Text(
            'Full Name: ${leaveFormSubmissions['Full Name'] ?? 'No Name'}',
            style: TextStyle(
              fontWeight: leaveFormSubmissions['isSeen'] == true
                  ? FontWeight.normal
                  : FontWeight.bold, // Highlight unseen entries
            ),
          ),
          subtitle: Text(
            'Reason for Leave: ${leaveFormSubmissions['Reason for Leave']?.split('.')[0] ?? 'No Reason'}',
            // Show only the first sentence
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '''
            Email: ${leaveFormSubmissions['Email'] ?? 'No Email'}
            Contact Number: ${leaveFormSubmissions['Contact Number'] ?? 'No Contact Number'}
            Reason for Leave: ${leaveFormSubmissions['Reason for Leave'] ?? 'No Reason'}
            Start Date: ${leaveFormSubmissions['Start Date'] ?? 'No Start Date'}
            End Date: ${leaveFormSubmissions['End Date'] ?? 'No End Date'}
            ''',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildMembershipFormTile(
      Map<String, dynamic> membershipFormSubmission, BuildContext context) {
    return Card(
      elevation: 5,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Rounded corners for the card
      ),
      color: Color(0xFFEFEBE9),
      // Light brown background color for the card
      child: InkWell(
        onTap: () async {
          try {
            var querySnapshot = await FirebaseFirestore.instance
                .collection('membershipFormSubmissions')
                .where('Email', isEqualTo: membershipFormSubmission['Email']) // Query by email
                .get();

            if (querySnapshot.docs.isNotEmpty) {
              String docId = querySnapshot.docs.first.id; // Get the first matching document ID
              await FirebaseFirestore.instance
                  .collection('membershipFormSubmissions')
                  .doc(docId)
                  .update({'isSeen': true});

              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Marked as Seen'),
              ));
            } else {

            }
          } catch (e) {
          }
        },
        child: ExpansionTile(
          leading: Icon(
            Icons.person,
            color: Color(0xFF6D4C41), // Brown color for the icon
          ),
          title: Text(
            'Full Name: ${membershipFormSubmission['Full Name'] ?? 'No Name'}',
            style: TextStyle(
              fontWeight: membershipFormSubmission['isSeen'] == true
                  ? FontWeight.normal
                  : FontWeight.bold,
            ),
          ),
          subtitle: Text(
            'Contact Number: ${membershipFormSubmission['Contact Number'] ?? 'No Contact'}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '''
            Full Name: ${membershipFormSubmission['Full Name'] ?? 'No Name'}
            Email: ${membershipFormSubmission['Email'] ?? 'No Email'}
            Contact Number: ${membershipFormSubmission['Contact Number'] ?? 'No Contact'}
            Home Address: ${membershipFormSubmission['Home Address'] ?? 'No Address'}
            Date of Application: ${membershipFormSubmission['Date of Application'] ?? 'No Date'}
            ''',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBaptismFormTile(Map<String, dynamic> baptismFormSubmission, BuildContext context) {
    return Card(
      elevation: 5,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Rounded corners for the card
      ),
      color: Color(0xFFEFEBE9), // Light brown background color for the card
      child: InkWell(
        onTap: () async {
          try {
            var querySnapshot = await FirebaseFirestore.instance
                .collection('baptismFormSubmissions')
                .where('Email', isEqualTo: baptismFormSubmission['Email']) // Query by email
                .get();

            if (querySnapshot.docs.isNotEmpty) {
              String docId = querySnapshot.docs.first.id; // Get the first matching document ID
              await FirebaseFirestore.instance
                  .collection('baptismFormSubmissions')
                  .doc(docId)
                  .update({'isSeen': true});

              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Marked as Seen'),
              ));
            } else {
              print('No document found for email: ${baptismFormSubmission['Email']}');
            }
          } catch (e) {
            print('Error updating isSeen field: $e');
          }
        },
        child: ExpansionTile(
          leading: Icon(
            Icons.church, // Icon to represent baptism
            color: Color(0xFF6D4C41), // Brown color for the icon
            size: 30,
          ),
          title: Text(
            'Full Name: ${baptismFormSubmission['Full Name'] ?? 'No Name'}',
            style: TextStyle(
              fontWeight: baptismFormSubmission['isSeen'] == true
                  ? FontWeight.normal
                  : FontWeight.bold,
            ),
          ),
          subtitle: Text(
            'Date of Birth: ${baptismFormSubmission['Date of Birth'] ?? 'No Date'}', // Display date of birth
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '''
              Full Name: ${baptismFormSubmission['Full Name'] ?? 'No Name'}
              Date of Birth: ${baptismFormSubmission['Date of Birth'] ?? 'No Date'}
              Email: ${baptismFormSubmission['Email'] ?? 'No Email'}
              Contact Number: ${baptismFormSubmission['Contact Number'] ?? 'No Contact'}
              ''',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildMarriageFormTile(Map<String, dynamic> marriageFormSubmissions,
      BuildContext context) {
    return Card(
      color: Color(0xFFEFEBE9),
      elevation: 5,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12), // Rounded corners for the card
      ),
      child: InkWell(
        onTap: () async {
          try {
            var querySnapshot = await FirebaseFirestore.instance
                .collection('marriageFormSubmissions')
                .where('email', isEqualTo: marriageFormSubmissions['email']) // Query by email
                .get();

            if (querySnapshot.docs.isNotEmpty) {
              String docId = querySnapshot.docs.first.id; // Get the first matching document ID
              await FirebaseFirestore.instance
                  .collection('marriageFormSubmissions')
                  .doc(docId)
                  .update({'isSeen': true});

              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Marked as Seen'),
              ));
            } else {
              print('No document found for email: ${marriageFormSubmissions['email']}');
            }
          } catch (e) {
            print('Error updating isSeen field: $e');
          }
        },
        child: ExpansionTile(
          leading: Icon(
            Icons.favorite, // Icon to represent marriage
            color: Color(0xFF6D4C41), // Brown color for the icon
            size: 30,
          ),
          title: Text(
            'Full Name: ${marriageFormSubmissions['Full Name'] ?? 'No Name'}',
            style: TextStyle(
              fontWeight: marriageFormSubmissions['isSeen'] == true
                  ? FontWeight.normal
                  : FontWeight.bold, // Adjust font weight based on isSeen
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          subtitle: Text(
            'Spouse\'s Name: ${marriageFormSubmissions['Spouse\'s Name'] ??
                'No Spouse'}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '''
            Full Name: ${marriageFormSubmissions['Full Name'] ?? 'No Name'}
            Spouse's Name: ${marriageFormSubmissions['Spouse\'s Name'] ??
                    'No Spouse'}
            Date of Marriage: ${marriageFormSubmissions['Wedding Date'] ??
                    'No Date'}
            Contact Number: ${marriageFormSubmissions['Contact Number'] ??
                    'No Contact'}
            Email: ${marriageFormSubmissions['Email'] ?? 'No Email address'}
            ''',
                textAlign: TextAlign.start,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
