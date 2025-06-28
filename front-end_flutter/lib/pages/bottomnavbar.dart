import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inote/hive/hive_sync_box.dart';
import 'package:inote/pages/main_group.dart';
import 'package:inote/pages/main_homepage.dart';
import 'package:inote/pages/main_me.dart';
import 'package:inote/refresh_sync.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  BottomNavBarState createState() => BottomNavBarState();
}

class BottomNavBarState extends State<BottomNavBar>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _refreshController;
  late bool _isSyncing = false;

  final List<Widget> _pages = [
    const MainHomepage(),
    const MainMe(),
    const MainGroup(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  void _onRefresh() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    await refreshSync(context, _refreshController);
    setState(() => _isSyncing = false);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    TextButton refreshButton = TextButton(
      style: TextButton.styleFrom(
        foregroundColor: Colors.indigoAccent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.indigoAccent, width: 1),
        ),
        backgroundColor: const Color.fromARGB(134, 115, 133, 236),
      ),
      onPressed: _isSyncing ? null : _onRefresh,
      onLongPress: () => _changeApiUrl(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _refreshController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _refreshController.value * 2 * 3.1416,
                child: child,
              );
            },
            child: const Icon(Icons.cloud_sync, size: 22),
          ),
          const SizedBox(width: 8),
          Text(
            'Refresh & sync',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.indigoAccent,
            ),
          ),
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 0,
        title: refreshButton,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniStartTop,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'My',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Groups',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigoAccent,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }
}

Future<void> _changeApiUrl(BuildContext context) async {
  final controller = TextEditingController(text: HiveSyncBox.apiUrl);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Set API URL'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(labelText: 'API URL'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save')),
      ],
    ),
  );
  if (result != null && result.isNotEmpty) {
    await HiveSyncBox.setApiUrl(result);
  }
}
