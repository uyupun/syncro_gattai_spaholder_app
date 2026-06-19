#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;
uniform float uNoiseIntensity; // 0.0(通常) 〜 1.0(ノイズ発生)
uniform sampler2D uTexture;

out vec4 fragColor;

// 擬似ランダムノイズを生成する関数
float noise(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    
    float wave = 0.0;
    float shift = 0.0012; // 目の負担を減らすため、通常時のRGBズレ（にじみ）も少しマイルドに
    
    // ノイズ発生時（一瞬だけパチッとさせる処理）
    if (uNoiseIntensity > 0.0) {
        // 横方向の瞬間的なブレ
        float stripe = noise(vec2(floor(uv.y * 15.0), uTime));
        if (stripe > 0.4) {
            wave = (noise(vec2(uTime)) - 0.5) * 0.012 * uNoiseIntensity;
        }
        
        // 色収差を一瞬強くする
        shift += 0.004 * uNoiseIntensity * noise(vec2(uTime));
    }
    
    // サンプリング（画像の切り出し）
    float r = texture(uTexture, vec2(uv.x + shift + wave, uv.y)).r;
    float g = texture(uTexture, vec2(uv.x + wave,         uv.y)).g;
    float b = texture(uTexture, vec2(uv.x - shift + wave, uv.y)).b;
    
    // ❌ 【完全削除】目を疲れさせる原因だった「黒い横線（走査線）」の処理はすべてカットしました！
    
    // 画面全体へのパチパチ砂嵐ノイズ（ノイズ発生時のみ）
    if (uNoiseIntensity > 0.0) {
        float n = (noise(uv + uTime) - 0.5) * 0.05 * uNoiseIntensity;
        r += n; g += n; b += n;
    }
    
    // 💡 【新規実装】全体的にとても薄い黒や茶色のフィルタ（ウォーム・シネマトーン）
    // 全体の明るさをわずかに落とし（薄い黒ベール）、青み(b)を少し強めに抑えることで、
    // フィルムカメラのような、ほんのり温かみのある茶色（セピア調）のニュアンスを出します。
    r = r * 0.96 + 0.025; // 赤みをほんのり残す
    g = g * 0.93 + 0.018; // 緑をブレンド
    b = b * 0.84 + 0.005; // 青を落として黄色〜茶色寄りにシフト
    
    fragColor = vec4(r, g, b, 1.0);
}
