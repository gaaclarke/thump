import 'package:test/test.dart';
import 'package:thump/thump.dart';

void main() {
  test('queryObject', () {
    Object foo = Object();
    World world = World(1024, 1024);
    world.add(foo, AABB.xywh(x: 16, y: 16, width: 16, height: 16));
    AABB? result = world.queryObject(foo);
    expect(result, isNotNull);
    if (result != null) {
      expect(result.x, closeTo(16, 0.01));
      expect(result.y, closeTo(16, 0.01));
      expect(result.width, closeTo(16, 0.01));
      expect(result.height, closeTo(16, 0.01));
    }
  });

  test('queryAABB', () {
    Object foo = Object();
    World world = World(1024, 1024);
    world.add(foo, AABB.xywh(x: 16, y: 16, width: 16, height: 16));
    List<Result> collisions =
        world.queryAABB(AABB.xywh(x: 16, y: 16, width: 16, height: 16));
    expect(collisions.length, 1);
    expect(collisions[0].object, foo);
  });

  test('queryAABB ignore', () {
    Object foo = Object();
    World world = World(1024, 1024);
    world.add(foo, AABB.xywh(x: 16, y: 16, width: 16, height: 16));
    List<Result> collisions = world
        .queryAABB(AABB.xywh(x: 16, y: 16, width: 16, height: 16), ignore: foo);
    expect(collisions.length, 0);
  });

  test('queryAABB negative', () {
    Object foo = Object();
    World world = World(1024, 1024);
    world.add(foo, AABB.xywh(x: 16, y: 16, width: 16, height: 16));
    List<Result> collisions =
        world.queryAABB(AABB.xywh(x: 100, y: 16, width: 16, height: 16));
    expect(collisions.length, 0);
  });

  test('queryAABB touching', () {
    Object foo = Object();
    World world = World(1024, 1024);
    world.add(foo, AABB.xywh(x: 16, y: 16, width: 16, height: 16));
    List<Result> collisions =
        world.queryAABB(AABB.xywh(x: 32, y: 16, width: 16, height: 16));
    expect(collisions.length, 0);
  });

  test('remove', () {
    Object foo = Object();
    World world = World(1024, 1024);
    world.add(foo, AABB.xywh(x: 16, y: 16, width: 16, height: 16));
    world.remove(foo);
    List<Result> collisions =
        world.queryAABB(AABB.xywh(x: 16, y: 16, width: 16, height: 16));
    expect(collisions.length, 0);
  });

  test('update', () {
    Object foo = Object();
    World world = World(1024, 1024);
    world.add(foo, AABB.xywh(x: 16, y: 16, width: 16, height: 16));
    world.update(foo, AABB.xywh(x: 100, y: 16, width: 16, height: 16));
    AABB? result = world.queryObject(foo);
    expect(result, isNotNull);
    if (result != null) {
      expect(result.x, closeTo(100, 0.01));
      expect(result.y, closeTo(16, 0.01));
      expect(result.width, closeTo(16, 0.01));
      expect(result.height, closeTo(16, 0.01));
    }
  });

  test('simple slide right', () {
    Object block = Object();
    Object man = Object();
    World world = World(1024, 1024);
    world.add(block, AABB.xywh(x: 64, y: 16, width: 16, height: 16));
    world.add(man, AABB.xywh(x: 47, y: 16, width: 16, height: 16));
    MoveResult result = world.move(man, 2, 0);
    expect(result.x, closeTo(48.0, 0.01));
    expect(result.y, closeTo(16.0, 0.01));
    expect(result.collisions.length, 1);
    expect(result.collisions[0].object, block);
  });

  test('simple slide right tiny', () {
    Object block = Object();
    Object man = Object();
    World world = World(1024, 1024);
    world.add(block, AABB.xywh(x: 64, y: 16, width: 1, height: 1));
    world.add(man, AABB.xywh(x: 61.99, y: 16, width: 1, height: 1));
    MoveResult result = world.move(man, 2.99, 0);
    expect(result.x, closeTo(63.0, 0.01));
    expect(result.y, closeTo(16.0, 0.01));
    expect(result.collisions.length, 1);
    expect(result.collisions[0].object, block);
  });

  test('simple slide no collisions', () {
    Object foo = Object();
    World world = World(1024, 1024);
    world.add(foo, AABB.xywh(x: 16, y: 16, width: 16, height: 16));
    world.move(foo, 100, 0);
    AABB? result = world.queryObject(foo);
    expect(result, isNotNull);
    if (result != null) {
      expect(result.x, closeTo(116, 0.01));
      expect(result.y, closeTo(16, 0.01));
      expect(result.width, closeTo(16, 0.01));
      expect(result.height, closeTo(16, 0.01));
    }
  });

  test('simple slide down right', () {
    Object block = Object();
    Object man = Object();
    World world = World(1024, 1024);
    world.add(block, AABB.xywh(x: 48, y: 32, width: 16, height: 16));
    world.add(man, AABB.xywh(x: 48, y: 16, width: 16, height: 16));
    MoveResult result = world.move(man, 3, 4);
    expect(result.x, closeTo(51.0, 0.01));
    expect(result.y, closeTo(16.0, 0.01));
    expect(result.collisions.length, 1);
    expect(result.collisions[0].object, block);
  });

  test('simple slide down right fractional', () {
    Object block = Object();
    Object man = Object();
    World world = World(1024, 1024);
    world.add(block, AABB.xywh(x: 48, y: 32, width: 16, height: 16));
    world.add(man, AABB.xywh(x: 48, y: 16, width: 16, height: 16));
    MoveResult result = world.move(man, 3, 3);
    expect(result.x, closeTo(51, 0.01));
    expect(result.y, closeTo(16.0, 0.01));
    expect(result.collisions.length, 1);
    expect(result.collisions[0].object, block);
  });

  test('simple pass right', () {
    Object block = Object();
    Object man = Object();
    World world = World(1024, 1024);
    world.add(block, AABB.xywh(x: 64, y: 16, width: 16, height: 16));
    world.add(man, AABB.xywh(x: 47, y: 16, width: 16, height: 16));
    MoveResult result = world.move(man, 2, 0, handler: (obj) => Behavior.Pass);
    expect(result.x, closeTo(49.0, 0.01));
    expect(result.y, closeTo(16.0, 0.01));
    expect(result.collisions.length, 1);
    expect(result.collisions[0].object, block);
  });

  test('simple slide left', () {
    Object block = Object();
    Object man = Object();
    World world = World(1024, 1024);
    world.add(block, AABB.xywh(x: 64, y: 16, width: 16, height: 16));
    world.add(man, AABB.xywh(x: 81, y: 16, width: 16, height: 16));
    MoveResult result = world.move(man, -2, 0);
    expect(result.x, closeTo(80.0, 0.01));
    expect(result.y, closeTo(16.0, 0.01));
    expect(result.collisions.length, 1);
    expect(result.collisions[0].object, block);
  });

  test('simple slide up', () {
    Object block = Object();
    Object man = Object();
    World world = World(1024, 1024);
    world.add(block, AABB.xywh(x: 64, y: 16, width: 16, height: 16));
    world.add(man, AABB.xywh(x: 64, y: 33, width: 16, height: 16));
    MoveResult result = world.move(man, 0, -2);
    expect(result.x, closeTo(64.0, 0.01));
    expect(result.y, closeTo(32.0, 0.01));
    expect(result.collisions.length, 1);
    expect(result.collisions[0].object, block);
  });

  test('slide slip by', () {
    Object block = Object();
    Object man = Object();
    World world = World(1024, 1024);
    world.add(block, AABB.xywh(x: 16, y: 32, width: 16, height: 16));
    world.add(man, AABB.xywh(x: 0, y: 50, width: 16, height: 16));
    MoveResult result = world.move(man, 0, -50);
    expect(result.x, closeTo(0.0, 0.01));
    expect(result.y, closeTo(0.0, 0.01));
    expect(result.collisions.length, 0);
  });

  test('simple slide up', () {
    Object block = Object();
    Object man = Object();
    World world = World(1024, 1024);
    world.add(block, AABB.xywh(x: 64, y: 32, width: 16, height: 16));
    world.add(man, AABB.xywh(x: 64, y: 15, width: 16, height: 16));
    MoveResult result = world.move(man, 0, 2);
    expect(result.x, closeTo(64.0, 0.01));
    expect(result.y, closeTo(16.0, 0.01));
    expect(result.collisions.length, 1);
    expect(result.collisions[0].object, block);

    AABB? queryResult = world.queryObject(man);
    expect(queryResult, isNotNull);
    if (queryResult != null) {
      expect(queryResult.x, closeTo(64, 0.01));
      expect(queryResult.y, closeTo(16, 0.01));
      expect(queryResult.width, closeTo(16, 0.01));
      expect(queryResult.height, closeTo(16, 0.01));
    }
  });
}
