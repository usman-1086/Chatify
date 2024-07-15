import 'package:Chatify/pages/login_page.dart';
import 'package:Chatify/pages/user_page.dart';
import 'package:Chatify/utils/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _firestore = FirebaseFirestore.instance.collection('users');
  final _currentUserEmail = FirebaseAuth.instance.currentUser!.email!;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chatify', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout_sharp, color: Colors.black),
            onPressed: () {

              FirebaseAuth.instance.signOut().then((value){
                Utils().toastMessage('Signed out');
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage(),));
              }).catchError((error){
                Utils().toastMessage(error.toString());
              });

              },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.03),
            Center(
              child: Text(
                'Chat with users',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.blueAccent,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  suffixIcon: Icon(Icons.search),
                ),
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query.toLowerCase();
                  });
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildShimmerListView();
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No users present'));
                  }
                  var users = snapshot.data!.docs.where((user) {
                    var name = user['Name'].toString().toLowerCase();
                    return name.startsWith(_searchQuery);
                  }).toList();
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      var user = users[index];
                      if (user['Email'] != _currentUserEmail) {
                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UsersPage(
                                  userEmail: user['Email'],
                                  userName: user['Name'],
                                  userImage: user['imageUrl'],
                                ),
                              ),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundImage: user['imageUrl'] != null
                                ? NetworkImage(user['imageUrl'])
                                : AssetImage('assets/default_avatar.jpg')
                            as ImageProvider,
                            radius: 30,
                          ),
                          title: Text(
                            user['Name'],
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          trailing: Icon(Icons.message, color: Colors.blue),
                        );
                      } else {
                        return Container(); // Don't show current user in the list
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerListView() {
    return ListView.builder(
      itemCount: 5, // Placeholder for shimmer effect
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            leading: CircleAvatar(
              backgroundColor: Colors.white,
              radius: 30,
            ),
            title: Container(
              height: 20,
              color: Colors.white,
            ),
            trailing: Icon(Icons.message, color: Colors.blue),
          ),
        );
      },
    );
  }
}