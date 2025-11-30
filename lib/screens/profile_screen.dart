import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final user = FirebaseAuth.instance.currentUser;

  Stream<DocumentSnapshot> getUserInfo() {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F6FA),

      appBar: AppBar(
        title: Text("Profile"),
        backgroundColor: Color(0xFF0C2D83),
        centerTitle: true,
        elevation: 0,
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: getUserInfo(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // USER AVATAR
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Color(0xFF0C2D83),
                  child: Icon(Icons.person, size: 55, color: Colors.white),
                ),

                SizedBox(height: 20),

                // CARD: NAME
                _buildInfoCard(
                  icon: Icons.person,
                  label: "Name",
                  value: data["name"] ?? "No Name",
                ),

                SizedBox(height: 15),

                // CARD: EMAIL
                _buildInfoCard(
                  icon: Icons.email,
                  label: "Email",
                  value: user?.email ?? "No Email",
                ),

                SizedBox(height: 15),

                // CARD: PASSWORD
                _buildInfoCard(
                  icon: Icons.lock,
                  label: "Password",
                  value: "••••••••••",
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 10),
            child: Icon(icon, color: Color(0xFF0C2D83), size: 30),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
