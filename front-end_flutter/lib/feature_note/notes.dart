import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inote/hive/hive_auth_box.dart';
import 'package:provider/provider.dart';
import 'package:inote/provider/providernote.dart';
import 'package:inote/feature_note/editnote.dart';
import 'package:inote/model/note_model.dart';

typedef NoteFilter = bool Function(NoteModel note, String searchQuery);

class NotesListContainer extends StatefulWidget {
  final NoteFilter? filter;
  final String filterType;
  final double? heightFactor;
  final bool hasSearchBar;

  const NotesListContainer({
    super.key,
    this.filter,
    this.hasSearchBar = true,
    required this.filterType,
    this.heightFactor,
  });

  @override
  State<NotesListContainer> createState() => _NotesListContainerState();
}

class _NotesListContainerState extends State<NotesListContainer> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final notes = context.watch<NoteProvider>().notes;

    final username = HiveAuthBox.getActiveUsername()?.toLowerCase() ?? 'guest';

    final filteredNotes = notes.where((note) {
      if (widget.filter != null) {
        return widget.filter!(note, _searchQuery);
      }
      final title = note.title.toLowerCase();
      final content = note.content.toLowerCase();
      final by = note.by.toLowerCase();

      return title.contains(_searchQuery) ||
          content.contains(_searchQuery) ||
          by.contains(username);
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
                  hintText: "Search ${widget.filterType.toLowerCase()}",
                  hintStyle: GoogleFonts.poppins(color: Colors.grey),
                  border: InputBorder.none,
                  icon: const Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
          const SizedBox(height: 20),
          Expanded(
            child: filteredNotes.isNotEmpty
                ? ListView.builder(
                    itemCount: filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = filteredNotes[index];
                      final originalIndex = notes.indexOf(note);
                      final timestamp = note.timestamp;
                      String formattedTime = '';

                      formattedTime =
                          '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} '
                          '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          leading: const Icon(Icons.note, color: Colors.indigo),
                          title: Text(
                            note.title,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            formattedTime.isNotEmpty ? formattedTime : '-',
                            style: GoogleFonts.poppins(color: Colors.grey[600]),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditNotePage(
                                  index: originalIndex,
                                  note: note,
                                ),
                              ),
                            );
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete,
                                color: Color.fromARGB(255, 104, 104, 104)),
                            onPressed: () {
                              Provider.of<NoteProvider>(context, listen: false)
                                  .deleteNote(originalIndex);
                            },
                          ),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      "No notes found.",
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
