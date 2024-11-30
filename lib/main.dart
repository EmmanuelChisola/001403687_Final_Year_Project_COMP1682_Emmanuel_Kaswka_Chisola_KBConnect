import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:kbconnect/features/user_auth/presentation/pages/add_announcements.dart';
import 'package:kbconnect/features/user_auth/presentation/pages/login_pg.dart';
import 'package:kbconnect/features/user_auth/presentation/pages/members.dart';
import 'package:kbconnect/features/user_auth/presentation/pages/profile_page.dart';
import 'package:kbconnect/features/user_auth/presentation/pages/sign_up_page.dart';
import 'package:kbconnect/forms.dart';
import 'package:kbconnect/home.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: "AIzaSyDQT-SvcUhfBQGY2v79lfcAvcIVbJG3t1c",
            authDomain: "kbc-db-d926a.firebaseapp.com",
            projectId: "kbc-db-d926a",
            storageBucket: "kbc-db-d926a.appspot.com",
            messagingSenderId: "124791319956",
            appId: "1:124791319956:web:c29dab6c50c85757267381"));
  } else {
    await Firebase.initializeApp();
  }

  runApp(const KBCApp());
}

class KBCApp extends StatelessWidget {
  const KBCApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'KBConnect',
      initialRoute: '/',
      routes: {
        '/': (context) => const Splashscreen(),
        '/login': (context) => const LoginPg(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => ChurchHomePage(),
        '/members': (context) => MembersPage(),
        '/forms': (context) => const FormsPage(),
        '/profile': (context) => ProfileScreen(),
        '/announcements': (context) => AddAnnouncement(),
      },
    );
  }
}
class Splashscreen extends StatefulWidget {
  final Widget? child;

  const Splashscreen({super.key, this.child});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Animation controller for the splash screen animation
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Animation for fading in the logo
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    // Navigate to the next screen after the splash screen
    Future.delayed(const Duration(seconds: 4), () {
      final user = FirebaseAuth.instance.currentUser;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => user != null
              ? ChurchHomePage() // Navigate to home if logged in
              : widget.child ?? const LoginPg(), // Navigate to login otherwise
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFD2B48C),
              Color(0xFF8B4513),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _animation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'images/LogoKBC.jpg', // Replace with your image path
                      width: 200,
                      height: 200,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "KBConnect",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      "by: Emmanuel Chisola",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              RotationTransition(
                turns: _controller,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5.0),
                      child: Dot(
                        radius: 5.0,
                        color: Colors.white,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Dot extends StatelessWidget {
  final double radius;
  final Color color;

  const Dot({required this.radius, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
