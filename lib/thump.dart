import 'dart:collection';
import 'dart:math';

class Vector2 {
  final double x;
  final double y;
  Vector2(this.x, this.y);
}

/// An axis-aligned bounding box.
class AABB {
  /// The lowest x value for this.
  final double x;

  /// The lowest y value for this.
  final double y;

  /// The width of this.
  final double width;

  /// The height of this.
  final double height;

  /// The highest x value for this.
  double get right => x + width;

  /// The highest y value for this.
  double get bottom => y + height;

  /// The x value for the center of this.
  double get centerX => x + width / 2.0;

  /// The y value for the center of this.
  double get centerY => y + height / 2.0;

  /// The top-left quadrant of an [AABB].
  AABB get topLeft =>
      AABB.xywh(x: x, y: x, width: width / 2, height: height / 2);

  /// The top-right quadrant of an [AABB].
  AABB get topRight =>
      AABB.xywh(x: centerX, y: x, width: width / 2, height: height / 2);

  /// The bottom-left quadrant of an [AABB].
  AABB get bottomLeft =>
      AABB.xywh(x: x, y: centerY, width: width / 2, height: height / 2);

  /// The bottom-right quadrant of an [AABB].
  AABB get bottomRight =>
      AABB.xywh(x: centerX, y: centerY, width: width / 2, height: height / 2);

  AABB.xywh(
      {required double this.x,
      required double this.y,
      required double this.width,
      required double this.height});

  /// Returns `true` if this and [other] are overlapping (not just touching).
  bool overlaps(AABB other) {
    if (other.right <= x) {
      return false;
    }
    if (other.x >= right) {
      return false;
    }
    if (other.y >= bottom) {
      return false;
    }
    if (other.bottom <= y) {
      return false;
    }
    return true;
  }

  /// Returns the smallest AABB that contains both this and [aabb].
  AABB union(AABB aabb) {
    double curTop = y;
    double curBottom = bottom;
    double curLeft = x;
    double curRight = right;

    if (aabb.y < curTop) {
      curTop = aabb.y;
    }
    if (aabb.bottom > curBottom) {
      curBottom = aabb.bottom;
    }
    if (aabb.x < curLeft) {
      curLeft = aabb.x;
    }
    if (aabb.right > curRight) {
      curRight = aabb.right;
    }
    return AABB.xywh(
        x: curLeft,
        y: curTop,
        width: curRight - curLeft,
        height: curBottom - curTop);
  }

  @override
  String toString() {
    return '(AABB x:$x y:$y width:$width height:$height)';
  }
}

/// A defined behavior to take when objects collide as a result of [World.move].
enum Behavior {
  Slide,
  Pass,
  Bounce,
  Touch,
}

class AABBPair {
  final Object object;
  final AABB aabb;
  AABBPair(this.object, this.aabb);
}

class Collision {
  /// The object that was collided with.
  final Object object;

  /// The [AABB] of the object that was collided with.
  final AABB aabb;

  /// The edge of the moving [AABB] that collided with [object].
  final Edge edge;

  /// The behavior executed at the collision.
  final Behavior behavior;

  /// The position of the object's top left hand corner at the point of impact.
  final Vector2 collisionPosition;

  Collision({
    required this.object,
    required this.aabb,
    required this.edge,
    required this.behavior,
    required this.collisionPosition,
  });
}

/// A result from [World.move].
class MoveResult {
  /// The resulting position of the moved object.
  final Vector2 position;

  /// The resulting normalized direction the object is traveling.
  final Vector2 direction;

  final List<Collision> collisions;

  MoveResult._make({
    required this.position,
    required this.collisions,
    required this.direction,
  });
}

class _Node {
  AABB _aabb;
  _Node? tl;
  _Node? tr;
  _Node? bl;
  _Node? br;
  _Node(this._aabb);
  Map<Object, AABB> _entries = {};
}

enum Edge { top, right, bottom, left }

