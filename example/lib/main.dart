import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:thump/thump.dart' as thump;

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
    gWorld.add(
        this,
        thump.AABB.xywh(
            x: x, y: y, width: width, height: height));
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
        if (result.y >= collision.aabb.bottom && dy <= 0) {
          _dy = 0;
        }
        if (result.y + height <= collision.aabb.y && dy >= 0) {
          _dy = 0;
          _onPlatform = true;
        }
      }
    }
    position = Vector2(result.x, result.y);
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
  @override
  FutureOr<void> onLoad() {
    gWorld.add(
        this,
        thump.AABB.xywh(
            x: x, y: y, width: width, height: height));
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height),
        Paint()..color = Color.fromARGB(255, 0, 255, 8));
  }
}

class NinjaWorld extends World {
  @override
  Future<void> onLoad() async {
    void addBlock(double x, double y) {
      final block = Block();
      block.position = Vector2(x, y);
      block.size = Vector2(16, 16);
      add(block);
    }

    for (int i = 0; i < 20; ++i) {
      addBlock(i * 16, 200);
    }

    addBlock(100, 100);
    addBlock(160, 184);

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
