import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inote/hive/hive_auth_box.dart';
import 'package:inote/model/task_model.dart';
import 'package:provider/provider.dart';
import 'package:inote/provider/providernote.dart';
import 'package:inote/feature_task/edittask.dart';

typedef TaskFilter = bool Function(TaskModel task, String searchQuery);

class TasksListContainer extends StatefulWidget {
  final TaskFilter? filter;
  final double? heightFactor;
  final bool hasSearchBar;
  final String filterType;

  const TasksListContainer({
    super.key,
    this.filter,
    this.heightFactor,
    this.hasSearchBar = true,
    required this.filterType,
  });

  @override
  State<TasksListContainer> createState() => _TasksListContainerState();
}

class _TasksListContainerState extends State<TasksListContainer> {
  String _searchQuery = '';

  Widget _buildTaskCard(BuildContext context, TaskModel task, int index) {
    final checklist = task.checklist;
    String formattedTime = '';

    final ts = task.timestamp;
    formattedTime =
        '${ts.day.toString().padLeft(2, '0')}/${ts.month.toString().padLeft(2, '0')}/${ts.year} '
        '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}';

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.task_alt, color: Colors.indigoAccent),
              title: Text(
                task.title,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${task.category} • ${formattedTime.isNotEmpty ? formattedTime : '-'}',
                style:
                    GoogleFonts.poppins(color: Colors.grey[600], fontSize: 13),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete,
                    color: Color.fromARGB(255, 104, 104, 104)),
                onPressed: () {
                  Provider.of<TaskProvider>(context, listen: false)
                      .deleteTask(index);
                },
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditTaskPage(
                      task: task,
                      taskIndex: index,
                      onTaskUpdated: (newTitle, newCategory, newChecklist, i) {
                        Provider.of<TaskProvider>(context, listen: false)
                            .editTask(
                          i,
                          newTitle,
                          newCategory,
                          newChecklist,
                          HiveAuthBox.getActiveUsername() ?? 'Guest',
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            if (checklist.isNotEmpty)
              ...checklist.map<Widget>((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        item.done
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: item.done ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.task,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            decoration:
                                item.done ? TextDecoration.lineThrough : null,
                            color: item.done ? Colors.grey : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            if (checklist.isEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  'No checklist items',
                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
                ),
              )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TaskProvider>().tasks;

    final filteredTasks = tasks.where((task) {
      if (widget.filter != null) {
        return widget.filter!(task, _searchQuery);
      }
      final title = (task.title).toLowerCase();
      final category = (task.category).toLowerCase();
      return title.contains(_searchQuery) || category.contains(_searchQuery);
    }).toList();

    final heightFactor = widget.heightFactor ?? 0.4;
    final containerHeight = MediaQuery.of(context).size.height * heightFactor;

    return Container(
      height: containerHeight,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, spreadRadius: 2),
        ],
      ),
      child: Column(
        children: [
          if (widget.hasSearchBar)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search ${widget.filterType.toLowerCase()}",
                  hintStyle: GoogleFonts.poppins(color: Colors.grey),
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: filteredTasks.isNotEmpty
                ? ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      final originalIndex = tasks.indexOf(task);
                      return _buildTaskCard(context, task, originalIndex);
                    },
                  )
                : Center(
                    child: Text(
                      "No tasks found.",
                      style:
                          GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
