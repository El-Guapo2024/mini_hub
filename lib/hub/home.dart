import 'package:flutter/material.dart';
import 'registry.dart';

class HubHome extends StatelessWidget {
  const HubHome({super.key});
  
  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.grey.shade900,
        title: const Text('Mini Hub'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade700, height: 1)
          ),
        ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16, 
        crossAxisSpacing: 16, 
        children: registry.map((app) {
        return Card(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => app.build(context),
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(app.icon, size: 48),
                const SizedBox(height: 8),
                Text(app.title),
              ],
            ),
          )
        );
        }).toList(),
      ),
    );
  }
} 
