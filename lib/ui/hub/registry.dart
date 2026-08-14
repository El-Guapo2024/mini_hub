import '../apps/course_app.dart';
import '../apps/notes_app.dart';
import '../apps/physics_leetcode_app.dart';
import '../apps/physics_tools_app.dart';
import '../apps/projects_app.dart';
import '../apps/robotics_app.dart';
import 'app_module.dart';

final List<AppModule> registry = [
  CourseApp(),
  RoboticsApp(),
  PhysicsToolsApp(),
  PhysicsLeetcodeApp(),
  NotesApp(),
  ProjectsApp(),
];
