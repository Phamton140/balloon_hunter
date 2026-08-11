// lib/managers/spawn_manager.dart
// Gestor de spawn con Object Pooling para globos, aves y partículas

import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';
import '../components/balloon_component.dart';
import '../components/special_balloon_component.dart';
import '../components/bird_component.dart';
import '../components/explosion_component.dart';
import '../components/armored_balloon_component.dart';
import '../models/balloon_type.dart';
import '../utils/constants.dart';

/// Pool genérico reutilizable para componentes de Flame.
/// Evita la creación/destrucción continua de objetos mejorando el rendimiento.
class ObjectPool<T extends PositionComponent> {
  final List<T> _available = [];
  final T Function() _factory;

  ObjectPool({required T Function() factory, int initialSize = 0})
      : _factory = factory {
    for (int i = 0; i < initialSize; i++) {
      _available.add(_factory());
    }
  }

  /// Obtiene un componente del pool (o crea uno nuevo si está vacío)
  T acquire() {
    if (_available.isEmpty) {
      return _factory();
    }
    return _available.removeLast();
  }

  /// Devuelve un componente al pool para reutilización
  void release(T component) {
    // No llamamos a removeFromParent() para evitar problemas de concurrencia en Flame.
    // El componente se queda en el árbol pero con _active = false.
    _available.add(component);
  }

  /// Número de componentes disponibles en el pool
  int get availableCount => _available.length;
}

/// Gestiona la creación y reciclado de todos los componentes del juego.
/// Trabaja junto con EnemyDirector (que decide qué spawnear).
class SpawnManager {
  final Random _random = Random();

  // Pools de objetos
  late final ObjectPool<BalloonComponent> _balloonPool;
  late final ObjectPool<ArmoredBalloonComponent> _armoredPool;
  late final ObjectPool<BirdComponent> _birdPool;
  late final ObjectPool<ExplosionComponent> _explosionPool;

  // Referencia a la función para añadir componentes al juego
  late final void Function(Component) _addToGame;
  late final double Function() _getScreenWidth;
  late final double Function() _getScreenHeight;

  bool _initialized = false;

  /// Inicializa los pools con los tamaños predefinidos.
  /// [addToGame] es la función para añadir componentes (game.add)
  void initialize({
    required void Function(Component) addToGame,
    required double Function() getScreenWidth,
    required double Function() getScreenHeight,
  }) {
    _addToGame = addToGame;
    _getScreenWidth = getScreenWidth;
    _getScreenHeight = getScreenHeight;

    _balloonPool = ObjectPool<BalloonComponent>(
      factory: () => BalloonComponent(),
      initialSize: GameConstants.poolSizeBalloons,
    );
    _armoredPool = ObjectPool<ArmoredBalloonComponent>(
      factory: () => ArmoredBalloonComponent(),
      initialSize: 5, // No need for a large pool, they are rare
    );
    _birdPool = ObjectPool<BirdComponent>(
      factory: () => BirdComponent(),
      initialSize: GameConstants.poolSizeBirds,
    );
    _explosionPool = ObjectPool<ExplosionComponent>(
      factory: () => ExplosionComponent(),
      initialSize: GameConstants.poolSizeExplosions,
    );

    _initialized = true;
    debugPrint('[SpawnManager] Initialized with pools');
  }

  /// Spawnea un globo normal del tipo indicado
  BalloonComponent spawnBalloon(BalloonType type) {
    assert(_initialized);
    final balloon = _balloonPool.acquire();
    final x = _random.nextDouble() *
        (_getScreenWidth() - GameConstants.balloonWidth);
    final y = _getScreenHeight() + GameConstants.balloonHeight;
    balloon.configure(type: type, x: x, y: y, pool: _balloonPool);
    if (balloon.parent == null) {
      _addToGame(balloon);
    }
    return balloon;
  }

  /// Spawnea un globo blindado
  ArmoredBalloonComponent spawnArmoredBalloon() {
    assert(_initialized);
    final balloon = _armoredPool.acquire();
    final x = _random.nextDouble() *
        (_getScreenWidth() - GameConstants.balloonWidth);
    final y = _getScreenHeight() + GameConstants.balloonHeight;
    balloon.configure(x: x, y: y, pool: _armoredPool);
    if (balloon.parent == null) {
      _addToGame(balloon);
    }
    return balloon;
  }

  /// Spawnea un globo especial (azul o negro)
  SpecialBalloonComponent spawnSpecialBalloon(BalloonType type) {
    assert(_initialized);
    assert(type.isSpecial);
    final balloon = SpecialBalloonComponent();
    final x = _random.nextDouble() *
        (_getScreenWidth() - GameConstants.balloonWidth) +
        GameConstants.balloonWidth / 2;
    final y = _getScreenHeight() + GameConstants.balloonHeight;
    balloon.configure(type: type, x: x, y: y);
    _addToGame(balloon);
    return balloon;
  }

  /// Spawnea un ave en una posición aleatoria en el borde de la pantalla
  BirdComponent spawnBird() {
    assert(_initialized);
    final bird = _birdPool.acquire();
    final fromLeft = _random.nextBool();
    final x = _random.nextDouble() * (_getScreenWidth() - GameConstants.birdWidth);
    final y = _getScreenHeight() + GameConstants.birdHeight;
    // fromLeft will now just determine horizontal zig-zag direction
    bird.configure(x: x, y: y, fromLeft: fromLeft, pool: _birdPool);
    if (bird.parent == null) {
      _addToGame(bird);
    }
    return bird;
  }

  /// Spawnea una explosión de partículas en la posición indicada
  ExplosionComponent spawnExplosion(Vector2 position, {required BalloonType type}) {
    assert(_initialized);
    final explosion = _explosionPool.acquire();
    explosion.configure(position: position, type: type, pool: _explosionPool);
    if (explosion.parent == null) {
      _addToGame(explosion);
    }
    return explosion;
  }

  /// Elimina todos los globos normales activos (para globo negro)
  /// Retorna la lista de globos eliminados con su tipo
  List<BalloonComponent> removeAllNormalBalloons(List<Component> gameChildren) {
    final balloons = gameChildren
        .whereType<BalloonComponent>()
        .where((b) => !b.balloonType.isSpecial && b.isActive)
        .toList();
    for (final b in balloons) {
      spawnExplosion(b.position.clone(), type: b.balloonType);
      b.explodeAndReturn();
    }
    return balloons;
  }

  /// Elimina todas las aves activas (para globo negro)
  void removeAllBirds(List<Component> gameChildren) {
    final birds = gameChildren
        .whereType<BirdComponent>()
        .where((b) => b.isActive)
        .toList();
    for (final b in birds) {
      spawnExplosion(b.position.clone(), type: BalloonType.red); // Efecto rojo para el ave
      b.disappear();
    }
  }

  void reset() {
    debugPrint('[SpawnManager] Pool stats - Balloons: ${_balloonPool.availableCount}, Birds: ${_birdPool.availableCount}');
  }
}
