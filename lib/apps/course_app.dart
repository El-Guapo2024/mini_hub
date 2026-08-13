import 'package:flutter/material.dart';
import '../hub/app_module.dart';
import '../models/course.dart';
import '../data/course_index_loader.dart';
import '../data/course_loader.dart';
import '../screens/topic_list_screen.dart';

class CourseApp implements AppModule {
  @override
  String get id => 'course';

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
  final CourseIndexLoader indexLoader = CourseIndexLoader();
  final CourseLoader courseLoader = CourseLoader();
  List<Course> courses = [];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final paths = await indexLoader.load('assets/mock/courses.json');
    final result = <Course>[];
    for (final path in paths) {
      result.add(await courseLoader.load(path));
    }
    setState(() {
      courses = result;
    });
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
      body: GridView.count(
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
                  Text(
                    course.title,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
