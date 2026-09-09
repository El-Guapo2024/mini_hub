import 'package:flutter/material.dart';

import '../hub/app_module.dart';
import '../screens/library_screen.dart';

class ChineseApp implements AppModule {
  const ChineseApp();

  @override
  String get title => 'Chinese';

  @override
  IconData get icon => Icons.menu_book;

  @override
  Widget build(BuildContext context) => const LibraryScreen();
}
