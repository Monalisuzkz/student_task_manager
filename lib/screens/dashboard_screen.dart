import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:student_task_manager_project/screens/delete_history_screen.dart';
import 'package:table_calendar/table_calendar.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

bool showCalendar = true;

Map<DateTime, List<Map<String, dynamic>>> taskEvents = {};
final Map<String, Color> priorityColors = {
  "Low": Colors.blue,
  "Medium": Colors.orange,
  "High": Colors.red,
};

Widget _chip(String text, Color bg, Color color) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
    ),
  );
}

class _DashboardScreenState extends State<DashboardScreen> {
  final taskController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;

  String selectedCategory = "School";
  String selectedPriority = "Medium";
  DateTime? selectedDueDate;
  String searchQuery = "";
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final List<String> categories = ["School", "Personal", "Urgent"];
  final List<String> priorities = ["Low", "Medium", "High"];

  void _showAddTaskDialog() {
    final TextEditingController taskNameController = TextEditingController();
    String tempCategory = selectedCategory;
    String tempPriority = selectedPriority;
    DateTime? tempDueDate = selectedDueDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: Text(
                "Add New Task",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C2D83),
                ),
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // TASK NAME
                    TextField(
                      controller: taskNameController,
                      decoration: InputDecoration(
                        labelText: "Task Name",
                        border: OutlineInputBorder(),
                      ),
                    ),

                    SizedBox(height: 15),

