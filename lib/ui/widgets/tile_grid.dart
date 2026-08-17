import 'package:flutter/material.dart';

/// A grid of tappable cards, each an icon over a label.
///
/// The hub and the course list were the same grid written twice, down to the
/// spacing, and only the second had learned to round its corners.
class TileGrid extends StatelessWidget {
  const TileGrid({super.key, required this.tiles});

  final List<GridTileEntry> tiles;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        for (final tile in tiles)
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: tile.onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    tile.icon,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(tile.label, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class GridTileEntry {
  const GridTileEntry({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}