Edge _calcClosestEdge(AABB a, AABB b, double dx, double dy) {
  Edge? result;
  double minDist = double.infinity;
  if (dx >= 0) {
    double dist = (a.right - b.x).abs();
    if (dist < minDist) {
      result = Edge.right;
      minDist = dist;
    }
  }
  if (dx <= 0) {
    double dist = (a.x - b.right).abs();
    if (dist < minDist) {
      result = Edge.left;
      minDist = dist;
    }
  }
  if (dy >= 0) {
    double dist = (a.bottom - b.y).abs();
    if (dist < minDist) {
      result = Edge.bottom;
      minDist = dist;
    }
  }
  if (dy <= 0) {
    double dist = (a.y - b.bottom).abs();
    if (dist < minDist) {
      result = Edge.top;
      minDist = dist;
    }
  }

  return result!;
}

void _add(_Node node, Object obj, AABB aabb) {
  if (aabb.right <= node._aabb.centerX) {
    if (aabb.bottom <= node._aabb.centerY) {
      if (node.tl == null) {
        node.tl = _Node(AABB.xywh(
            x: node._aabb.x,
            y: node._aabb.y,
            width: node._aabb.width / 2,
            height: node._aabb.height / 2));
      }
      _add(node.tl!, obj, aabb);
      return;
    }
  }
  if (aabb.x >= node._aabb.centerX) {
    if (aabb.bottom <= node._aabb.centerY) {
      if (node.tr == null) {
        node.tr = _Node(AABB.xywh(
            x: node._aabb.centerX,
            y: node._aabb.y,
            width: node._aabb.width / 2,
            height: node._aabb.height / 2));
      }
      _add(node.tr!, obj, aabb);
      return;
    }
  }
  if (aabb.right <= node._aabb.centerX) {
    if (aabb.y >= node._aabb.centerY) {
      if (node.bl == null) {
        node.bl = _Node(AABB.xywh(
            x: node._aabb.x,
            y: node._aabb.centerY,
            width: node._aabb.width / 2,
            height: node._aabb.height / 2));
      }
      _add(node.bl!, obj, aabb);
      return;
    }
  }
  if (aabb.x >= node._aabb.centerX) {
    if (aabb.y >= node._aabb.centerY) {
      if (node.br == null) {
        node.br = _Node(AABB.xywh(
            x: node._aabb.centerX,
            y: node._aabb.centerY,
            width: node._aabb.width / 2,
            height: node._aabb.height / 2));
      }
      _add(node.br!, obj, aabb);
      return;
    }
  }

  node._entries[obj] = aabb;
}

void _queryAABB(_Node node, List<AABBPair> results, AABB aabb, Object? ignore) {
  node._entries.forEach((obj, otherAABB) {
    if ((ignore != null && ignore != obj) || ignore == null) {
      if (aabb.overlaps(otherAABB)) {
        results.add(AABBPair(obj, otherAABB));
      }
    }
  });
  if (node.tl != null && node.tl!._aabb.overlaps(aabb)) {
    _queryAABB(node.tl!, results, aabb, ignore);
  }
  if (node.tr != null && node.tr!._aabb.overlaps(aabb)) {
    _queryAABB(node.tr!, results, aabb, ignore);
  }
  if (node.bl != null && node.bl!._aabb.overlaps(aabb)) {
    _queryAABB(node.bl!, results, aabb, ignore);
  }
  if (node.br != null && node.br!._aabb.overlaps(aabb)) {
    _queryAABB(node.br!, results, aabb, ignore);
  }
}

bool _remove(_Node node, Object obj, {AABB? hint}) {
  bool found = false;
  node._entries.removeWhere((Object entry, AABB aabb) {
    if (obj == entry) {
      found = true;
      return true;
    }
    return false;
  });
  if (found) {
    return true;
  }
  if (node.tl != null && (hint == null || hint.overlaps(node._aabb.topLeft))) {
    if (_remove(node.tl!, obj)) {
      return true;
    }
  }
  if (node.tr != null && (hint == null || hint.overlaps(node._aabb.topRight))) {
    if (_remove(node.tr!, obj)) {
      return true;
    }
  }
  if (node.bl != null &&
      (hint == null || hint.overlaps(node._aabb.bottomLeft))) {
    if (_remove(node.bl!, obj)) {
      return true;
    }
  }
  if (node.br != null &&
      (hint == null || hint.overlaps(node._aabb.bottomRight))) {
    if (_remove(node.br!, obj)) {
      return true;
    }
  }
  return false;
}

