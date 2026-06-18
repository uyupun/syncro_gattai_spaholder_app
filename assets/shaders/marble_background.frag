#include <flutter/runtime_effect.glsl>

uniform float uTime;
uniform float uWidth;
uniform float uHeight;

out vec4 fragColor;

// ─── ノイズ ───────────────────────────────────────────────────────────────────
float hash(vec2 p) {
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p + 19.19);
    return fract(p.x * p.y);
}

float vnoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * f * (f * (f * 6.0 - 15.0) + 10.0);
    return mix(
        mix(hash(i),                  hash(i + vec2(1.0, 0.0)), u.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
        u.y
    );
}

float fbm(vec2 p) {
    float v = 0.0, a = 0.5;
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.5));
    for (int i = 0; i < 5; i++) {
        v += a * vnoise(p);
        p  = rot * p * 2.1 + vec2(100.0);
        a *= 0.5;
    }
    return v;
}

// sinの山頂を細い石目線にする (sharpness ↑ → より細く鋭い)
float veinLine(float v, float sharpness) {
    return pow(1.0 - abs(sin(v * 3.14159)), sharpness);
}

// ─── メイン ───────────────────────────────────────────────────────────────────
void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv        = fragCoord / vec2(uWidth, uHeight);

    float t      = uTime * 0.022;
    float aspect = uWidth / uHeight;
    vec2  p      = vec2(uv.x * aspect, uv.y) * 3.8;

    // ─── 共通ドメインワーピング（両色が同じ「流れ」に乗る）────────────────────
    vec2 q = vec2(
        fbm(p + vec2(0.10, 0.30) + vec2(t * 0.38, t * 0.21)),
        fbm(p + vec2(4.80, 1.70) + vec2(t * 0.21, t * 0.38))
    );
    vec2 wp = p + 5.0 * q;

    // 赤用追加ワープ: より水平方向に流れる
    float wR = fbm(wp + vec2(1.50, 0.50) + vec2(t * 0.17, t * 0.08));
    // 青用追加ワープ: より斜め〜垂直方向に流れる
    float wB = fbm(wp + vec2(0.80, 6.20) + vec2(t * 0.09, t * 0.19));

    // ─── 赤の石目パターン（水平寄り）─────────────────────────────────────────
    float mR = 0.0;
    mR += sin(wp.x * 3.8  + wp.y * 0.9  + wR * 4.5  + t * 0.72);
    mR += sin(wp.x * 1.9  - wp.y * 1.4  + wR * 3.0  + t * 0.50) * 0.65;
    mR += sin(wp.x * 5.5  + wp.y * 0.3  + wR * 2.2  + t * 0.38) * 0.35;
    mR /= 2.0;

    float rBroad  = veinLine(mR, 1.8);   // ぼんやりグロー
    float rMedium = veinLine(mR, 6.0);   // 石目線
    float rSharp  = veinLine(mR, 20.0);  // 輝きエッジ

    // ─── 青の石目パターン（斜め〜垂直）───────────────────────────────────────
    float mB = 0.0;
    mB += sin(wp.x * 0.7  + wp.y * 4.2  + wB * 4.0  - t * 0.63);
    mB += sin(wp.x * -1.6 + wp.y * 3.0  + wB * 3.2  - t * 0.44) * 0.65;
    mB += sin(wp.x * 1.1  + wp.y * 5.8  + wB * 2.0  - t * 0.29) * 0.35;
    mB /= 2.0;

    float bBroad  = veinLine(mB, 1.8);
    float bMedium = veinLine(mB, 6.0);
    float bSharp  = veinLine(mB, 20.0);

    // ─── 赤×青 混色 ───────────────────────────────────────────────────────────
    // mix(cRed, cBlue, 0.5) ≈ vec3(0.435, 0.035, 0.670) ≈ #6F09AB ≈ #6F09AE
    vec3 cRed  = vec3(0.75, 0.02, 0.36);   // ラズベリーレッド
    vec3 cBlue = vec3(0.12, 0.05, 0.98);   // インディゴブルー

    // broad 層: 赤と青の強さの比で色を決める
    float totB = rBroad + bBroad;
    float blB  = totB > 0.001 ? bBroad / totB : 0.5;
    vec3  cB   = mix(cRed, cBlue, blB);

    // medium 層
    float totM = rMedium + bMedium;
    float blM  = totM > 0.001 ? bMedium / totM : 0.5;
    vec3  cM   = mix(cRed, cBlue, blM);

    // sharp 層（ラベンダー白にシフト）
    float totS = rSharp + bSharp;
    float blS  = totS > 0.001 ? bSharp / totS : 0.5;
    vec3  cShine = vec3(0.88, 0.55, 1.00);
    vec3  cS     = mix(mix(cRed, cBlue, blS), cShine, 0.55);

    // ─── 下地と合成 ────────────────────────────────────────────────────────────
    vec3  cBase = vec3(0.03, 0.01, 0.06);
    float bgTex = fbm(p * 0.5 + vec2(t * 0.03)) * 0.5 + 0.5;
    vec3  col   = mix(cBase, cBase * 2.5, bgTex * bgTex);

    col = mix(col, cB, clamp(totB * 0.85, 0.0, 1.0));
    col = mix(col, cM, clamp(totM * 0.90, 0.0, 1.0));
    col = mix(col, cS, clamp(totS,        0.0, 1.0));

    // ─── ビネット ──────────────────────────────────────────────────────────────
    vec2  c   = uv - 0.5;
    float vig = clamp(1.0 - dot(c, c) * 1.5, 0.0, 1.0);
    col *= vig;

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
