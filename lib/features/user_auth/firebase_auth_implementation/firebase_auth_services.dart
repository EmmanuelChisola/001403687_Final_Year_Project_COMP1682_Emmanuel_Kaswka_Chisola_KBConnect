import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';


class FirebaseAuthServices{
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> createUserWithEmailAndPassword(
      String email, String password) async{
    try{
      final credential= await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return credential.user;
    } catch (e){
      log("Something went wrong creating the user");
    }
    return null;
  }
  Future<User?> loginUserWithEmailAndPassword(
      String email, String password) async{
    try{
      final credential= await _auth.signInWithEmailAndPassword(email: email, password: password);
      return credential.user;
    } catch (e){
      log("Login error occured");
    }
    return null;
  }
  Future<User?> signUpWithEmailAndPassword(
      String email, String password) async{

    try{
      UserCredential credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return credential.user;

    }catch (e){
      log("Sign up error occured");
    }
    return null;
  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async{

    try{
      UserCredential credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return credential.user;

    }catch (e){
      log("Some error occured");
    }

    return null;
  }

  Future<void> signout() async{
    try{
      await _auth.signOut();

    }catch(e){
      log("User has logged out");

    }
  }

}