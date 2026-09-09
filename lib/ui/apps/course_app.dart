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

/// Physics, as its own way in.
///
/// The same screen over the same index, showing only the courses named here.
/// A subject is a selection of what already exists rather than a second kind
/// of thing, so nothing about loading, topics or progress differs — and a
/// course reached this way is the same course reached from the hub, with one
/// history rather than two.
class PhysicsApp implements AppModule {
  const PhysicsApp();

  /// Course ids this tile offers. Named here rather than read from a field on
  /// the course, because one list in one place is easier to check than a
  /// subject spelled out in every course file.
  static const courseIds = {'quantum'};

  @override
  String get title => 'Physics';

  @override
  IconData get icon => Icons.science;

  @override
  Widget build(BuildContext context) =>
      const StemaArenaScreen(title: 'Physics', only: courseIds);
}

class StemaArenaScreen extends StatefulWidget {
  const StemaArenaScreen({super.key, this.title = 'Stema Arena', this.only});

  /// What the bar says. The screen is the same either way; only the heading
  /// tells a student which way in they took.
  final String title;

  /// Ids to show, or null for every course the index names.
  final Set<String>? only;

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
      final only = widget.only;
      // The load is asynchronous and the screen can be popped mid-flight.
      if (!mounted) return;
      setState(
        () => courses = only == null
            ? result
            : [
                for (final c in result)
                  if (only.contains(c.id)) c,
              ],
      );
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
      appBar: AppBar(title: Text(widget.title)),
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
            // Guarded so a double tap does not stack the same course twice.
            onTap: () {
              if (ModalRoute.of(context)?.isCurrent != true) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TopicListScreen(course: course),
                ),
              );
            },
          ),
      ],
    );
  }
}
