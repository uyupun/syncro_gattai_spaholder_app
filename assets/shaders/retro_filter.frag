#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;
uniform float uTime;           
uniform float uNoiseIntensity; 
uniform sampler2D uTexture;

out vec4 fragColor;

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    
    // 1. 画面の中心からの距離を計算（周辺ボケを作るため）
    vec2 center = vec2(0.5, 0.5);
    vec2 toCenter = uv - center;
    float dist = length(toCenter); // 中心から離れるほど大きくなる値 (0.0 〜 約0.7)
    
    // 💡 【外側の強さを 0.005 に抑える調整】
    // 後ろの加算値を 0.010 ➔ 0.0054 に下げました。
    // これにより、中心付近の「0.0012」のにじみを維持したまま、
    // 最も離れた四隅でも強さが「約0.005」を狙う、非常に上品な【 内 ＜ 外 】が完成します。
    float intensity = (0.0012 / max(dist, 0.001)) + 0.0054;
    vec2 direction = toCenter * intensity; 
    
    // 3. 【色収差 ＋ 擬似レンズブラー】（構造は元のまま維持）
    float r = 0.0;
    float g = 0.0;
    float b = 0.0;
    
    // 赤チャンネル：外側に大きく広げてぼかす
    r += texture(uTexture, uv + direction * 1.5).r * 0.4;
    r += texture(uTexture, uv + direction * 1.0).r * 0.3;
    r += texture(uTexture, uv + direction * 0.5).r * 0.2;
    r += texture(uTexture, uv).r * 0.1;
    
    // 緑チャンネル：中心付近に留めて芯を作る
    g += texture(uTexture, uv + direction * 0.5).g * 0.2;
    g += texture(uTexture, uv).g * 0.6;
    g += texture(uTexture, uv - direction * 0.5).g * 0.2;
    
    // 青チャンネル：内側に大きく狭めてぼかす
    b += texture(uTexture, uv).b * 0.1;
    b += texture(uTexture, uv - direction * 0.5).b * 0.2;
    b += texture(uTexture, uv - direction * 1.0).b * 0.3;
    b += texture(uTexture, uv - direction * 1.5).b * 0.4;

    // 4. 前回の「薄い黒・茶色のヴィンテージトーン」を維持
    r = r * 0.96 + 0.025;
    g = g * 0.93 + 0.018;
    b = b * 0.84 + 0.005;
    
    fragColor = vec4(r, g, b, 1.0);
}