Behavior _defaultBehavior(Object obj) => Behavior.Slide;

double _length(double dx, double dy) => sqrt(dx * dx + dy * dy);

/// An object thant holds all the information for the collision system.
class World {
  final double width;
  final double height;
  final _Node _node;
  final HashMap<Object, AABB> _aabbs = new HashMap<Object, AABB>();

  /// Creates a [World] with the given [width] and [height] dimensions.
  /// Objects can exist out of those dimensions inefficiently.
  World(this.width, this.height)
      : _node = _Node(AABB.xywh(x: 0, y: 0, width: width, height: height));

  /// Add a new [Object] to the [World] at the position specified by the [AABB].
  void add(Object obj, AABB aabb) {
    _aabbs[obj] = aabb;
    _add(_node, obj, aabb);
  }

  /// Removes an [Object] from the [World] that was previously added with [add].
  void remove(Object obj) {
    _aabbs.remove(obj);
    _remove(_node, obj);
  }

  /// Looks up the current [AABB] for the specified [Object].  Returns `null` if
  /// it can't be found.
  AABB? queryObject(Object obj) {
    return _aabbs[obj];
  }

  /// Returns a list of all the objects that intersect with [aabb]. The optional
  /// argument [ignore] specifies an object that will be excluded from results.
  List<AABBPair> queryAABB(AABB aabb, {Object? ignore}) {
    List<AABBPair> results = [];
    _queryAABB(_node, results, aabb, ignore);
    return results;
  }

  /// Resets the [AABB] associated with an [obj] that has previously been added
  /// to the [World] with [add].
  void update(Object obj, AABB aabb) {
    AABB oldAABB = _aabbs[obj]!;
    _remove(_node, obj, hint: oldAABB);
    _add(_node, obj, aabb);
    _aabbs[obj] = aabb;
  }

