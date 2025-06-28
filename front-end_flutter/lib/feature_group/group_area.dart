import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inote/feature_note/notes.dart';
import 'package:inote/feature_task/tasks.dart';

class GroupArea extends StatelessWidget {
  final String groupId;
  final String groupName;
  final List? members;
  const GroupArea({
    super.key,
    required this.groupId,
    required this.groupName,
    this.members,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Badge(
            alignment: Alignment.bottomLeft,
            backgroundColor: Colors.black,
            label: Text(
              '${members?.length} member',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
            child: Text(
              '$groupName (#$groupId)',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          backgroundColor: Colors.indigoAccent,
          foregroundColor: Colors.white,
          bottom: TabBar(
            labelStyle: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.white),
            indicatorColor: Colors.white,
            tabs: const [
              Tab(text: 'Notes'),
              Tab(text: 'Tasks'),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  NotesListContainer(
                    filterType: 'Group Note',
                    filter: (note, search) =>
                        note.category.toLowerCase() ==
                            groupName.toLowerCase() &&
                        (note.title.toLowerCase().contains(search) ||
                            (note.content).toLowerCase().contains(search)),
                    heightFactor: 1.0,
                  ),
                  TasksListContainer(
                    filterType: "Group Task",
                    filter: (task, search) =>
                        task.category.toLowerCase() ==
                            groupName.toLowerCase() &&
                        task.title.toLowerCase().contains(search),
                    heightFactor: 1.0,
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
