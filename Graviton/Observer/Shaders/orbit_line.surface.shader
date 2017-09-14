uniform float trueAnomaly;
uniform float transparentStart;
uniform float transparentEnd;

#pragma arguments

float trueAnomaly;
float transparentStart;
float transparentEnd;

#pragma transparent
#pragma body

vec2 pos = (u_inverseModelViewTransform * vec4(_surface.position, 1.0)).xy;
float angle = fmod(atan2(pos.y, pos.x) - M_PI_F - trueAnomaly, M_PI_F * 2);
if (angle > M_PI_F) {
    angle -= 2 * M_PI_F;
} else if (angle < -M_PI_F) {
    angle += 2 * M_PI_F;
}
float percent = clamp((angle + M_PI_F) / (2 * M_PI_F), 0.0, 1.0);
if (percent < 0.3) {
    _surface.transparent = vec4(transparentStart);
} else {
    _surface.transparent = mix(vec4(transparentStart), vec4(transparentEnd), (percent - 0.3) / 0.7);
}
