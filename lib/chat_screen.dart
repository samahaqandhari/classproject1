import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatScreen extends StatefulWidget {
  final String senderName;
  final String receiverName;
  final String senderId;
  final String receiverId;

  const ChatScreen({
    Key? key,
    required this.senderName,
    required this.receiverName,
    required this.senderId,
    required this.receiverId,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> messages = [];  // Change type to dynamic

  // Reference to Firestore collection for chat messages
  late CollectionReference chatRoom;

  @override
  void initState() {
    super.initState();

    // Sort user IDs so that the smaller one comes first
    final sortedIds = [widget.senderId, widget.receiverId]..sort();
    final chatRoomId = sortedIds.join("_");

    chatRoom = FirebaseFirestore.instance.collection('chats').doc(chatRoomId).collection('messages');

    // Load existing messages from Firestore
    loadMessages();
  }

  Future<void> loadMessages() async {
    final snapshot = await chatRoom.orderBy('timestamp').get();
    setState(() {
      messages = snapshot.docs
          .map((doc) => {
        'senderId': doc['senderId'],
        'receiverId': doc['receiverId'],
        'message': doc['message'],
      })
          .toList();
    });
  }

  void sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      final timestamp = FieldValue.serverTimestamp();

      await chatRoom.add({
        'senderId': widget.senderId,
        'receiverId': widget.receiverId,
        'message': message,
        'timestamp': timestamp,
      });

      _messageController.clear();
      loadMessages();  // Reload messages after sending a new one
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.receiverName}'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final chat = messages[index];
                final isSender = chat['senderId'] == widget.senderId;
                return Align(
                  alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isSender ? Colors.lightBlueAccent.withOpacity(0.8) : Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      chat['message']!,
                      style: TextStyle(color: isSender ? Colors.white : Colors.black),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: sendMessage,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlueAccent),
                  child: const Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
