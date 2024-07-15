import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../utils/utils.dart';

class UsersPage extends StatefulWidget {
  final String userEmail;
  final String userName;
  final String? userImage; // Optional user image URL

  const UsersPage({Key? key, required this.userEmail, required this.userName, this.userImage}) : super(key: key);

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _currentUser = FirebaseAuth.instance.currentUser!.email!;
  final messageController = TextEditingController();
  late final fireStore = FirebaseFirestore.instance.collection('chats/${generateChatId(_currentUser, widget.userEmail)}/messages');
  late final fireStoreStream = fireStore.orderBy('timestamp').snapshots();

  String generateChatId(String user1, String user2) {
    return user1.hashCode <= user2.hashCode ? '$user1-$user2' : '$user2-$user1';
  }

  void _deleteMessage(String messageId) {
    fireStore.doc(messageId).delete().then((value) {
      Utils().toastMessage('Message deleted successfully');
    }).catchError((error) {
      Utils().toastMessage('Failed to delete message: $error');
    });
  }

  String _formatTime(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return '${dateTime.hour}:${dateTime.minute}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName),
        centerTitle: true,
        backgroundColor: Colors.blue, // Customize app bar color
        elevation: 0, // Remove elevation
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
              image:AssetImage('images/background.jpg'),
            fit: BoxFit.cover
          )
        ),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: fireStoreStream,
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  } else {
                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var message = snapshot.data!.docs[index];
                        String messageId = message.id;
                        bool isCurrentUser = message['sender'] == _currentUser;
                        Timestamp timestamp = message['timestamp'];

                        return GestureDetector(
                          onLongPress: () {
                            if (isCurrentUser) {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Delete Message'),
                                  content: Text('Are you sure you want to delete this message?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context); // Close the dialog
                                      },
                                      child: Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context); // Close the dialog
                                        _deleteMessage(messageId);
                                      },
                                      child: Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          child: Align(
                            alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
                              child: Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: isCurrentUser ? Colors.blue[200] : Colors.grey[200],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message['message'],
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      _formatTime(timestamp),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      style: TextStyle(color: Colors.white), // This will change the color of the input text
                      decoration: InputDecoration(
                        hintText: 'Enter your message',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)), // Optional: Adjust hint color
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white), // Optional: Adjust border color
                        ),
                      ),
                    )

                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      String message = messageController.text.trim();
                      if (message.isNotEmpty) {
                        String id = DateTime.now().millisecondsSinceEpoch.toString();
                        fireStore.doc(id).set({
                          'id': id,
                          'message': message,
                          'sender': _currentUser,
                          'receiver': widget.userEmail,
                          'timestamp': Timestamp.now(),
                        }).then((value) {
                          Utils().toastMessage('Message Sent Successfully');
                          messageController.clear();
                        }).catchError((error) {
                          Utils().toastMessage('Failed to send message: $error');
                        });
                      } else {
                        Utils().toastMessage('Message cannot be empty');
                      }
                    },
                    child: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
