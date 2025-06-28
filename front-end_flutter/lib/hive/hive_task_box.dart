import 'package:hive/hive.dart';

class HiveTaskBox {
  static const String boxName = 'tasksBox';

  static Future<void> init() async {
    await Hive.openBox(boxName);
  }

  static Box get box => Hive.box(boxName);
}
