import 'dart:collection';
import 'dart:math';

class AABB {
  final double x;
  final double y;
  final double width;
  final double height;

  double get right => x + width;
  double get bottom => y + height;
  double get centerX => x + width / 2.0;
  double get centerY => y + height / 2.0;

  AABB get topLeft =>
      AABB.xywh(x: x, y: x, width: width / 2, height: height / 2);
  AABB get topRight =>
      AABB.xywh(x: centerX, y: x, width: width / 2, height: height / 2);
  AABB get bottomLeft =>
      AABB.xywh(x: x, y: centerY, width: width / 2, height: height / 2);
  AABB get bottomRight =>
      AABB.xywh(x: centerX, y: centerY, width: width / 2, height: height / 2);

  AABB.xywh(
      {required double this.x,
      required double this.y,
      required double this.width,
      required double this.height});

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

enum Behavior {
  Slide,
  Pass,
  Bounce,
  Touch,
}

class Result {
  final Object object;
  final AABB aabb;
  Result(this.object, this.aabb);
}

class MoveResult {
  final double x;
  final double y;
  final List<Result> collisions;
  MoveResult(this.x, this.y, this.collisions);
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

enum _Edge { top, right, bottom, left }

_Edge _calcClosestEdge(AABB a, AABB b, double dx, double dy) {
  _Edge? result;
  double minDist = double.infinity;
  if (dx >= 0) {
    double dist = (a.right - b.x).abs();
    if (dist < minDist) {
      result = _Edge.right;
      minDist = dist;
    }
  }
  if (dx <= 0) {
    double dist = (a.x - b.right).abs();
    if (dist < minDist) {
      result = _Edge.left;
      minDist = dist;
    }
  }
  if (dy >= 0) {
    double dist = (a.bottom - b.y).abs();
    if (dist < minDist) {
      result = _Edge.bottom;
      minDist = dist;
    }
  }
  if (dy <= 0) {
    double dist = (a.y - b.bottom).abs();
    if (dist < minDist) {
      result = _Edge.top;
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

void _queryAABB(_Node node, List<Result> results, AABB aabb, Object? ignore) {
  node._entries.forEach((obj, otherAABB) {
    if ((ignore != null && ignore != obj) || ignore == null) {
      if (aabb.overlaps(otherAABB)) {
        results.add(Result(obj, otherAABB));
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

class World {
  final double width;
  final double height;
  final _Node _node;
  final HashMap<Object, AABB> _aabbs = new HashMap<Object, AABB>();

  World(this.width, this.height)
      : _node = _Node(AABB.xywh(x: 0, y: 0, width: width, height: height));

  void add(Object obj, AABB aabb) {
    _aabbs[obj] = aabb;
    _add(_node, obj, aabb);
  }

  void remove(Object obj) {
    _aabbs.remove(obj);
    _remove(_node, obj);
  }

  AABB? queryObject(Object obj) {
    return _aabbs[obj];
  }

  /// Returns a list of all the objects that intersect with [aabb].
  List<Result> queryAABB(AABB aabb, {Object? ignore}) {
    List<Result> results = [];
    _queryAABB(_node, results, aabb, ignore);
    return results;
  }

  void update(Object obj, AABB aabb) {
    AABB oldAABB = _aabbs[obj]!;
    _remove(_node, obj, hint: oldAABB);
    _add(_node, obj, aabb);
    _aabbs[obj] = aabb;
  }

  MoveResult move(Object obj, double dx, double dy,
      {Behavior Function(Object other) handler = _defaultBehavior}) {
    final AABB start = _aabbs[obj]!;
    double resultX = start.x;
    double resultY = start.y;
    Set<Object> collisions = {};
    final AABB end = AABB.xywh(
        x: start.x + dx,
        y: start.y + dy,
        width: start.width,
        height: start.height);
    final AABB union = start.union(end);
    final List<Result> potentials = queryAABB(union, ignore: obj);
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
      return MoveResult(resultX, resultY, []);
    }
    final int steps = _length(dx, dy).ceil();
    final double normDx = dx / steps;
    final double normDy = dy / steps;
    bool shouldBreak = false;
    for (int i = 0; i < steps; ++i) {
      double nextX = resultX + normDx;
      double nextY = resultY + normDy;
      final AABB nextAABB = AABB.xywh(
          x: nextX, y: nextY, width: start.width, height: start.height);
      for (Result potential in potentials) {
        if (nextAABB.overlaps(potential.aabb)) {
          collisions.add(potential.object);
          Behavior behavior = handler(potential.object);
          switch (behavior) {
            case Behavior.Touch:
              shouldBreak = true;
              final _Edge closest = _calcClosestEdge(
                  AABB.xywh(
                      x: resultX,
                      y: resultY,
                      width: start.width,
                      height: start.height),
                  potential.aabb,
                  dx,
                  dy);
              switch (closest) {
                case _Edge.top:
                  nextY = max(nextY, potential.aabb.bottom);
                  double moveRatio = (nextY - start.y) / normDy;
                  nextX = resultX + normDx * moveRatio;
                case _Edge.right:
                  nextX = min(nextX, potential.aabb.x - start.width);
                  double moveRatio = (nextX - start.x) / normDx;
                  nextY = resultY + normDy * moveRatio;
                case _Edge.bottom:
                  nextY = min(nextY, potential.aabb.y - start.height);
                  double moveRatio = (nextY - start.y) / normDy;
                  nextX = resultX + normDx * moveRatio;
                case _Edge.left:
                  nextX = max(nextX, potential.aabb.right);
                  double moveRatio = (nextX - start.x) / normDx;
                  nextY = resultY + normDy * moveRatio;
              }
              break;
            case Behavior.Slide:
              final _Edge closest = _calcClosestEdge(
                  AABB.xywh(
                      x: resultX,
                      y: resultY,
                      width: start.width,
                      height: start.height),
                  potential.aabb,
                  dx,
                  dy);
              switch (closest) {
                case _Edge.top:
                  nextY = max(nextY, potential.aabb.bottom);
                case _Edge.right:
                  nextX = min(nextX, potential.aabb.x - start.width);
                case _Edge.bottom:
                  nextY = min(nextY, potential.aabb.y - start.height);
                case _Edge.left:
                  nextX = max(nextX, potential.aabb.right);
              }
              break;
            case Behavior.Pass:
              break;
            case Behavior.Bounce:
              throw UnimplementedError('Bounce is not implemented.');
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

    return MoveResult(resultX, resultY,
        collisions.map((Object obj) => Result(obj, _aabbs[obj]!)).toList());
  }
}
