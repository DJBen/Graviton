uniform float horizontalOffset;
uniform float verticalOffset;

#pragma arguments

float horizontalOffset;
float verticalOffset;

#pragma body

_geometry.position += vec4(horizontalOffset, verticalOffset, 0.0, 0.0);
