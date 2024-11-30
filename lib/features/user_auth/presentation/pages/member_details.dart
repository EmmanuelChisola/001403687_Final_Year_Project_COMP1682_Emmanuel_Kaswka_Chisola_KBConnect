import 'package:flutter/material.dart';
import 'package:kbconnect/features/user_auth/presentation/pages/members.dart';


class MemberDetailPage extends StatelessWidget {
  final Member member;

  const MemberDetailPage({Key? key, required this.member}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(member.fullName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(member.profilePictureUrl),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Full Name: ${member.fullName}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              'Phone Number: ${member.phoneNumber}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              'Email Address: ${member.emailAddress}',
              style: const TextStyle(fontSize: 18),
            ),
            // Add more details if needed
          ],
        ),
      ),
    );
  }
}
