#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;

out vec4 fragColor;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i + vec2(0.0,0.0)), hash(i + vec2(1.0,0.0)), u.x),
               mix(hash(i + vec2(0.0,1.0)), hash(i + vec2(1.0,1.0)), u.x), u.y);
}

// ノイズのループ回数は維持しつつ、倍率を少しマイルドに調整
float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    mat2 rot = mat2(0.8, 0.6, -0.6, 0.8);
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p = rot * p * 2.0;
        a *= 0.5;
    }
    return v;
}

void main() {
    vec2 p = (FlutterFragCoord().xy - 0.5 * uSize) / min(uSize.x, uSize.y);
    
    // ⭐ ズームイン！模様を大きく見せるためにスケールを2.8から1.6へ縮小
    p *= 1.6; 
    
    // ⏱️ 【変更ポイント】アニメーションの全体速度をゆっくりに調整（0.25 → 0.08）
    // もっと遅くしたい場合は 0.05 などに、少し速く戻したい場合は 0.15 などに調整してください。
    float t = uTime * 0.05;

    // 🌊 複数の方向・速度の波を足し合わせて、あちこちで「絡み合う」動きを作ります。
    vec2 flow = p;
    
    // 1つ目の波（ベースのうねり）
    flow.x += sin(p.y * 2.2 + t * 0.6) * 0.25;
    flow.y += cos(p.x * 2.0 - t * 0.5) * 0.25;
    
    // 2つ目の波（斜め方向からぶつけて干渉させる）
    flow.x += cos(p.y * 1.5 - p.x * 1.1 + t * 0.4) * 0.20;
    flow.y += sin(p.x * 1.4 + p.y * 1.2 - t * 0.3) * 0.20;

    // 3つ目の波（ゆっくりとした大きな引き合い）
    flow.x += sin(p.x * 0.8 + t * 0.3) * 0.15;
    flow.y += cos(p.y * 0.9 + t * 0.4) * 0.15;

    // ドメインワーピング（歪みの係数を下げて、グチャグチャになりすぎないようにする）
    vec2 q = vec2(
        fbm(flow + vec2(0.0, 0.0) + t * 0.2),
        fbm(flow + vec2(5.2, 1.3) - t * 0.2)
    );
    vec2 r = vec2(
        fbm(flow + 3.0 * q + vec2(1.7, 9.2) + t * 0.3),
        fbm(flow + 3.0 * q + vec2(8.3, 2.8) - t * 0.3)
    );

    float n = fbm(flow + 4.0 * r);

    // ⭐ 等高線の密度を 12.0 から 7.0 へ変更。これで帯が太くなります
    float val = n * 7.0 - t * 1.0;
    float bandIdx = floor(val);
    float localF = fract(val);

    // 🎨 カラーパレット
    vec3 colRed    = vec3(0.680, 0.320, 0.350); // くすんだ赤
    vec3 colBlue   = vec3(0.200, 0.463, 0.624); // くすんだ青 (#33769F)
    vec3 colPurple = vec3(0.255, 0.078, 0.271); // ご指定の紫 (#411445)

    vec3 baseCol = mod(bandIdx, 2.0) < 1.0 ? colRed : colBlue;

    // 帯が太くなった分、紫の縁取り線のバランスも調整
    float edgeDist = min(localF, 1.0 - localF);
    float blend = smoothstep(0.06, 0.18, edgeDist);

    vec3 finalCol = mix(colPurple, baseCol, blend);

    fragColor = vec4(finalCol, 1.0);
}
