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
    // Sized by how big a tile should be, not by how many fit across. Two
    // columns is right on a phone and absurd on a 13-inch iPad, where it gave
    // each tile a third of a metre of card with a 48-pixel icon adrift in the
    // middle of it. Asking for a maximum width instead means the phone still
    // gets two and the iPad gets as many as it has room for.
    return GridView.extent(
      maxCrossAxisExtent: 240,
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
