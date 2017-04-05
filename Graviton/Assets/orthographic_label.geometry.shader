uniform float horizontalOffset;
uniform float verticalOffset;

#pragma arguments

float horizontalOffset;
float verticalOffset;

#pragma transparent
#pragma body

vec4 projected = u_modelViewTransform * _geometry.position;
projected += vec4(horizontalOffset, verticalOffset, 0.0, 0.0);
_geometry.position = u_inverseModelViewTransform * projected;
