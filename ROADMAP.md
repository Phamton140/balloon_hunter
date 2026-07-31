# Roadmap de Desarrollo: Mejoras y Nuevas Características

He analizado todas las solicitudes de los usuarios y tus ideas de expansión. Para garantizar que el juego se mantenga estable y que el desarrollo sea eficiente, he organizado estas tareas desde las **más críticas (bugs que rompen la experiencia actual)** hasta las **más complejas (requieren infraestructura de servidores en la nube)**.

---

## Fase 1: Correcciones Críticas y Balanceo (Prioridad Inmediata)
*Estas tareas solucionan problemas actuales que frustran al jugador y causan que abandonen el juego injustamente.*

1. **Continuidad Post-Anuncio (Crítico):** 
   - **Problema:** El juego corre de fondo mientras el anuncio sigue activo.
   - **Solución:** Implementar un estado `paused_for_ad` y mostrar una pantalla/botón flotante de "Reanudar" que el jugador debe presionar tras cerrar el anuncio para continuar la partida.
2. **Movimiento del Ave (UX/Jugabilidad):**
   - **Problema:** Teletransportación/Saltos que hacen injusto esquivarlas.
   - **Solución:** Ajustar el algoritmo de movimiento errático (`_zigZagFreq`, `_zigZagAmp`) en `bird_component.dart` para que el vuelo sea suave, curvo y continuo, sin cambios bruscos de coordenadas (`x`, `y`).
3. **Visibilidad de Globos Especiales (UX):**
   - **Problema:** Pasan muy rápido y no se entiende que son bombas o hielo.
   - **Solución:** Reducir su velocidad base a la de un globo regular (o un poco menos), y quizás agregarles un pequeño icono distintivo interno (un copo de nieve o un símbolo de radiación/chispa) para que la silueta sea inconfundible.

---

## Fase 2: Expansión del Core Gameplay (Prioridad Media)
*Mejoras puramente visuales y de mecánicas que enriquecen el juego offline sin requerir servidores.*

4. **Nuevos Personajes / Globos (Gran Actualización de Contenido):**
   - **Globo Reloj:** Resta 5 segundos al tiempo.
   - **Globo Señuelo:** Casi idéntico a uno normal. Ignorarlo no penaliza, tocarlo no hace nada (o hace un sonido de "broma").
   - **Globo Blindado:** Requiere 3 toques. Se le caen "capas" (ej. armadura de metal -> madera -> normal). Penaliza si escapa.
   - **Globo Fantasma:** Alterna entre transparente (inmune) y color (vulnerable). Penaliza si escapa.
   - **Caja Misteriosa:** Otorga un buff aleatorio (tiempo, ralentizar, bomba, multiplicador).
5. **Fondos y Climas Dinámicos:**
   - **Implementación:** Crear un gestor de escenarios (`EnvironmentManager`) que cambie el `background.png` (Desierto, Nieve, Noche, Lluvia) y emita partículas sobre toda la pantalla (lluvia cayendo, nieve, estrellas fugaces) dependiendo del nivel o al azar.

---

## Fase 3: Infraestructura en la Nube y Social (Prioridad Alta - Mayor Complejidad)
*Requieren integración con Firebase (Auth, Firestore) y configuración de credenciales de Google/Meta.*

6. **Guardado en la Nube (Cloud Save):**
   - **Implementación:** Login silencioso con Google Play Games / Apple Game Center, y vinculación manual con Facebook. El progreso se guarda en Firebase Firestore para no perderlo al cambiar de teléfono.
7. **Ranking Avanzado:**
   - **Implementación:** Tablas de clasificación semanales mediante consultas a Firestore. Filtros por país y amigos (usando la API social de la plataforma).

---

## Fase 4: Multijugador (Prioridad Baja - Máxima Complejidad)
*Requiere arquitectura de juego en tiempo real (Sockets / Firebase Realtime Database).*

8. **Modo Competitivo 1v1 (Versus):**
   - **Implementación:** Matchmaking mediante códigos de sala o invitación de amigos. Ambos clientes se sincronizan para empezar al mismo tiempo. Se envían paquetes de datos ligeros cada segundo indicando el score y nivel del rival. Cuando alguien pierde, el servidor notifica al otro cliente para detener el tiempo y mostrar la pantalla de victoria.

---

## Preguntas Abiertas y Siguientes Pasos

> [!IMPORTANT]
> **Revisión del Plan**
> Te sugiero que comencemos inmediatamente con la **Fase 1**, ya que podemos programarla hoy mismo sin necesidad de configurar bases de datos externas y mejorará drásticamente las reseñas actuales de los usuarios.
> 
> ¿Estás de acuerdo con este orden? Si me das luz verde, empezaré corrigiendo el botón post-anuncio y suavizando el vuelo de las aves.
