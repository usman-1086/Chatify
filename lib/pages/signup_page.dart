import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../components/my_textfield.dart';
import '../utils/utils.dart';
import 'home_page.dart';
import 'login_page.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final nameController = TextEditingController();
  final _firestore = FirebaseFirestore.instance.collection('users');
  final _firebaseauth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    phoneNumberController.dispose();
    nameController.dispose();
    super.dispose();
  }

  Future<bool> _isUserUnique(String email, String name, String phoneNumber) async {
    final QuerySnapshot emailQuery = await _firestore.where('Email', isEqualTo: email).get();
    final QuerySnapshot nameQuery = await _firestore.where('Name', isEqualTo: name).get();
    final QuerySnapshot phoneQuery = await _firestore.where('Phone Number', isEqualTo: phoneNumber).get();

    if (emailQuery.docs.isNotEmpty || nameQuery.docs.isNotEmpty || phoneQuery.docs.isNotEmpty) {
      return false;
    }
    return true;
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await storageRef.putFile(image);
      return await storageRef.getDownloadURL();
    } catch (e) {
      Utils().toastMessage('Failed to upload image: $e');
      return null;
    }
  }

  Future<void> _signup() async {
    setState(() {
      _isLoading = true;
    });

    // Extract input values
    String email = emailController.text.toString();
    String password = passwordController.text.toString();
    String name = nameController.text.toString();
    String phoneNumber = phoneNumberController.text.toString();

    // Check for empty fields
    if (email.isEmpty || password.isEmpty || name.isEmpty || phoneNumber.isEmpty) {
      Utils().toastMessage('All fields are required');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Check for uniqueness
    bool isUnique = await _isUserUnique(email, name, phoneNumber);
    if (!isUnique) {
      Utils().toastMessage('Email, Name, or Phone Number already taken');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      await _firebaseauth.createUserWithEmailAndPassword(email: email, password: password);
      // Upload image if selected
      String? imageUrl;
      if (_image != null) {
        imageUrl = await _uploadImage(_image!);
      }

      String id = DateTime.now().millisecondsSinceEpoch.toString();
      await _firestore.doc(id).set({
        'id': id,
        'Email': email,
        'Phone Number': phoneNumber,
        'Name': name,
        'imageUrl': imageUrl,
      });

      Utils().toastMessage('Account created successfully');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } catch (error) {
      Utils().toastMessage('Failed to signup: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('Signup'),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: height * 0.05),
              GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _image != null ? FileImage(_image!) : null,
                  child: _image == null
                      ? Icon(Icons.add_a_photo, size: 50, color: Colors.grey)
                      : null,
                ),
              ),
              SizedBox(height: height * 0.03),
              MyTextfield(
                controller: nameController,
                hintText: 'Enter your name',
                obscureText: false,
              ),
              SizedBox(height: height * 0.03),
              MyTextfield(
                controller: emailController,
                hintText: 'Enter your email',
                obscureText: false,
              ),
              SizedBox(height: height * 0.03),
              MyTextfield(
                controller: passwordController,
                hintText: 'Enter your password',
                obscureText: true,
              ),
              SizedBox(height: height * 0.03),
              MyTextfield(
                controller: phoneNumberController,
                hintText: 'Enter your phone number',
                obscureText: false,
              ),
              SizedBox(height: height * 0.05),
              GestureDetector(
                onTap: _isLoading ? null : _signup,
                child: Container(
                  height: height * 0.06,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _isLoading
                        ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                        : Text(
                      'Signup',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: height * 0.03),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account?",
                    style: TextStyle(fontSize: 16),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => LoginPage()),
                      );
                    },
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: height * 0.05),
            ],
          ),
        ),
      ),
    );
  }
}
