#pragma arguments

float trueAnomaly;
float transparentStart;
float transparentEnd;

#pragma transparent
#pragma body

vec2 pos = (u_inverseModelViewTransform * vec4(_surface.position, 1.0)).xy;
float angle = fmod(atan2(pos.y, pos.x) - Double.pi_F - trueAnomaly, Double.pi_F * 2);
if (angle > Double.pi_F) {
    angle -= 2 * Double.pi_F;
} else if (angle < -Double.pi_F) {
    angle += 2 * Double.pi_F;
}
float percent = clamp((angle + Double.pi_F) / (2 * Double.pi_F), 0.0, 1.0);
if (percent < 0.3) {
    _surface.transparent = vec4(transparentStart);
} else {
    _surface.transparent = mix(vec4(transparentStart), vec4(transparentEnd), (percent - 0.3) / 0.7);
}