  /// Moves [obj] by delta values [dx] in the x direction and [dy] in the y
  /// direction.  Optional value [handler] can be specified to have custom
  /// [Behavior]s set for a given collision.  If none is specified
  /// [Behavior.Slide] is assumed.
  MoveResult move(Object obj, double dx, double dy,
      {Behavior Function(Object other) handler = _defaultBehavior}) {
    final AABB start = _aabbs[obj]!;
    double resultX = start.x;
    double resultY = start.y;
    Set<Object> collisionObjects = {};
    List<Collision> collisions = [];
    final AABB end = AABB.xywh(
        x: start.x + dx,
        y: start.y + dy,
        width: start.width,
        height: start.height);
    final AABB union = start.union(end);
    final List<AABBPair> potentials = queryAABB(union, ignore: obj);
    final length = _length(dx, dy);
    final double origDirX = length > 0 ? dx / length : 0;
    final double origDirY = length > 0 ? dy / length : 0;
    if (potentials.isEmpty) {
      resultX = start.x + dx;
      resultY = start.y + dy;
      update(
          obj,
          AABB.xywh(
              x: resultX,
              y: resultY,
              width: start.width,
              height: start.height));
      return MoveResult._make(
          position: Vector2(resultX, resultY),
          collisions: [],
          direction: Vector2(origDirX, origDirY));
    }
    final int steps = length.ceil();
    double normDx = dx / steps;
    double normDy = dy / steps;
    bool shouldBreak = false;
    for (int i = 0; i < steps; ++i) {
      double nextX = resultX + normDx;
      double nextY = resultY + normDy;
      final AABB nextAABB = AABB.xywh(
          x: nextX, y: nextY, width: start.width, height: start.height);
      for (AABBPair potential in potentials) {
        if (nextAABB.overlaps(potential.aabb)) {
          final Edge closest = _calcClosestEdge(
              AABB.xywh(
                  x: resultX,
                  y: resultY,
                  width: start.width,
                  height: start.height),
              potential.aabb,
              dx,
              dy);
          Behavior behavior = handler(potential.object);
          late final Vector2 collisionPosition;
          switch (closest) {
            case Edge.top:
              final double y = max(nextY, potential.aabb.bottom);
              double moveRatio = (y - resultY) / normDy;
              final double x = resultX + normDx * moveRatio;
              collisionPosition = Vector2(x, y);
            case Edge.right:
              final double x = min(nextX, potential.aabb.x - start.width);
              double moveRatio = (x - resultX) / normDx;
              final double y = resultY + normDy * moveRatio;
              collisionPosition = Vector2(x, y);
            case Edge.bottom:
              final double y = min(nextY, potential.aabb.y - start.height);
              double moveRatio = (y - resultY) / normDy;
              final double x = resultX + normDx * moveRatio;
              collisionPosition = Vector2(x, y);
            case Edge.left:
              final double x = max(nextX, potential.aabb.right);
              double moveRatio = (x - resultX) / normDx;
              final double y = resultY + normDy * moveRatio;
              collisionPosition = Vector2(x, y);
          }

          if (!collisionObjects.contains(potential.object)) {
            collisions.add(Collision(
                object: potential.object,
                aabb: potential.aabb,
                edge: closest,
                behavior: behavior,
                collisionPosition: collisionPosition));
            collisionObjects.add(potential.object);
          }
          switch (behavior) {
            case Behavior.Touch:
              shouldBreak = true;
              nextY = collisionPosition.y;
              nextX = collisionPosition.x;
              break;
            case Behavior.Slide:
              switch (closest) {
                case Edge.top:
                  nextY = max(nextY, potential.aabb.bottom);
                case Edge.right:
                  nextX = min(nextX, potential.aabb.x - start.width);
                case Edge.bottom:
                  nextY = min(nextY, potential.aabb.y - start.height);
                case Edge.left:
                  nextX = max(nextX, potential.aabb.right);
              }
              break;
            case Behavior.Pass:
              break;
            case Behavior.Bounce:
              switch (closest) {
                case Edge.top:
                  final double impactY = max(nextY, potential.aabb.bottom);
                  final double moveRatio = (impactY - resultY) / normDy;
                  nextY = resultY +
                      normDy * moveRatio +
                      (-normDy * (1 - moveRatio));
                  normDy *= -1;
                case Edge.right:
                  final double impactX =
                      min(nextX, potential.aabb.x - start.width);
                  final double moveRatio = (impactX - resultX) / normDx;
                  nextX = resultX +
                      normDx * moveRatio +
                      (-normDx * (1 - moveRatio));
                  normDx *= -1;
                case Edge.bottom:
                  final double impactY =
                      min(nextY, potential.aabb.y - start.height);
                  final double moveRatio = (impactY - resultY) / normDy;
                  nextY = resultY +
                      normDy * moveRatio +
                      (-normDy * (1 - moveRatio));
                  normDy *= -1;
                case Edge.left:
                  final double impactX = max(nextX, potential.aabb.right);
                  final double moveRatio = (impactX - resultX) / normDx;
                  nextX = resultX +
                      normDx * moveRatio +
                      (-normDx * (1 - moveRatio));
                  normDx *= -1;
              }
              break;
          }
        }
      }
      resultX = nextX;
      resultY = nextY;
      if (shouldBreak) break;
    }

    update(
        obj,
        AABB.xywh(
            x: resultX, y: resultY, width: start.width, height: start.height));

    return MoveResult._make(
      position: Vector2(resultX, resultY),
      collisions: collisions,
      direction: Vector2((normDx < 0 != dx < 0) ? -origDirX : origDirX,
          (normDy < 0 != dy < 0) ? -origDirY : origDirY),
    );
  }
}
