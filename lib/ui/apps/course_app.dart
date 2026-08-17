import 'package:flutter/material.dart';

import '../../content/content_repository.dart';
import '../../content/course.dart';
import '../hub/app_module.dart';
import '../screens/topic_list_screen.dart';
import '../widgets/screen_state.dart';

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
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.white,
        title: const Text('Stema Arena'),
        centerTitle: true,
      ),
      body: _body(),
    );
  }

  Widget _body() {
    final error = this.error;
    if (error != null) return ScreenMessage.failure(error);

    final courses = this.courses;
    if (courses == null) return const ScreenLoading();
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: courses.map((course) {
        return Card(
          color: Colors.grey.shade900,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TopicListScreen(course: course),
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.functions, size: 48, color: Colors.teal.shade400),
                const SizedBox(height: 8),
                Text(course.title, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
