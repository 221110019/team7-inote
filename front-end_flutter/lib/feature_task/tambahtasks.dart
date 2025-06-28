import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inote/hive/hive_auth_box.dart';
import 'package:inote/model/task_model.dart';
import 'package:inote/model/group_model.dart';
import 'package:inote/hive/hive_group_box.dart';

class NewTaskPage extends StatefulWidget {
  final Function(
    String title,
    String category,
    List<ChecklistItemModel> checklist,
  ) onTaskAdded;

  const NewTaskPage({super.key, required this.onTaskAdded});

  @override
  NewTaskPageState createState() => NewTaskPageState();
}

class NewTaskPageState extends State<NewTaskPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController taskController = TextEditingController();
  String selectedCategory = "Private";
  List<ChecklistItemModel> checklist = [];
  List<GroupModel> allGroups = [];

  @override
  void initState() {
    super.initState();

    HiveGroupBox.init().then((_) {
      final username = HiveAuthBox.getActiveUsername() ?? '';
      setState(() {
        allGroups = HiveGroupBox.getGroups()
            .where((g) => g.leader == username || g.members.contains(username))
            .toList();

        selectedCategory = categoryList.contains(selectedCategory)
            ? selectedCategory
            : (categoryList.isNotEmpty ? categoryList.first : "Private");
      });
    });
  }

  void addTaskToChecklist() {
    if (taskController.text.trim().isNotEmpty) {
      setState(() {
        checklist.add(ChecklistItemModel(
          task: taskController.text.trim(),
          done: false,
        ));
        taskController.clear();
      });
    }
  }

  void removeTaskFromChecklist(int index) {
    setState(() {
      checklist.removeAt(index);
    });
  }

  void toggleTaskCompletion(int index) {
    setState(() {
      checklist[index] = ChecklistItemModel(
        task: checklist[index].task,
        done: !checklist[index].done,
      );
    });
  }

  void saveTask() {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Task title cannot be empty")),
      );
      return;
    }

    if (checklist.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Add at least one checklist item")),
      );
      return;
    }

    widget.onTaskAdded(title, selectedCategory, checklist);
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
        title: Text(
          'New Task',
          style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.indigoAccent,
        elevation: 4,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              style: GoogleFonts.poppins(
                  fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: "Task Title",
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                border: InputBorder.none,
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
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: taskController,
                    decoration: InputDecoration(
                      hintText: "Enter task item...",
                      hintStyle:
                          GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                      border: const UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.indigoAccent),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: addTaskToChecklist,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigoAccent,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(10),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: checklist.isEmpty
                  ? Center(
                      child: Text(
                        "No tasks added yet!",
                        style: GoogleFonts.poppins(
                            fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      key: ValueKey(checklist.length),
                      itemCount: checklist.length,
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            Dismissible(
                              key: ValueKey(checklist[index].task +
                                  checklist[index].done.toString()),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              onDismissed: (direction) {
                                removeTaskFromChecklist(index);
                              },
                              child: ListTile(
                                leading: Checkbox(
                                  activeColor: Colors.indigoAccent,
                                  value: checklist[index].done,
                                  onChanged: (value) =>
                                      toggleTaskCompletion(index),
                                ),
                                title: Text(
                                  checklist[index].task,
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    decoration: checklist[index].done
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                    color: checklist[index].done
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.grey),
                                  onPressed: () =>
                                      removeTaskFromChecklist(index),
                                ),
                              ),
                            ),
                            const Divider(color: Colors.grey),
                          ],
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
            "Save Task",
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.indigoAccent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
    );
  }
}
