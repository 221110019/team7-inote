import 'package:hive/hive.dart';

class HiveNoteBox {
  static const String boxName = 'notesBox';

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  static Box get box => Hive.box(boxName);
}
