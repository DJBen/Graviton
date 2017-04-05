#pragma transparent
#pragma body

vec2 pos = _surface.position.xy;
_surface.diffuse[3] = mix(1.0, 0.0, clamp(length(pos) / 12.0, 0.0, 1.0));
