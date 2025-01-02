import 'package:thump/thump.dart';

/// Tries repeatedly to punch through hundreds of objects on the horizontal plane.

void main() {
  const int tileWidth = 10 * 32;
  const int tileHeight = 18;
  const double tileSize = 16;
  final World world = World(tileWidth * tileSize, tileHeight * tileSize);
  const int column = 9;
  for (int j = 1; j < tileWidth - 1; ++j) {
    world.add(
        Object(),
        AABB.xywh(
            x: j * tileSize,
            y: column.toDouble(),
            width: tileSize,
            height: tileSize));
  }

  Object left = Object();
  world.add(left, AABB.xywh(x: 0, y: column.toDouble(), width: 16, height: 16));

  Object right = Object();
  world.add(
      right,
      AABB.xywh(
          x: (tileWidth - 1 * 16),
          y: column.toDouble(),
          width: 16,
          height: 16));

  const int iterations = 500;
  final double moveCount = ((tileWidth - 1) * 16).toDouble();

  Stopwatch stopwatch = Stopwatch();
  stopwatch.start();

  for (int i = 0; i < iterations; ++i) {
    world.move(left, moveCount, 0);
    world.move(right, -moveCount, 0);
  }

  stopwatch.stop();
  int count = iterations * 2;
  print('${stopwatch.elapsedMilliseconds / count} ms per move');
}
