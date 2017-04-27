#pragma arguments

float radius;

uniform float radius;

#pragma transparent
#pragma body

float currentRadius = radius * (0.15 * sin(u_time * 3) + 1.0);
float4x4 rot = float4x4(1.0);
float angle = u_time / 5;
rot[0][0] = cos(angle);
rot[0][1] = sin(angle);
rot[1][0] = -sin(angle);
rot[1][1] = cos(angle);
_geometry.position += vec4(currentRadius, 0.0, 0.0, 0.0);
_geometry.position = rot * _geometry.position;
