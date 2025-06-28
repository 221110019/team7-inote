import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inote/hive/hive_auth_box.dart';
import 'package:inote/model/task_model.dart';
import 'package:inote/model/group_model.dart';
import 'package:inote/hive/hive_group_box.dart';

class EditTaskPage extends StatefulWidget {
  final TaskModel task;
  final int taskIndex;
  final Function(String, String, List<ChecklistItemModel>, int) onTaskUpdated;

  const EditTaskPage({
    required this.task,
    required this.taskIndex,
    required this.onTaskUpdated,
    super.key,
  });

  @override
  State<EditTaskPage> createState() => EditTaskPageState();
}

class EditTaskPageState extends State<EditTaskPage> {
  late TextEditingController titleController;
  late List<ChecklistItemModel> checklist;
  late String selectedCategory;
  List<GroupModel> allGroups = [];

  @override
  void initState() {
    super.initState();

    HiveGroupBox.init().then((_) {
      final username = HiveAuthBox.getActiveUsername() ?? '';
      final groups = HiveGroupBox.getGroups()
          .where((g) => g.leader == username || g.members.contains(username))
          .toList();

      setState(() {
        allGroups = groups;
        selectedCategory = categoryList.contains(widget.task.category)
            ? widget.task.category
            : (categoryList.isNotEmpty ? categoryList.first : "Private");
      });
    });

    titleController = TextEditingController(text: widget.task.title);
    checklist = List<ChecklistItemModel>.from(widget.task.checklist);
    selectedCategory = widget.task.category;
  }

  void toggleChecklist(int index) {
    setState(() {
      checklist[index] = ChecklistItemModel(
        task: checklist[index].task,
        done: !checklist[index].done,
      );
    });
  }

  void saveTask() {
    widget.onTaskUpdated(
      titleController.text,
      selectedCategory,
      checklist,
      widget.taskIndex,
    );
    Navigator.pop(context);
  }

  List<String> get categoryList {
    final groupNames = allGroups.map((g) => g.name).toSet().toList();
    return ['Private', ...groupNames];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text("Edit Task", style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.indigoAccent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Title",
                labelStyle: GoogleFonts.poppins(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.category, color: Colors.indigoAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String>(
                    value: categoryList.contains(selectedCategory)
                        ? selectedCategory
                        : "Private",
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          selectedCategory = newValue;
                        });
                      }
                    },
                    items: categoryList.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(
                          category,
                          style: GoogleFonts.poppins(),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: checklist.length,
                itemBuilder: (context, index) {
                  return CheckboxListTile(
                    title: Text(checklist[index].task,
                        style: GoogleFonts.poppins()),
                    value: checklist[index].done,
                    onChanged: (_) => toggleChecklist(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: saveTask,
          icon: const Icon(Icons.save, color: Colors.white),
          label: Text(
            "Save",
            style: GoogleFonts.poppins(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigoAccent,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }
}
