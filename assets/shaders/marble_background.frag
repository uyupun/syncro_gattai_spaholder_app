#include <flutter/runtime_effect.glsl>

uniform float uTime;
uniform float uWidth;
uniform float uHeight;

out vec4 fragColor;

// ─── Value noise ──────────────────────────────────────────────────────────────
float hash(vec2 p) {
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p + 19.19);
    return fract(p.x * p.y);
}

float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    // Quintic smoothstep で滑らかに補間
    vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);

    float a = hash(i + vec2(0.0, 0.0));
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// ─── fBm (fractal Brownian motion) ────────────────────────────────────────────
float fbm(vec2 p) {
    float v   = 0.0;
    float amp = 0.5;
    mat2  rot = mat2(
        cos(0.5),  sin(0.5),
       -sin(0.5),  cos(0.5)
    );
    for (int i = 0; i < 6; i++) {
        v   += amp * valueNoise(p);
        p    = rot * p * 2.1 + vec2(100.0, 100.0);
        amp *= 0.5;
    }
    return v;
}

// ─── マーブル模様のメイン ──────────────────────────────────────────────────────
void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv = fragCoord / vec2(uWidth, uHeight);

    // ゆっくりと時間で流れる（切れ目なく無限に続く）
    float t = uTime * 0.04;

    // ─── ドメインワーピング（2段階）───────────────────────────────────────────
    vec2 p = uv * 4.5;

    // 第1段階
    float q0 = fbm(p + vec2(t * 0.28, t * 0.19));
    float q1 = fbm(p + vec2(5.2 + t * 0.21, 1.3 + t * 0.31));

    // 第2段階
    float r0 = fbm(p + 3.0 * vec2(q0, q1) + vec2(1.7, 9.2) + vec2(t * 0.14, t * 0.09));
    float r1 = fbm(p + 3.0 * vec2(q0, q1) + vec2(8.3, 2.8) + vec2(t * 0.09, t * 0.14));

    float f = fbm(p + 3.0 * vec2(r0, r1));

    // ─── 大きな流れ筋（主要な石目）────────────────────────────────────────────
    float vein1 = abs(sin(
        (uv.x * 7.0 + uv.y * 2.5) + f * 11.0 + t * 0.45
    ));
    vein1 = pow(1.0 - vein1, 2.8);

    // ─── 細い流れ筋（副次的な石目）────────────────────────────────────────────
    float vein2 = abs(sin(
        (uv.x * 3.5 - uv.y * 9.0) + f * 8.5 - t * 0.32
    ));
    vein2 = pow(1.0 - vein2, 6.0) * 0.6;

    // ─── 極細の光る筋（ハイライト）────────────────────────────────────────────
    float veinShine = abs(sin(
        (uv.x * 5.0 + uv.y * 6.0) + f * 9.0 + t * 0.6
    ));
    veinShine = pow(1.0 - veinShine, 12.0) * 0.4;

    // ─── カラーパレット（ダークメタリックマーブル）────────────────────────────
    // 暗い下地：黒に近い青みがかった色
    vec3 cBase   = vec3(0.05, 0.05, 0.08);
    // 深いブルーグレー
    vec3 cDeep   = vec3(0.08, 0.10, 0.17);
    // スレートブルー
    vec3 cSlate  = vec3(0.16, 0.20, 0.30);
    // シルバーブルーの石目
    vec3 cVein   = vec3(0.45, 0.52, 0.68);
    // 明るいシルバーのハイライト
    vec3 cShine  = vec3(0.82, 0.86, 0.94);

    // 下地をfBmで混ぜて奥行きを出す
    float fNorm = clamp(f * 1.2 + 0.1, 0.0, 1.0);
    vec3 col = mix(cBase, cDeep, fNorm);
    col = mix(col, cSlate, clamp(fNorm - 0.3, 0.0, 1.0) * 1.5);

    // 石目を重ねる
    col += cVein  * vein1;
    col += cVein  * vein2;
    col += cShine * veinShine;

    // ごく薄いブルーアクセント
    col += vec3(0.0, 0.015, 0.06) * (1.0 - fNorm);

    // ─── ビネット（周辺を暗く）────────────────────────────────────────────────
    vec2  center  = uv - 0.5;
    float vignette = 1.0 - dot(center, center) * 1.4;
    col *= clamp(vignette, 0.0, 1.0);

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
