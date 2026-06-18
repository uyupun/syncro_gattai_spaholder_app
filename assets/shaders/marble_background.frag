#include <flutter/runtime_effect.glsl>

uniform float uTime;
uniform float uWidth;
uniform float uHeight;

out vec4 fragColor;

// ─── Value Noise ──────────────────────────────────────────────────────────────
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

// ─── タービュランス ────────────────────────────────────────────────────────────
// abs(noise) の多重加算で「鋭い稜線」を生む。
// これがマーブルの石目らしさの核心。通常の fBm だと稜線が出ない。
float turb(vec2 p) {
    float v = 0.0, a = 1.0;
    for (int i = 0; i < 7; i++) {
        v += a * abs(vnoise(p) * 2.0 - 1.0);
        p  = p * 2.05 + vec2(73.1, 52.7);
        a *= 0.5;
    }
    return v / 1.98;   // [0, 1] に正規化
}

// ─── メイン ───────────────────────────────────────────────────────────────────
void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 uv        = fragCoord / vec2(uWidth, uHeight);

    float aspect = uWidth / uHeight;
    vec2  pos    = vec2(uv.x * aspect, uv.y);

    // ─── 大きくゆっくり揺れる底流（全体の流れ感）──────────────────────────────
    float st = uTime * 0.016;
    float warp = vnoise(pos * 1.1 + vec2(st * 0.55, st * 0.35)) * 0.38
               + vnoise(pos * 0.55 + vec2(st * 0.28, st * 0.62)) * 0.22;
    vec2 wp = pos + warp * 0.65;   // 25〜40% 程度の大きな空間歪み

    vec2 p = wp * 3.2;

    // ─── タービュランス（赤・青で共有 → 同じ石の地層で歪む）──────────────────
    float t = turb(p);

    // ─── 赤の石目 ─────────────────────────────────────────────────────────────
    // 方向がゆっくり回転 → 石目が「ゆらゆら」と向きを変える
    float aR  = uTime * 0.015;
    float phR = uTime * 0.30;
    // sin の引数をタービュランスで大きく歪める（7.5 = 歪み強度）
    float rawR = sin(dot(p, vec2(cos(aR), sin(aR))) * 3.5 + t * 7.5 + phR);
    float mR   = rawR * 0.5 + 0.5;   // [0, 1]

    // ─── 青の石目 ─────────────────────────────────────────────────────────────
    // 赤と独立した角速度で回転し、逆方向にも流れる → 常に交差パターンが変化
    float aB  = -uTime * 0.011 + 1.57;   // π/2 offset で直交しやすくする
    float phB = -uTime * 0.22;            // 逆方向に流れる
    float rawB = sin(dot(p, vec2(cos(aB), sin(aB))) * 3.5 + t * 7.5 + phB);
    float mB   = rawB * 0.5 + 0.5;

    // ─── べき乗で石目を細い輝く線にシャープ化 ─────────────────────────────────
    // pow(x, n) は n が大きいほど細い線になる（マーブルの特徴的な細脈）
    float vR = pow(mR, 4.5);
    float vB = pow(mB, 4.5);

    // ─── カラー合成 ────────────────────────────────────────────────────────────
    vec3 cBase   = vec3(0.04, 0.01, 0.07);   // 黒紫の石（下地）
    vec3 cRed    = vec3(0.82, 0.03, 0.18);   // 深紅の石目
    vec3 cBlue   = vec3(0.10, 0.03, 0.95);   // 深青の石目
    vec3 cPurple = vec3(0.44, 0.04, 0.68);   // #6F09AE（交差部）
    vec3 cShine  = vec3(0.92, 0.60, 1.00);   // ラベンダー白（最輝点）

    // 下地: rawR / rawB でごく微妙な石の色むらを付ける（追加コストなし）
    float stoneVar = (rawR * 0.12 + rawB * 0.08) * 0.5 + 0.5;
    vec3  col = mix(cBase, cBase * 1.9, stoneVar * stoneVar * 0.5);

    // 赤・青の石目を重ねる
    col = mix(col, cRed,  vR);
    col = mix(col, cBlue, vB);

    // 交差部: vR * vB は両方の石目が重なる場所でのみ大きくなる
    // → 赤と青が出会う瞬間に #6F09AE の紫が浮かぶ
    float cross = vR * vB;
    col = mix(col, cPurple, clamp(cross * 5.5, 0.0, 0.90));

    // 最輝点（石目の中心線が交わる点）→ ラベンダー白でキラリと光る
    col = mix(col, cShine, clamp(cross * cross * 14.0, 0.0, 0.72));

    // ─── ビネット ──────────────────────────────────────────────────────────────
    vec2  c   = uv - 0.5;
    float vig = clamp(1.0 - dot(c, c) * 1.4, 0.0, 1.0);
    col *= vig;

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
