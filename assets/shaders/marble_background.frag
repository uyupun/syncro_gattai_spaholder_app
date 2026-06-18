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

// sharpness ↑ → 石目線が細くなる
float veinLine(float v, float sharpness) {
    return pow(1.0 - abs(sin(v * 3.14159)), sharpness);
}

// ─── メイン ───────────────────────────────────────────────────────────────────
void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv        = fragCoord / vec2(uWidth, uHeight);

    // 赤と青でわずかに速度を変える → 常にすれ違い・交差し続ける
    float t  = uTime * 0.055;   // 共通ワープ速度（アップ）
    float tR = uTime * 0.090;   // 赤は速め
    float tB = uTime * 0.062;   // 青は遅め → 位相差が生まれる

    float aspect = uWidth / uHeight;

    // 全体をゆっくり大きく揺らす底流（sin/cos で円を描くようにドリフト）
    vec2 drift = vec2(
        sin(uTime * 0.028) * 1.2,
        cos(uTime * 0.019) * 0.8
    );

    // スケールを 3.8 → 2.4 に下げて石目を大きく表示
    vec2  p = vec2(uv.x * aspect, uv.y) * 2.4 + drift;

    // ─── 共通ドメインワーピング（強度アップ）──────────────────────────────────
    vec2 q = vec2(
        fbm(p + vec2(0.10, 0.30) + vec2(t * 0.55, t * 0.38)),
        fbm(p + vec2(4.80, 1.70) + vec2(t * 0.38, t * 0.55))
    );
    vec2 wp = p + 10.0 * q;   // ワープ強度 7.5 → 10.0

    // 赤・青それぞれ独立した追加ワープ（速度が違うので常にずれる）
    float wR = fbm(wp + vec2(1.50, 0.50) + vec2(tR * 0.44, tR * 0.30));
    float wB = fbm(wp + vec2(0.80, 6.20) + vec2(tB * 0.28, tB * 0.50));

    // ─── 赤の石目（水平〜斜め・tR で流れる）──────────────────────────────────
    float mR = 0.0;
    mR += sin(wp.x * 2.6  + wp.y * 0.6  + wR * 5.0  + tR * 1.80);
    mR += sin(wp.x * 1.3  - wp.y * 1.0  + wR * 3.5  + tR * 1.25) * 0.65;
    mR += sin(wp.x * 3.8  + wp.y * 0.2  + wR * 2.5  + tR * 0.80) * 0.35;
    mR /= 2.0;

    // broad(1.0): さらに広いグロー → 色のにじみを強調
    float rBroad  = veinLine(mR, 1.0);
    float rMedium = veinLine(mR, 5.5);
    float rSharp  = veinLine(mR, 20.0);

    // ─── 青の石目（垂直〜斜め・tB で流れる）──────────────────────────────────
    float mB = 0.0;
    mB += sin(wp.x * 0.5  + wp.y * 2.9  + wB * 4.5  - tB * 1.55);
    mB += sin(wp.x * -1.1 + wp.y * 2.1  + wB * 3.5  - tB * 1.10) * 0.65;
    mB += sin(wp.x * 0.8  + wp.y * 4.0  + wB * 2.2  - tB * 0.70) * 0.35;
    mB /= 2.0;

    float bBroad  = veinLine(mB, 1.0);
    float bMedium = veinLine(mB, 5.5);
    float bSharp  = veinLine(mB, 20.0);

    // ─── カラーパレット ─────────────────────────────────────────────────────────
    // mix(cRed, cBlue, 0.5) ≈ vec3(0.435, 0.035, 0.670) ≈ #6F09AB ≈ #6F09AE
    vec3 cRed   = vec3(0.75, 0.02, 0.36);   // ラズベリーレッド
    vec3 cBlue  = vec3(0.12, 0.05, 0.98);   // インディゴブルー
    vec3 cMix   = vec3(0.44, 0.04, 0.68);   // #6F09AE（混合ゾーン用）
    vec3 cShine = vec3(0.88, 0.55, 1.00);   // ラベンダー白（ハイライト）

    // ─── broad: 赤/青の比率で混色、交差量に応じて紫にブースト ──────────────────
    float totB = rBroad + bBroad;
    float blB  = totB > 0.001 ? bBroad / totB : 0.5;
    vec3  cB   = mix(cRed, cBlue, blB);

    // 交差ゾーン強調: rBroad * bBroad は両方あるときだけ大きくなる
    float mixPower = rBroad * bBroad * 5.0;

    // medium
    float totM = rMedium + bMedium;
    float blM  = totM > 0.001 ? bMedium / totM : 0.5;
    vec3  cM   = mix(cRed, cBlue, blM);

    // sharp（ハイライト: ラベンダーにシフト）
    float totS = rSharp + bSharp;
    float blS  = totS > 0.001 ? bSharp / totS : 0.5;
    vec3  cS   = mix(mix(cRed, cBlue, blS), cShine, 0.55);

    // ─── 下地と合成 ────────────────────────────────────────────────────────────
    vec3  cBase = vec3(0.03, 0.01, 0.06);
    float bgTex = fbm(p * 0.5 + vec2(t * 0.06)) * 0.5 + 0.5;
    vec3  col   = mix(cBase, cBase * 2.5, bgTex * bgTex);

    col = mix(col, cB, clamp(totB * 0.90, 0.0, 1.0));
    col = mix(col, cM, clamp(totM * 0.92, 0.0, 1.0));
    col = mix(col, cS, clamp(totS,        0.0, 1.0));

    // 赤と青が交差する瞬間、#6F09AE の紫がにじみ出る
    col += cMix * clamp(mixPower, 0.0, 0.75);

    // ─── ビネット ──────────────────────────────────────────────────────────────
    vec2  c   = uv - 0.5;
    float vig = clamp(1.0 - dot(c, c) * 1.5, 0.0, 1.0);
    col *= vig;

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
