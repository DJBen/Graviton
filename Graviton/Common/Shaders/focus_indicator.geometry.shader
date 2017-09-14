uniform float radius;

#pragma arguments

double radius;

#pragma transparent
#pragma body

float angle = u_time / 5.0;
float4x4 rot = float4x4(1.0);
rot[0][0] = cos(angle);
rot[0][1] = sin(angle);
rot[1][0] = -sin(angle);
rot[1][1] = cos(angle);
float currentRadius = radius * (0.2 * sin(u_time * 4.0) + 1.0);
_geometry.position += vec4(currentRadius, 0.0, 0.0, 0.0);
_geometry.position = rot * _geometry.position;