                    // CATEGORY
                    DropdownButtonFormField<String>(
                      initialValue: tempCategory,
                      items: categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Category",
                      ),
                      onChanged: (value) {
                        setStateDialog(() => tempCategory = value!);
                      },
                    ),

                    SizedBox(height: 15),

                    // PRIORITY
                    DropdownButtonFormField<String>(
                      initialValue: tempPriority,
                      items: priorities
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          )
                          .toList(),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: "Priority",
                      ),
                      onChanged: (value) {
                        setStateDialog(() => tempPriority = value!);
                      },
                    ),

                    SizedBox(height: 15),

                    // DUE DATE PICKER
                    TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: tempDueDate == null
                            ? "Select Due Date"
                            : "Due: ${DateFormat('MMM d, yyyy').format(tempDueDate!)}",

                        // DYNAMIC COLOR (blue if not due, red if overdue)
                        labelStyle: TextStyle(
                          color: tempDueDate == null
                              ? Colors.grey
                              : (tempDueDate!.isBefore(DateTime.now())
                                    ? Colors.red
                                    : Colors.blue),
                        ),
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_month),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tempDueDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );

                        if (picked != null) {
                          setStateDialog(() => tempDueDate = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),

              actionsPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Color(0xFF0C2D83)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: TextStyle(color: Color(0xFF0C2D83)),
                        ),
                      ),
                    ),

                    SizedBox(width: 10),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (taskNameController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: Colors.white,
                                content: Text(
                                  "Please enter task name",
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
                            return;
                          }

                          await FirebaseFirestore.instance
                              .collection("users")
                              .doc(user!.uid)
                              .collection("tasks")
                              .add({
                                "task": taskNameController.text.trim(),
                                "completed": false,
                                "timestamp": FieldValue.serverTimestamp(),
                                "category": tempCategory,
                                "priority": tempPriority,
                                "dueDate": tempDueDate != null
                                    ? Timestamp.fromDate(tempDueDate!)
                                    : null,
                              });

                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0C2D83),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text("Add Task"),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =============================
  // LOGOUT DIALOG
  // =============================
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            "Logout",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF0C2D83),
            ),
          ),
          content: Text(
            "Are you sure you want to logout?",
            textAlign: TextAlign.center,
          ),
          actionsPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Color(0xFF0C2D83)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: Color(0xFF0C2D83)),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await FirebaseAuth.instance.signOut();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => LoginScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0C2D83),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text("Logout"),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // =============================
  // ADD TASK
  // =============================
  Future<void> addTask() async {
    if (taskController.text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .collection("tasks")
        .add({
          "task": taskController.text,
          "completed": false,
          "timestamp": FieldValue.serverTimestamp(),
          "category": selectedCategory,
          "priority": selectedPriority,
          "dueDate": selectedDueDate != null
              ? Timestamp.fromDate(selectedDueDate!)
              : null,
        });

    taskController.clear();
    selectedCategory = "School";
    selectedPriority = "Medium";
    selectedDueDate = null;
    setState(() {});
  }

  Future<void> editTask(String id, Map<String, dynamic> data) async {
    final TextEditingController taskNameController = TextEditingController(
      text: data["task"],
    );

    String tempCategory = data["category"] ?? "School";
    String tempPriority = data["priority"] ?? "Medium";
    DateTime? tempDueDate = data["dueDate"]?.toDate();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              title: Text(
                "Edit Task",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0C2D83),
                ),
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // TASK NAME
                    TextField(
                      controller: taskNameController,
                      decoration: InputDecoration(
                        labelText: "Task Name",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 15),

                    // CATEGORY
                    DropdownButtonFormField<String>(
                      initialValue: tempCategory,
                      decoration: InputDecoration(
                        labelText: "Category",
                        border: OutlineInputBorder(),
                      ),
                      items: categories
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          tempCategory = value!;
                        });
                      },
                    ),
                    SizedBox(height: 15),

                    // PRIORITY
                    DropdownButtonFormField<String>(
                      initialValue: tempPriority,
                      decoration: InputDecoration(
                        labelText: "Priority",
                        border: OutlineInputBorder(),
                      ),
                      items: priorities
                          .map(
                            (p) => DropdownMenuItem(value: p, child: Text(p)),
                          )
                          .toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          tempPriority = value!;
                        });
                      },
                    ),
                    SizedBox(height: 15),

                    // DUE DATE
                    TextFormField(
                      readOnly: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: tempDueDate == null
                            ? "Select Due Date"
                            : "Due: ${DateFormat('MMM d, yyyy').format(tempDueDate!)}",
                        suffixIcon: Icon(Icons.calendar_month),
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: tempDueDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );

                        if (picked != null) {
                          setStateDialog(() {
                            tempDueDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),

              actionsPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Cancel",
                          style: TextStyle(color: Color(0xFF0C2D83)),
                        ),
                      ),
                    ),

                    SizedBox(width: 10),

                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection("users")
                              .doc(user!.uid)
                              .collection("tasks")
                              .doc(id)
                              .update({
                                "task": taskNameController.text.trim(),
                                "category": tempCategory,
                                "priority": tempPriority,
                                "dueDate": tempDueDate != null
                                    ? Timestamp.fromDate(tempDueDate!)
                                    : null,
                              });

                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF0C2D83),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text("Save"),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =============================
  // DELETE TASK
  // =============================
  Future<void> deleteTask(String id, Map<String, dynamic> data) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: Text(
            "Delete Task",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          content: Text(
            "Are you sure you want to delete this task?",
            textAlign: TextAlign.center,
          ),

          // ⭐ Aligned buttons row
          actionsPadding: EdgeInsets.all(12),
          actions: [
            Row(
              children: [
                // CANCEL BUTTON
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
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

                // DELETE BUTTON
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);

                      // ⭐ CREATE SAFE COPY OF DATA
                      final deletedData = Map<String, dynamic>.from(data)
                        ..["deletedAt"] = Timestamp.now();

                      // 1️⃣ MOVE TO deleted_tasks
                      await FirebaseFirestore.instance
                          .collection("users")
                          .doc(user!.uid)
                          .collection("deleted_tasks")
                          .doc(id)
                          .set(deletedData);

                      // 2️⃣ REMOVE FROM tasks
                      await FirebaseFirestore.instance
                          .collection("users")
                          .doc(user!.uid)
                          .collection("tasks")
                          .doc(id)
                          .delete();

                      // 3️⃣ SNACKBAR UNDO
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Task deleted"),
                          duration: Duration(seconds: 5),
                          action: SnackBarAction(
                            label: "UNDO",
                            onPressed: () async {
                              final restoredData = Map<String, dynamic>.from(
                                data,
                              )..remove("deletedAt");

                              await FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(user!.uid)
                                  .collection("tasks")
                                  .doc(id)
                                  .set({
                                    ...restoredData,
                                    "timestamp": FieldValue.serverTimestamp(),
                                  });

                              await FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(user!.uid)
                                  .collection("deleted_tasks")
                                  .doc(id)
                                  .delete();
                            },
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text("Delete"),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // =============================
  // TOGGLE CHECKBOX
  // =============================
  Future<void> toggleTask(String id, bool value) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .collection("tasks")
        .doc(id)
        .update({"completed": value});
  }

  // =============================
  // UI
  // =============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Student Task Manager"),
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton(
            icon: Icon(Icons.menu),
            offset: Offset(0, kToolbarHeight),
            onSelected: (value) {
              if (value == "profile") {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ProfileScreen()),
                );
              } else if (value == "logout") {
                _showLogoutDialog();
              } else if (value == "history") {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DeleteHistoryScreen()),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: "profile",
                child: Row(
                  children: [
                    Icon(Icons.person, color: Color(0xFF0C2D83)),
                    SizedBox(width: 8),
                    Text("Profile"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: "history",
                child: Row(
                  children: [
                    Icon(Icons.history, color: Color(0xFF0C2D83)),
                    SizedBox(width: 8),
                    Text("Delete History"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: "logout",
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Color(0xFF0C2D83)),
                    SizedBox(width: 8),
                    Text("Logout"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: Container(
        color: Color(0xFFF5F6FA),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // GREETING
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("users")
                    .doc(user!.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Text(
                      "Hello!",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0C2D83),
                      ),
                    );
                  }
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  return Text(
                    "Hello, ${data["name"]} 👋",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0C2D83),
                    ),
                  );
                },
              ),

              SizedBox(height: 15),

              // SEARCH BAR
              TextField(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  labelText: "Search tasks...",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onChanged: (value) {
                  setState(() => searchQuery = value.toLowerCase());
                },
              ),

              SizedBox(height: 15),

              // ADD BUTTON
              ElevatedButton.icon(
                onPressed: _showAddTaskDialog,
                icon: Icon(Icons.add),
                label: Text("Add New Task"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0C2D83),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              SizedBox(height: 5),

              TextButton.icon(
                onPressed: () {
                  setState(() => showCalendar = !showCalendar);
                },
                style: TextButton.styleFrom(foregroundColor: Color(0xFF0C2D83)),
                icon: Icon(
                  showCalendar ? Icons.expand_less : Icons.expand_more,
                  color: Color(0xFF0C2D83),
                ),
                label: Text(
                  showCalendar ? "Hide Calendar" : "Show Calendar",
                  style: TextStyle(
                    color: Color(0xFF0C2D83),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // =====================
              //   CALENDAR CARD UI
              // =====================
              if (showCalendar)
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),

                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2035, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),

                    eventLoader: (day) {
                      final key = DateTime(day.year, day.month, day.day);
                      return taskEvents[key] ?? [];
                    },

                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Color(0xFF0C2D83),
                        shape: BoxShape.circle,
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),

                    calendarBuilders: CalendarBuilders(
                      markerBuilder: (context, day, events) {
                        if (events.isEmpty) return SizedBox();
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: events.take(3).map((event) {
                            final task = event as Map<String, dynamic>;
                            final priority = task["priority"] ?? "Low";

                            Color dotColor = priority == "High"
                                ? Colors.red
                                : priority == "Medium"
                                ? Colors.orange
                                : Colors.blue;

                            return Container(
                              margin: EdgeInsets.symmetric(horizontal: 2),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: dotColor,
                                shape: BoxShape.circle,
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),

                    onDaySelected: (day, focusedDay) {
                      setState(() {
                        _selectedDay = day;
                        _focusedDay = focusedDay;
                      });
                    },
                  ),
                ),

              SizedBox(height: 20),

              // =====================
              //   TASK LIST (scrollable)
              // =====================
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection("users")
                      .doc(user!.uid)
                      .collection("tasks")
                      .orderBy("timestamp", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;

                    taskEvents.clear();

                    for (var doc in docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (data["dueDate"] == null) continue;

                      final due = data["dueDate"].toDate();
                      final key = DateTime(due.year, due.month, due.day);

                      taskEvents[key] ??= [];
                      taskEvents[key]!.add(data);
                    }

                    // SORTING LOGIC
                    docs.sort((a, b) {
                      final A = a['dueDate']?.toDate();
                      final B = b['dueDate']?.toDate();

                      // CASE 1 — No selected date → normal sort (newest first)
                      if (_selectedDay == null) {
                        final tsA = a['timestamp'];
                        final tsB = b['timestamp'];

                        if (tsA == null && tsB == null) return 0;
                        if (tsA == null) return 1;
                        if (tsB == null) return -1;

                        return tsB.toDate().compareTo(tsA.toDate());
                      }

                      // CASE 2 — Check if task matches selected calendar day
                      bool aMatch =
                          A != null &&
                          A.year == _selectedDay!.year &&
                          A.month == _selectedDay!.month &&
                          A.day == _selectedDay!.day;

                      bool bMatch =
                          B != null &&
                          B.year == _selectedDay!.year &&
                          B.month == _selectedDay!.month &&
                          B.day == _selectedDay!.day;

                      // CASE 3 — If one matches selected day → put it first
                      if (aMatch && !bMatch) return -1;
                      if (!aMatch && bMatch) return 1;

                      // CASE 4 — Both match → sort ASCENDING by time
                      if (aMatch && bMatch) {
                        return A!.compareTo(B!);
                      }

                      // CASE 5 — Neither matches → sort newest first
                      final tsA = a['timestamp'];
                      final tsB = b['timestamp'];

                      if (tsA == null && tsB == null) return 0;
                      if (tsA == null) return 1;
                      if (tsB == null) return -1;

                      return tsB.toDate().compareTo(tsA.toDate());
                    });

                    if (docs.isEmpty) {
                      return Center(child: Text("No tasks yet"));
                    }

                    final List<Map<String, dynamic>> sortedTasks = docs.map((
                      doc,
                    ) {
                      return {
                        "id": doc.id,
                        "data": doc.data() as Map<String, dynamic>,
                      };
                    }).toList();

                    return ListView(
                      children: sortedTasks.map((task) {
                        final id = task["id"];
                        final data = task["data"];

                        final taskDate = data["dueDate"]?.toDate();

                        if (!data["task"].toLowerCase().contains(searchQuery)) {
                          return SizedBox.shrink();
                        }

                        // 🎨 NEW CARD UI (fixed)
                        return Container(
                          margin: EdgeInsets.only(bottom: 14),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                            border: Border(
                              left: BorderSide(
                                color: data["completed"]
                                    ? Colors.green
                                    : Color(0xFF0C2D83),
                                width: 6,
                              ),
                            ),
                          ),

                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: data["completed"],
                                activeColor: Color(0xFF0C2D83),
                                onChanged: (v) => toggleTask(id, v!),
                              ),

                              SizedBox(width: 6),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data["task"],
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        decoration: data["completed"]
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),

                                    SizedBox(height: 6),

                                    Row(
                                      children: [
                                        _chip(
                                          data["category"],
                                          Color(0xFF0C2D83),
                                          Colors.white,
                                        ),
                                        SizedBox(width: 8),
                                        _chip(
                                          data["priority"],
                                          Colors.orange.shade50,
                                          Colors.orange,
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: 10),

                                    Text(
                                      data["timestamp"] != null
                                          ? "Added: ${DateFormat('MMM d, yyyy – h:mm a').format(data['timestamp'].toDate())}"
                                          : "Added: Not available",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),

                                    if (taskDate != null)
                                      Text(
                                        "Due: ${DateFormat('MMM d, yyyy').format(taskDate)}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color:
                                              taskDate.isBefore(DateTime.now())
                                              ? Colors.red
                                              : Colors.blue,
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              Column(
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => editTask(id, data),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => deleteTask(id, data),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
