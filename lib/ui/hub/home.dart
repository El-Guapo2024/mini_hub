import 'package:flutter/material.dart';

import '../widgets/tile_grid.dart';
import 'registry.dart';

class HubHome extends StatelessWidget {
  const HubHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mini Hub'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade700, height: 1),
        ),
      ),
      body: TileGrid(
        tiles: [
          for (final app in registry)
            GridTileEntry(
              icon: app.icon,
              label: app.title,
              // Guarded so a double tap does not stack the same app twice.
              onTap: () {
                if (ModalRoute.of(context)?.isCurrent != true) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => app.build(context)),
                );
              },
            ),
        ],
      ),
    );
  }
}
