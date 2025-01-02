import 'package:thump/thump.dart';

/// Moves a tile back and forth horizontally surrounded by tile sized items with
/// no collisions at super high speeds.

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

  const int iterations = 10000;
  const int moveCount = (tileWidth - 1) * 16;

  Stopwatch stopwatch = Stopwatch();
  stopwatch.start();

  for (int i = 0; i < iterations; ++i) {
    world.move(man, moveCount.toDouble(), 0);
    world.move(man, -moveCount.toDouble(), 0);
  }

  stopwatch.stop();

  int count = iterations * 2;
  print('${stopwatch.elapsedMilliseconds / count} ms per move');
}
