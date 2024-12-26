import 'package:thump/thump.dart';

/// Moves a tile back and forth horizontally surrounded by tile sized items with
/// no collisions.

void main() {
  const int tileWidth = 10 * 32;
  const int tileHeight = 18;
  const double tileSize = 16;
  final World world = World(tileWidth * tileSize, tileHeight * tileSize);
  const int column = 9;
  for (int i = 0; i < tileHeight; ++i) {
    for (int j = 0; j < tileWidth; ++j) {
      if (i == column) {
        continue;
      }
      world.add(
          Object(),
          AABB.xywh(
              x: j * tileSize,
              y: i * tileSize,
              width: tileSize,
              height: tileSize));
    }
  }

  Object man = Object();
  world.add(man, AABB.xywh(x: 0, y: column * tileSize, width: 16, height: 16));

  Stopwatch stopwatch = Stopwatch();
  stopwatch.start();

  const int iterations = 10;
  const int moveCount = (tileWidth - 1) * 16;
  for (int i = 0; i < iterations; ++i) {
    for (int j = 0; j < moveCount; ++j) {
      world.move(man, 1, 0);
    }
    for (int j = 0; j < moveCount; ++j) {
      world.move(man, -1, 0);
    }
  }
  int count = iterations * moveCount * 2;

  print('${stopwatch.elapsedMilliseconds / count} ms per move');
}
