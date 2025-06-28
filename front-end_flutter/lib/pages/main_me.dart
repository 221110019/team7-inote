import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inote/feature_account/account_setting_page.dart';
import 'package:inote/feature_note/notes.dart';
import 'package:inote/feature_task/tasks.dart';
import 'package:inote/hive/hive_auth_box.dart';
import 'package:inote/feature_account/authentication_page.dart';

class MainMe extends StatelessWidget {
  const MainMe({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Account Setting",
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.indigoAccent,
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          await logout(context);
                        },
                        icon: const Icon(
                          Icons.logout,
                          color: Colors.red,
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigoAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.settings, color: Colors.white),
                    label: Text(
                      "Go to Account Setting",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AccountSettingPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  TabBar(
                    labelStyle:
                        GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    indicatorColor: Colors.indigoAccent,
                    labelColor: Colors.indigoAccent,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: 'Notes'),
                      Tab(text: 'Tasks'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TabBarView(
                      children: [
                        NotesListContainer(
                          heightFactor: 1.0,
                          filterType: 'My Private Note',
                          filter: (note, search) {
                            final activeUser = HiveAuthBox.getActiveUsername()
                                    ?.toLowerCase() ??
                                'guest';

                            return note.category
                                    .toLowerCase()
                                    .contains('private') &&
                                note.by.toLowerCase() == activeUser &&
                                (note.title.toLowerCase().contains(search) ||
                                    note.content
                                        .toLowerCase()
                                        .contains(search));
                          },
                        ),
                        TasksListContainer(
                          heightFactor: 1.0,
                          filterType: 'My Private Task',
                          hasSearchBar: true,
                          filter: (task, search) =>
                              task.category.toLowerCase().contains('private') &&
                              task.by.toLowerCase().contains(
                                  HiveAuthBox.getActiveUsername()!
                                      .toLowerCase()) &&
                              (task.title.toLowerCase().contains(search) ||
                                  (task.checklist
                                      .map((item) => item.task.toLowerCase())
                                      .join(' ')
                                      .contains(search))),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> logout(BuildContext context) async {
    await HiveAuthBox.logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthenticationPage()),
        (route) => false,
      );
    }
  }
}
