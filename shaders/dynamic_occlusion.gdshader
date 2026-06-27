shader_type canvas_item;

// Shader de occlusión dinámica: desvanece los píxeles que caen dentro de un
// círculo alrededor de uno o varios actores (jugador / grupo). Cuanto más cerca
// del actor, más transparente; recupera opacidad de forma suave hacia el borde
// del radio. Pensado para aplicarse a paredes/estructuras (incluidos
// TileMapLayer completos), de modo que el efecto sea un CÍRCULO real por píxel
// y no el desvanecimiento de la capa entera.

const int MAX_ACTORS = 16;

// Posiciones de los actores en espacio global (mundo).
uniform vec2 actor_positions[MAX_ACTORS];
// Cantidad de posiciones válidas en el arreglo.
uniform int actor_count = 0;
// Radio del círculo de detección, en píxeles de mundo.
uniform float detection_radius = 96.0;
// Alpha mínimo (más transparente) en el centro del círculo.
uniform float min_alpha : hint_range(0.0, 1.0) = 0.25;

varying vec2 world_pos;

void vertex() {
	// Posición del vértice en coordenadas globales (mundo).
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	if (actor_count > 0 && detection_radius > 0.0) {
		// Distancia al actor más cercano.
		float closest = 1e20;
		for (int i = 0; i < MAX_ACTORS; i++) {
			if (i >= actor_count) {
				break;
			}
			closest = min(closest, distance(world_pos, actor_positions[i]));
		}
		// min_alpha en el centro -> 1.0 en el borde, con transición suave.
		float t = smoothstep(0.0, detection_radius, closest);
		COLOR.a *= mix(min_alpha, 1.0, t);
	}
}
