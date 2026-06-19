#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;

out vec4 fragColor;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

// バリューノイズ
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i + vec2(0.0,0.0)), hash(i + vec2(1.0,0.0)), u.x),
               mix(hash(i + vec2(0.0,1.0)), hash(i + vec2(1.0,1.0)), u.x), u.y);
}

// イラスト特有の「滑らかで大きなうねり」を作る
float fbm(vec2 p) {
    float v = 0.0;
    v += 0.50 * noise(p); p = p * 2.0 * mat2(0.8, 0.6, -0.6, 0.8);
    v += 0.25 * noise(p);
    return v;
}

void main() {
    // 座標の正規化
    vec2 p = (FlutterFragCoord().xy - 0.5 * uSize) / min(uSize.x, uSize.y);
    p *= 1.5; 
    
    float t = uTime * 0.15;

    // ドメインワーピング
    vec2 q = vec2(
        fbm(p + vec2(0.0, 0.0) + t * 0.1),
        fbm(p + vec2(5.2, 1.3) + t * 0.12)
    );
    vec2 r = vec2(
        fbm(p + 2.5 * q + vec2(1.7, 9.2) - t * 0.15),
        fbm(p + 2.5 * q + vec2(8.3, 2.8) - t * 0.1)
    );

    float n = fbm(p * 1.5 + r * 2.5);

    // 等高線のようにパキッと階層を分ける
    float val = n * 8.0 - t * 0.8 + 1000.0;
    float bandIdx = floor(val);
    float localF = fract(val);

    // 🎨 カラーパレット
    vec3 colRed    = vec3(0.761, 0.247, 0.220); // ご指定の赤 #C23F38
    vec3 colBlue   = vec3(0.125, 0.275, 0.612); // ご指定の青 #20469C
    vec3 colPurple = vec3(0.435, 0.035, 0.682); // ご指定の紫 #6F09AE
    
    // ⭐ 変更点：白を廃止し、少し馴染みの良い「黒っぽい色」を追加
    vec3 colBlack  = vec3(0.05, 0.05, 0.08);    // ダークカラー

    // 3色を順番にベタ塗りでループさせる
    float modId = mod(bandIdx, 3.0);
    vec3 baseCol;
    if (modId < 1.0) {
        baseCol = colRed;
    } else if (modId < 2.0) {
        baseCol = colBlue;
    } else {
        baseCol = colPurple;
    }

    // 🖍️ 黒っぽい境界線を描き込む
    float dist = min(localF, 1.0 - localF);
    float lineFactor = 1.0 - smoothstep(0.09, 0.12, dist);

    // ベースのベタ塗り色の上に、黒い線を合成
    vec3 finalCol = mix(baseCol, colBlack, lineFactor);

    fragColor = vec4(finalCol, 1.0);
}
