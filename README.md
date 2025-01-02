# Thump

## Description

A simple 2D collision system for axis-aligned bounding boxes.

## Features

- Tunneling - No matter the speed of an object it will hit anything it collides
  with, provided the dimensions of the objects is >= 1.
- Slide, Pass, Touch, Bounce (unimplemented) behaviors when
  resolving collisions.

## Example

```dart
import 'package:thump/thump.dart';

void main() {
  final Object block = Object();
  final Object man = Object();
  final World world = World(1024, 1024);
  world.add(block, AABB.xywh(x: 64, y: 16, width: 16, height: 16));
  world.add(man, AABB.xywh(x: 47, y: 16, width: 16, height: 16));
  MoveResult result = world.move(man, 2, 0);
  print(result.collisions.length);
}
```

## Algorithm

1) Store objects in [quadtree](https://en.wikipedia.org/wiki/Quadtree).
1) Create a union AABB around the starting point and ending point.
1) Query quadtree with the union to find potential collisions.
1) Move the object <= 1 units ([Nyquist
   frequency](https://en.wikipedia.org/wiki/Nyquist_frequency)) at a time
   checking against potential collisions and resolving behaviors.

## To do

- Implement Bounce behavior
- Create infastructure to run all benchmarks
- Report which edges collided in results

## Potential optimizations

1) Instead of using a union AABB to calculate potential collisions, use a convex
   hull around starting and ending AABB.
1) Sort potential collisions based on their distance to the starting point.
1) Have a private AABB that is mutable to avoid generating garbage.
1) Make potentials come back as a mini quadtree
1) Divide large Move()'s into smaller moves

## Recognitions

The API was inspired by [bump.lua](https://github.com/kikito/bump.lua).  That is
an excellent physics engine and much more impressive than this one.  This is a
simplified equivalent that I implemented when really wanted it for Dart.

## License

[MIT](https://opensource.org/license/mit)
