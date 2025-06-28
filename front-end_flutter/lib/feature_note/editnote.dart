import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inote/hive/hive_auth_box.dart';
import 'package:provider/provider.dart';
import 'package:inote/provider/providernote.dart';
import 'package:inote/model/note_model.dart';
import 'package:inote/hive/hive_group_box.dart';
import 'package:inote/model/group_model.dart';

class EditNotePage extends StatefulWidget {
  final int index;
  final NoteModel note;

  const EditNotePage({
    super.key,
    required this.index,
    required this.note,
  });

  @override
  EditNotePageState createState() => EditNotePageState();
}

class EditNotePageState extends State<EditNotePage> {
  late TextEditingController titleController;
  late TextEditingController contentController;
  String selectedCategory = "Private";
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

        selectedCategory = categoryList.contains(widget.note.category)
            ? widget.note.category
            : (categoryList.isNotEmpty ? categoryList.first : "Private");
      });
    });

    titleController = TextEditingController(text: widget.note.title);
    contentController = TextEditingController(text: widget.note.content);
  }

  void saveNote() {
    final title = titleController.text.trim();
    final content = contentController.text.trim();

    if (title.isNotEmpty) {
      Provider.of<NoteProvider>(context, listen: false).editNote(
        widget.index,
        title,
        content,
        selectedCategory,
        HiveAuthBox.getUser()?.username ?? 'Guest',
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Note title cannot be empty")),
      );
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
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
          'Edit Note',
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
                hintText: "Note Title",
                hintStyle: GoogleFonts.poppins(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Last modified by: ${widget.note.by.toUpperCase()}",
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
            ),
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
            Expanded(
              child: TextField(
                controller: contentController,
                maxLines: null,
                expands: true,
                style: GoogleFonts.poppins(fontSize: 16),
                decoration: InputDecoration(
                  hintText: "Start writing your note...",
                  hintStyle: GoogleFonts.poppins(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: saveNote,
          icon: const Icon(Icons.save, color: Colors.white),
          label: Text(
            "Save Note",
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.indigoAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}
