import 'package:flutter/material.dart';
import 'package:kbconnect/features/user_auth/presentation/pages/add_member.dart';
import 'package:kbconnect/features/user_auth/presentation/pages/edit_member.dart';
import 'package:kbconnect/features/user_auth/presentation/pages/login_pg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MembersPage extends StatefulWidget {
  @override
  _MembersPageState createState() => _MembersPageState();
}
class Member {
  final String id;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String emailAddress;
  final String profilePictureUrl;

  Member({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.emailAddress,
    required this.profilePictureUrl,
  });

  String get fullName => '$firstName $lastName';
}
class _MembersPageState extends State<MembersPage> {
  String query = '';
  String sortBy = 'firstName'; // Default sorting by first name
  List<Member> members = [];
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    _fetchMembersFromFirestore();
    _checkAdminStatus();
  }

  void _checkAdminStatus() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null && user.email == 'testuser@gmail.com') {
      setState(() {
        isAdmin = true;
      });
    }
  }
  Future<void> _fetchMembersFromFirestore() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('members').get();
      List<Member> fetchedMembers = snapshot.docs.map((doc) {
        var data = doc.data() as Map<String, dynamic>;

        // Debug prints to check if data is being fetched correctly
        print('Fetched member data: $data');

        return Member(
          id: doc.id,
          firstName: data['firstName'] ?? 'N/A',
          lastName: data['lastName'] ?? 'N/A',
          phoneNumber: data['phone'] ?? 'N/A',
          emailAddress: data['email'] ?? 'N/A',
          profilePictureUrl: data['imageUrl'] ?? '',
        );
      }).toList();

      setState(() {
        members = fetchedMembers;
      });
    } catch (e) {
      print("Error fetching members: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredMembers = members.where((member) {
      return member.fullName.toLowerCase().contains(query.toLowerCase());
    }).toList();

    filteredMembers.sort((a, b) {
      if (sortBy == 'firstName') {
        return a.firstName.compareTo(b.firstName);
      } else {
        return a.lastName.compareTo(b.lastName);
      }
    });
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search, color: Colors.brown), // Brown search icon
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(color: Colors.brown), // Brown border
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    onChanged: (text) {
                      setState(() {
                        query = text;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                PopupMenuButton<String>(
                  onSelected: (String value) {
                    setState(() {
                      sortBy = value;
                    });
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      const PopupMenuItem<String>(
                        value: 'firstName',
                        child: Text('Sort by First Name'),
                      ),
                      const PopupMenuItem<String>(
                        value: 'lastName',
                        child: Text('Sort by Last Name'),
                      ),
                    ];
                  },
                  icon: const Icon(Icons.sort, color: Colors.brown), // Brown sort icon
                ),
              ],
            ),
          ),
          Flexible(
            child: members.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: filteredMembers.length,
              itemBuilder: (context, index) {
                final member = filteredMembers[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.brown[50],
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: member.profilePictureUrl.isEmpty
                          ? CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: Text(
                          '${member.firstName[0].toUpperCase()}${member.lastName[0].toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20.0,
                          ),
                        ),
                      )
                          : CachedNetworkImage(
                        imageUrl: member.profilePictureUrl,
                        placeholder: (context, url) =>
                        const CircularProgressIndicator(),
                        errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                        imageBuilder: (context, imageProvider) =>
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: imageProvider,
                            ),
                      ),
                      title: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: member.firstName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.brown,
                                fontSize: 18.0,
                              ),
                            ),
                            TextSpan(
                              text: ' ${member.lastName}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.brown,
                                fontSize: 18.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.phone, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                member.phoneNumber,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          Wrap(
                            spacing: 4.0, // Space between items
                            runSpacing: 4.0, // Space between lines
                            children: [
                              const Icon(Icons.email, size: 16, color: Colors.grey),
                              Text(
                                member.emailAddress,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: isAdmin
                          ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.brown),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditMember(memberId: member.id),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final memberId =
                                  filteredMembers[index].id;

                              bool? confirmDelete = await showDialog<bool>(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text('Confirm Delete'),
                                    content: const Text(
                                        'Are you sure you want to delete this member?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  );
                                },
                              );

                              if (confirmDelete == true) {
                                try {
                                  await FirebaseFirestore.instance
                                      .collection('members')
                                      .doc(memberId)
                                      .delete();
                                  setState(() {
                                    // Remove the member from the list at the current index
                                    members.removeWhere((member) => member.id == memberId);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        backgroundColor: Colors.green,
                                        content: Text(
                                            'Member deleted successfully')),
                                  );
                                } catch (e) {
                                  print("Error deleting member: $e");
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Failed to delete member')),
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      )
                          : null,
                      onTap: () {},
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddMember()),
          );
        },
        label: const Text(''),
        icon: const Icon(Icons.add,color: Colors.brown,),
      )
          : const SizedBox.shrink(),
      backgroundColor: Colors.white24,
    );
  }
}

