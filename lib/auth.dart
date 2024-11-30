import 'dart:developer';

import 'package:flutter/material.dart';

class Auth extends StatelessWidget {
  const Auth({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login & Signup Page',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final  _emailController = TextEditingController();
  final  _passwordController = TextEditingController();

  void _login() {
    String email = _emailController.text;
    String password = _passwordController.text;
    log('Logging in with email: $email, password: $password');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/LogoKBC.jpg'), // Provide your own background image
            fit: BoxFit.fill,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon:const  Icon(Icons.email),
                  border:const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon:const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.7),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _login,
                child: const Text('Login'),
              ),
              const SizedBox(height: 1.0),
              const Text('or', style: TextStyle(fontSize: 25.0)),
              const SizedBox(height: 8.0),
              Column(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignupPage()),
                      );
                    },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.brown, // Set your desired color here
              borderRadius: BorderRadius.circular(50.0), // Optional: add border radius for rounded corners
            ),
            padding:const EdgeInsets.all(8.0), // Optional: adjust padding as needed
            child: const Text(
              'Create an Account',
              style: TextStyle(
                color: Colors.black, // Set text color to contrast with the background color
                fontSize: 16.0,
              ),
            ),
          ),
        ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key});

  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _signup() {
    String email = _emailController.text;
    String password = _passwordController.text;
    log('Signing up with email: $email, password: $password');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signup'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/LogoKBC.jpg'),
            fit: BoxFit.fill,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16.0),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.7),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _signup,
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}