#pragma transparent
#pragma body

vec2 pos = _surface.position.xy;
_surface.transparent = mix(vec4(1.0), vec4(0.0), clamp(length(pos) / 12.0, 0.0, 1.0));
