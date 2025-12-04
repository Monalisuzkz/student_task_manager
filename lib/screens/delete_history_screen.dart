import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class DeleteHistoryScreen extends StatelessWidget {
  DeleteHistoryScreen({super.key});

  final user = FirebaseAuth.instance.currentUser;

  Future<void> _clearAllHistory(BuildContext context) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            "Clear All Delete History",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          content: Text(
            "Are you sure you want to permanently delete ALL deleted tasks?",
            textAlign: TextAlign.center,
          ),

          actionsPadding: EdgeInsets.all(12),
          actions: [
            Row(
              children: [
                // CANCEL BUTTON
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text("Cancel", style: TextStyle(color: Colors.red)),
                  ),
                ),

                SizedBox(width: 10),

                // CLEAR ALL BUTTON
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text("Clear"),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    // DELETE / CLEAR ALL deleted_tasks
    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .collection("deleted_tasks")
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.white,
        content: Text(
          "All delete history cleared",
          style: TextStyle(color: Colors.black),
        ),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 20, left: 16, right: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F6FA),
      appBar: AppBar(
        title: Text("Delete History"),
        backgroundColor: Color(0xFF0C2D83),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep),
            tooltip: "Clear All",
            onPressed: () => _clearAllHistory(context),
          ),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(user!.uid)
            .collection("deleted_tasks")
            .orderBy("deletedAt", descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Text(
                "No deleted tasks",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView(
            children: docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final id = doc.id;

              return Container(
                margin: EdgeInsets.all(12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TASK NAME
                    Text(
                      data["task"] ?? "",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 5),
                    // DELETED DATE
                    Text(
                      "Deleted: ${DateFormat('MMM d, yyyy – h:mm a').format(data['deletedAt'].toDate())}",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),

                    SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // RESTORE BUTTON
                        TextButton.icon(
                          onPressed: () async {
                            final restoredData = Map<String, dynamic>.from(data)
                              ..remove("deletedAt");

                            // Restore to tasks
                            await FirebaseFirestore.instance
                                .collection("users")
                                .doc(user!.uid)
                                .collection("tasks")
                                .doc(id)
                                .set({
                                  ...restoredData,
                                  "timestamp": FieldValue.serverTimestamp(),
                                });

                            // Remove from deleted history
                            await FirebaseFirestore.instance
                                .collection("users")
                                .doc(user!.uid)
                                .collection("deleted_tasks")
                                .doc(id)
                                .delete();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.white,
                                content: Text(
                                  "Task Restored",
                                  style: TextStyle(color: Colors.black),
                                ),
                                behavior: SnackBarBehavior.floating,
                                margin: EdgeInsets.only(
                                  bottom: 20,
                                  left: 16,
                                  right: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                          icon: Icon(Icons.restore, color: Colors.blue),
                          label: Text("Restore"),
                        ),

                        // DELETE BUTTON
                        TextButton.icon(
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection("users")
                                .doc(user!.uid)
                                .collection("deleted_tasks")
                                .doc(id)
                                .delete();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.white,
                                content: Text(
                                  "Task permanently deleted",
                                  style: TextStyle(color: Colors.black),
                                ),
                                behavior: SnackBarBehavior.floating,
                                margin: EdgeInsets.only(
                                  bottom: 20,
                                  left: 16,
                                  right: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                          icon: Icon(Icons.delete_forever, color: Colors.red),
                          label: Text("Delete Forever"),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
