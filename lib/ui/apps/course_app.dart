import 'package:flutter/material.dart';

import '../../content/content_repository.dart';
import '../../content/course.dart';
import '../hub/app_module.dart';
import '../screens/topic_list_screen.dart';
import '../widgets/screen_state.dart';
import '../widgets/tile_grid.dart';

class CourseApp implements AppModule {
  @override
  String get title => 'Stema Arena';

  @override
  IconData get icon => Icons.school;

  @override
  Widget build(BuildContext context) {
    return const StemaArenaScreen();
  }
}

class StemaArenaScreen extends StatefulWidget {
  const StemaArenaScreen({super.key});

  @override
  State<StemaArenaScreen> createState() => _StemaArenaScreenState();
}

class _StemaArenaScreenState extends State<StemaArenaScreen> {
  final ContentRepository content = ContentRepository();
  List<Course>? courses;
  Object? error;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final result = await content.courses();
      // The load is asynchronous and the screen can be popped mid-flight.
      if (!mounted) return;
      setState(() => courses = result);
    } on Object catch (e) {
      if (!mounted) return;
      // An unreadable index used to leave an empty grid and no explanation,
      // which reads as "there are no courses" rather than "this is broken".
      setState(() => error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stema Arena')),
      body: _body(),
    );
  }

  Widget _body() {
    final error = this.error;
    if (error != null) return ScreenMessage.failure(error);

    final courses = this.courses;
    if (courses == null) return const ScreenLoading();
    return TileGrid(
      tiles: [
        for (final course in courses)
          GridTileEntry(
            icon: Icons.functions,
            label: course.title,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TopicListScreen(course: course),
              ),
            ),
          ),
      ],
    );
  }
}
