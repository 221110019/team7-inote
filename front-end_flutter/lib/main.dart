import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:inote/hive/hive_auth_box.dart';
import 'package:inote/hive/hive_group_box.dart';
import 'package:inote/hive/hive_note_box.dart';
import 'package:inote/hive/hive_sync_box.dart';
import 'package:inote/hive/hive_task_box.dart';
import 'package:inote/pages/loadingscreen.dart';
import 'package:provider/provider.dart';
import 'package:inote/provider/providernote.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await HiveAuthBox.init();
  await HiveGroupBox.init();
  await HiveNoteBox.init();
  await HiveTaskBox.init();
  await HiveSyncBox.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'iNote',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
