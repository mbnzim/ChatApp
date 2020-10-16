import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

final _firestore = FirebaseFirestore.instance;
auth.User loggedInUser;

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageTextController = TextEditingController();
  final _auth = auth.FirebaseAuth.instance;
  bool buttonActive = false;

  String messageText;
  void getCurrentUser() async {
    final user = _auth.currentUser;
    try {
      if (user != null) {
        loggedInUser = user;
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    getCurrentUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD2D3C9),
      appBar: AppBar(
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessagesStream(),
            Container(
              height: 50.0,
              margin: EdgeInsets.all(15.0),
              decoration: kRoudedTextField,
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 3.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                        textInputAction: TextInputAction.newline,
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        expands: true,
                        style: TextStyle(
                          fontSize: 20.0,
                        ),
                        controller: messageTextController,
                        onChanged: (value) {
                          messageText = value;
                          setState(() {
                            messageText == ""
                                ? buttonActive = false
                                : buttonActive = true;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Type message...',
                          border: InputBorder.none,
                        )),
                  ),
                  buttonActive == true
                      ? FlatButton(
                          onPressed: () {
                            messageTextController.clear();
                            _firestore.collection('messages').add({
                              'text': messageText,
                              'sender': loggedInUser.email,
                              'messageTime': DateTime.now()
                            });
                            setState(() {
                              buttonActive = false;
                            });
                            // print(DateTime.now().hour.toString() +':'+DateTime.now().minute.toString() );
                          },
                          child: Text(
                            'Send',
                            textAlign: TextAlign.end,
                            style: kSendButtonTextStyle,
                          ),
                        )
                      : Container(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessagesStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection("messages")
          .orderBy('messageTime', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        }

        final messages = snapshot.data.docs.reversed;
        List<MessageBubble> messageBubbles = [];
        for (var message in messages) {
          final messageText = message.data()['text'];
          final messageSender = message.data()['sender'];
          final time = message.data()['messageTime'].toDate();

          //  String timem = DateFormat.jm(time).toString();

          final currentUser = loggedInUser.email;

          final messageBubble = MessageBubble(
            //sender: messageSender,
            sender: '',
            text: messageText,
            time: time,
            isMe: currentUser == messageSender,
          );

          messageBubbles.add(messageBubble);
        }
        return Expanded(
          child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
            children: messageBubbles,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String sender;
  final String text;
  final bool isMe;
  final time;

  MessageBubble({this.sender, this.text, this.isMe, this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Text(
          //   sender,
          //   style: TextStyle(color: Colors.black54),
          // ),
          Material(
            borderRadius: isMe
                ? BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                  )
                : BorderRadius.only(
                    topRight: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                  ),
            elevation: 5.0,
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Column(
              children: [
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                  child: Text(
                    text,
                    style: TextStyle(
                        color: isMe ? Colors.white : Colors.black54,
                        fontSize: 20.0),
                  ),
                ),
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                  child: Text(
                    DateFormat.jm().format(time),
                    style: TextStyle(
                        color: isMe ? Colors.white : Colors.black54,
                        fontSize: 10.0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
