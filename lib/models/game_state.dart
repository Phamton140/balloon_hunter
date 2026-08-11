// lib/models/game_state.dart
// Estados posibles del juego

/// Representa el estado actual del ciclo de vida del juego
enum GameState {
  /// Mostrando el menú principal
  mainMenu,

  /// Pantalla de registro de usuario
  registration,

  /// Partida en curso
  playing,

  /// Partida pausada
  paused,

  /// Game Over (3 globos escapados o disparo a un ave)
  gameOver,

  /// Nivel completado con éxito (pantalla de estrellas)
  victory,

  /// Mostrando la pantalla de ranking
  ranking,

  /// Mostrando los ajustes
  settings,

  /// Cuenta regresiva antes de empezar a jugar
  countdown,

  /// Esperando a que el jugador pulse Continuar tras revivir
  reviveReady,

  /// Mostrando la galería de desbloqueos
  collection,
}
