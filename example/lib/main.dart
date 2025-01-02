import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:thump/thump.dart' as thump;

// How much energy is maintained when a bounce happens.
const double bounceCoefficient = 0.9;
// How much downward force is required to activate bouncing.  You don't want it
// to bounce while walking over it.
const double bounceActivation = 0.5;
thump.World gWorld = thump.World(5120, 288);

class Ninja extends RectangleComponent with KeyboardHandler {
  final Set<LogicalKeyboardKey> keysPressed = {};
  final Set<LogicalKeyboardKey> keysDown = {};
  final double speed = 128;
  double _dy = 0;
  bool _onPlatform = false;
  final _gravity = 9.0;
  final _jumpPower = 5.0;
  bool _isStuck = false;

  @override
  FutureOr<void> onLoad() {
    gWorld.add(this, thump.AABB.xywh(x: x, y: y, width: width, height: height));
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2,
        Paint()..color = Color.fromARGB(255, 178, 186, 247));
  }

  @override
  void update(double dt) {
    double dx = 0;
    double dy = _dy;

    if (!_isStuck) {
      _dy += _gravity * dt;
    } else {
      _onPlatform = true;
    }

    if (_isStuck && !keysPressed.contains(LogicalKeyboardKey.keyZ)) {
      _isStuck = false;
    }
    if (_onPlatform && keysDown.contains(LogicalKeyboardKey.arrowUp)) {
      _dy = -_jumpPower;
      _isStuck = false;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      dx = dt * speed;
      _isStuck = false;
    }
    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      dx = -dt * speed;
      _isStuck = false;
    }

    _onPlatform = false;
    thump.MoveResult result = gWorld.move(this, dx, dy, handler: (Object obj) {
      if (obj is Block && obj.bouncy && _dy >= bounceActivation) {
        return thump.Behavior.Bounce;
      }
      if (keysPressed.contains(LogicalKeyboardKey.keyZ)) {
        return thump.Behavior.Touch;
      } else {
        return thump.Behavior.Slide;
      }
    });
    if (result.collisions.isNotEmpty) {
      for (final collision in result.collisions) {
        if (keysPressed.contains(LogicalKeyboardKey.keyZ)) {
          _dy = 0;
          _onPlatform = true;
          _isStuck = true;
        }
        if (result.position.y >= collision.aabb.bottom && dy <= 0) {
          // Hit your head.
          _dy = 0;
        }
        if (result.position.y + height <= collision.aabb.y && dy >= 0) {
          // Hit your feet.
          if (collision.behavior == thump.Behavior.Bounce &&
              _dy >= bounceActivation) {
            _dy *= -bounceCoefficient;
          } else {
            _dy = 0;
            _onPlatform = true;
          }
        }
      }
    }
    position = Vector2(result.position.x, result.position.y);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    keysDown.clear();
    for (final key in keysPressed) {
      if (!this.keysPressed.contains(key)) {
        keysDown.add(key);
      }
    }
    this.keysPressed.clear();
    this.keysPressed.addAll(keysPressed);
    return false;
  }
}

class Block extends RectangleComponent {
  final bool bouncy;

  Block({this.bouncy = false});

  @override
  FutureOr<void> onLoad() {
    gWorld.add(this, thump.AABB.xywh(x: x, y: y, width: width, height: height));
  }

  @override
  void render(Canvas canvas) {
    final Color color = bouncy
        ? Color.fromARGB(255, 233, 97, 29)
        : Color.fromARGB(255, 0, 255, 8);
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), Paint()..color = color);
  }
}

class NinjaWorld extends World {
  @override
  Future<void> onLoad() async {
    void addBlock(double x, double y, {bool bouncy = false}) {
      final block = Block(bouncy: bouncy);
      block.position = Vector2(x, y);
      block.size = Vector2(16, 16);
      add(block);
    }

    for (int i = 0; i < 20; ++i) {
      addBlock(i * 16, 200);
    }

    addBlock(100, 100);
    addBlock(160, 184);
    addBlock(200, 184, bouncy: true);

    final ninja = Ninja();
    ninja.position = Vector2(0, 0);
    ninja.size = Vector2(32, 32);
    ninja.debugMode = true;
    add(ninja);
  }
}

class NinjaGame extends FlameGame with HasKeyboardHandlerComponents {
  NinjaGame()
      : super(
            camera:
                CameraComponent.withFixedResolution(width: 512, height: 288),
            world: NinjaWorld());

  @override
  Future<void> onLoad() async {
    camera.moveTo(Vector2(256, 144));
    camera.viewfinder.zoom = 1.0;
  }
}

void main() {
  final game = NinjaGame();
  runApp(GameWidget(game: game));
}
