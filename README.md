# 🎈 Balloon Hunter

**Balloon Hunter** es un divertido y frenético juego arcade casual desarrollado con **Flutter** y **Flame Engine**. Pon a prueba tus reflejos reventando la mayor cantidad de globos posible antes de que se acabe el tiempo, ¡pero ten cuidado con las aves!

## 🎮 Jugabilidad
- **El Objetivo:** Revienta globos tocándolos para ganar puntos. Tienes 60 segundos por nivel.
- **Peligros:** 🐦 ¡NO toques a las aves! Si lo haces, será Game Over inmediato. Tampoco dejes escapar más de 3 globos hacia el cielo.
- **Globos Especiales:**
  - 🧊 **Globo Azul:** Activa un efecto de "Cámara Lenta" (Slow Motion) congelando temporalmente la pantalla.
  - 💣 **Globo Negro:** Crea una explosión en cadena que destruye todos los globos normales en pantalla, dándote puntos extra.
- **Progresión:** La dificultad aumenta exponencialmente con cada nivel que superes, haciendo que los globos suban más rápido y aparezcan con mayor frecuencia.

## ✨ Características
- Motor de físicas y colisiones basado en **Flame**.
- Interfaz nativa y overlays integrados con **Flutter**.
- **Sistema de Guardado Persistente** usando `Hive`. El juego guarda tu nivel de manera automática para que puedas continuar de donde lo dejaste aunque cierres la aplicación.
- **Récords Locales (Top 3)** para competir por la puntuación más alta.
- **Transición automática** entre niveles con un diseño moderno.
- Efectos de sonido y vibración háptica inmersiva.

## 🚀 Instalación y Ejecución

Asegúrate de tener instalado el SDK de Flutter (versión 3.0.0 o superior).

```bash
# Clonar el repositorio
git clone https://github.com/Phamton140/balloon_hunter.git

# Entrar al directorio
cd balloon_hunter

# Instalar dependencias
flutter pub get

# Ejecutar el juego
flutter run
```

## 🛠️ Tecnologías Usadas
- [Flutter](https://flutter.dev/) - Framework UI
- [Flame](https://flame-engine.org/) - Game Engine
- [Hive](https://pub.dev/packages/hive) - Base de datos local ultrarrápida
- [Flame Audio](https://pub.dev/packages/flame_audio) - Efectos de sonido
- [Flutter Animate](https://pub.dev/packages/flutter_animate) - Animaciones de la interfaz

---
*Desarrollado con mucha dedicación para horas de diversión.*
