import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:inote/hive/hive_auth_box.dart';
import 'package:intl/intl.dart';
import 'package:inote/feature_note/tambahnotes.dart';
import 'package:inote/feature_task/tambahtasks.dart';
import 'package:provider/provider.dart';
import 'package:inote/provider/providernote.dart';
import 'package:inote/feature_note/editnote.dart';
import 'package:inote/feature_task/edittask.dart';
import 'package:inote/model/note_model.dart';
import 'package:inote/model/task_model.dart';

class MainHomepage extends StatefulWidget {
  const MainHomepage({super.key});

  @override
  MainHomepageState createState() => MainHomepageState();
}

class MainHomepageState extends State<MainHomepage> {
  TextEditingController scratchPadController = TextEditingController();
  String _searchQuery = '';

  void convertToNote() {
    if (scratchPadController.text.isNotEmpty) {
      Provider.of<NoteProvider>(context, listen: false).addNote(
        'Untitled Note',
        scratchPadController.text,
        'Private',
        HiveAuthBox.getActiveUsername() ?? 'Guest',
      );
      scratchPadController.clear();
    }
  }

  void clearScratchPad() {
    scratchPadController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NoteProvider>().notes;
    final tasks = context.watch<TaskProvider>().tasks;
    final username = HiveAuthBox.getActiveUsername() ?? '';
    final userGroups = Hive.box('groupsBox')
        .values
        .where((g) => (g is Map &&
            (g['leader'] == username ||
                (g['members'] as List?)?.contains(username) == true)))
        .map((g) => g['name'] as String)
        .toSet();

    final combined = [
      ...notes.map((n) => {'type': 'note', 'model': n}),
      ...tasks.map((t) => {'type': 'task', 'model': t}),
    ];
    combined.sort((a, b) {
      final aModel = a['model'];
      final bModel = b['model'];
      final aTime = aModel is NoteModel
          ? aModel.timestamp
          : (aModel as TaskModel).timestamp;
      final bTime = bModel is NoteModel
          ? bModel.timestamp
          : (bModel as TaskModel).timestamp;
      return bTime.compareTo(aTime);
    });

    final filteredCombined = combined.where((item) {
      if (item['type'] == 'note') {
        final n = item['model'] as NoteModel;
        final isOwnPrivate = n.category == 'Private' && n.by == username;
        final isAllowedGroup = userGroups.contains(n.category);
        final isAllowed = isOwnPrivate || isAllowedGroup;
        return isAllowed &&
            (n.by.toLowerCase().contains(username.toLowerCase()) ||
                n.title.toLowerCase().contains(_searchQuery) ||
                n.category.toLowerCase().contains(_searchQuery) ||
                n.content.toLowerCase().contains(_searchQuery));
      } else {
        final t = item['model'] as TaskModel;
        final isOwnPrivate = t.category == 'Private' && t.by == username;
        final isAllowedGroup = userGroups.contains(t.category);
        final isAllowed = isOwnPrivate || isAllowedGroup;
        return isAllowed &&
            (t.by.toLowerCase().contains(username.toLowerCase()) ||
                t.title.toLowerCase().contains(_searchQuery) ||
                t.category.toLowerCase().contains(_searchQuery) ||
                t.checklist
                    .map((item) => item.task.toLowerCase())
                    .join(' ')
                    .contains(_searchQuery));
      }
    }).toList();

    String formattedDate =
        DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now());

    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(16.0),
        height: MediaQuery.of(context).size.height,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    "${(HiveAuthBox.getActiveUsername() ?? 'Guest').toUpperCase()}'s iNotes",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigoAccent,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    formattedDate,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12, blurRadius: 4, spreadRadius: 2),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: "Find any note or task",
                  hintStyle: GoogleFonts.poppins(color: Colors.grey),
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSelectionBox(
                  context,
                  icon: Icons.note_add,
                  label: "New Note",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NewNotePage(),
                      ),
                    );
                  },
                ),
                _buildSelectionBox(
                  context,
                  icon: Icons.task,
                  label: "New Task",
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NewTaskPage(
                            onTaskAdded: (title, category, checklist) {
                              Provider.of<TaskProvider>(context, listen: false)
                                  .addTask(
                                      title,
                                      category,
                                      checklist.map<ChecklistItemModel>((item) {
                                        return item;
                                      }).toList(),
                                      HiveAuthBox.getUser()?.username ??
                                          'Guest');
                            },
                          ),
                        ));
                  },
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              "Recent Notes & Tasks",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: filteredCombined.isNotEmpty
                  ? ListView.builder(
                      itemCount: filteredCombined.length,
                      itemBuilder: (context, index) {
                        final item = filteredCombined[index];
                        final isNote = item['type'] == 'note';
                        if (isNote) {
                          final n = item['model'] as NoteModel;
                          final originalIndex = notes.indexOf(n);
                          return Card(
                            elevation: 2,
                            child: ListTile(
                              leading: const Icon(Icons.note,
                                  color: Colors.indigoAccent),
                              dense: true,
                              title:
                                  Text(n.title, style: GoogleFonts.poppins()),
                              subtitle: Text(
                                'Note: ${n.category}',
                                style: GoogleFonts.poppins(color: Colors.grey),
                              ),
                              onTap: () async {
                                if (originalIndex != -1) {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditNotePage(
                                        index: originalIndex,
                                        note: n,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text("Note updated successfully!"),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          );
                        } else {
                          final t = item['model'] as TaskModel;
                          final originalIndex = tasks.indexOf(t);
                          return Card(
                            elevation: 2,
                            child: ListTile(
                              leading: const Icon(
                                Icons.check_box,
                                color: Colors.indigoAccent,
                              ),
                              dense: true,
                              title: Text(
                                t.title,
                                style: GoogleFonts.poppins(),
                              ),
                              subtitle: Text(
                                'Task: ${t.category}',
                                style: GoogleFonts.poppins(color: Colors.grey),
                              ),
                              onTap: () async {
                                if (originalIndex != -1) {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditTaskPage(
                                        task: t,
                                        taskIndex: originalIndex,
                                        onTaskUpdated:
                                            (title, category, checklist, idx) {
                                          Provider.of<TaskProvider>(context,
                                                  listen: false)
                                              .editTask(
                                            idx,
                                            title,
                                            category,
                                            checklist
                                                .cast<ChecklistItemModel>(),
                                            HiveAuthBox.getUser()?.username ??
                                                'Guest',
                                          );
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                  );

                                  if (result == true) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text("Task updated successfully!"),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                          );
                        }
                      },
                    )
                  : Center(
                      child: Text(
                        "No notes or tasks yet",
                        style: GoogleFonts.poppins(
                            fontSize: 16, color: Colors.grey),
                      ),
                    ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Scratch Pad",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'convert') {
                      convertToNote();
                    } else if (value == 'clear') {
                      clearScratchPad();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'convert',
                      child: Row(
                        children: [
                          const Icon(Icons.note_add,
                              color: Colors.indigoAccent),
                          const SizedBox(width: 12),
                          Text("Convert to note",
                              style: GoogleFonts.poppins(fontSize: 16)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'clear',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_forever,
                              color: Colors.redAccent),
                          const SizedBox(width: 12),
                          Text("Clear all",
                              style: GoogleFonts.poppins(fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              height: 100,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12, blurRadius: 4, spreadRadius: 2)
                ],
              ),
              child: TextField(
                controller: scratchPadController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Write a temporary note...",
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionBox(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.indigoAccent,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 5, spreadRadius: 2)
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
