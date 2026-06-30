import 'package:flutter/material.dart';

/// ユガロック戦専用: 腕の揺動位置を示すスライドカーソル型タイミングバー。
/// [swingNormalized] が _sweetMin〜_sweetMax の範囲に入ると攻撃チャンス。
/// ゾーン内は中央(赤)→橙→黄のグラデーション。
class AttackTimingBar extends StatefulWidget {
  final double swingNormalized;
  final double width;

  const AttackTimingBar({
    super.key,
    required this.swingNormalized,
    required this.width,
  });

  @override
  State<AttackTimingBar> createState() => _AttackTimingBarState();
}

class _AttackTimingBarState extends State<AttackTimingBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ドリルの当たり判定が成立する「攻撃チャンス」ゾーン
  static const double _sweetMin = 0.25;
  static const double _sweetMax = 0.75;
  static const double _zoneCenter = (_sweetMin + _sweetMax) / 2; // 0.5
  static const double _zoneHalf = (_sweetMax - _sweetMin) / 2; // 0.25

  static const _colorRed = Color(0xFFDD2020);
  static const _colorOrange = Color(0xFFFF7700);
  static const _colorYellow = Color(0xFFFFCC00);
  static const _trackColor = Color(0xFF2A2A2A);
  static const _cursorColorDefault = Color(0xFFEEEEEE);

  /// ゾーン内の位置(0=中心, 1=端)からゾーンカラーを返す
  Color _zoneColor(double t) {
    if (t < 0.5) {
      return Color.lerp(_colorRed, _colorOrange, t * 2)!;
    }
    return Color.lerp(_colorOrange, _colorYellow, (t - 0.5) * 2)!;
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.swingNormalized.clamp(0.0, 1.0);
    final inSweet = p >= _sweetMin && p <= _sweetMax;

    // ゾーン内での中心からの距離 (0=中心, 1=端)
    final zoneT = inSweet
        ? ((p - _zoneCenter).abs() / _zoneHalf).clamp(0.0, 1.0)
        : 1.0;
    final zoneColor = inSweet ? _zoneColor(zoneT) : _cursorColorDefault;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        final pulse = inSweet ? _pulseAnimation.value : 1.0;

        return Container(
          width: widget.width,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
          color: const Color(0xFF434343),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    inSweet ? '今だ！' : '攻撃タイミング',
                    style: TextStyle(
                      color: inSweet
                          ? Color.lerp(zoneColor, Colors.white, pulse * 0.4)
                          : Colors.white54,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'ATTACK',
                    style: TextStyle(
                      color: _colorYellow.withValues(alpha: 0.55),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              LayoutBuilder(
                builder: (context, constraints) {
                  final trackW = constraints.maxWidth;
                  const trackH = 8.0;
                  const cursorR = 7.0;
                  const totalH = trackH + cursorR * 2;
                  final cursorCenterX = (cursorR + p * (trackW - cursorR * 2))
                      .clamp(cursorR, trackW - cursorR);
                  final zoneL = trackW * _sweetMin;
                  final zoneW = trackW * (_sweetMax - _sweetMin);

                  return SizedBox(
                    width: trackW,
                    height: totalH,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // トラック背景
                        Positioned(
                          left: 0,
                          top: cursorR - trackH / 2,
                          child: Container(
                            width: trackW,
                            height: trackH,
                            decoration: BoxDecoration(
                              color: _trackColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        // スイートゾーン: 中央赤→橙→黄グラデーション
                        Positioned(
                          left: zoneL,
                          top: cursorR - trackH / 2,
                          child: Opacity(
                            opacity: inSweet ? (0.45 + pulse * 0.35) : 0.3,
                            child: Container(
                              width: zoneW,
                              height: trackH,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _colorYellow,
                                    _colorOrange,
                                    _colorRed,
                                    _colorOrange,
                                    _colorYellow,
                                  ],
                                  stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // カーソル(丸): ゾーン内は位置に応じた色
                        Positioned(
                          left: cursorCenterX - cursorR,
                          top: 0,
                          child: Container(
                            width: cursorR * 2,
                            height: cursorR * 2,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: inSweet
                                  ? Color.lerp(
                                      zoneColor,
                                      Colors.white,
                                      pulse * 0.4,
                                    )
                                  : _cursorColorDefault,
                              boxShadow: [
                                if (inSweet)
                                  BoxShadow(
                                    color: zoneColor.withValues(
                                      alpha: pulse * 0.85,
                                    ),
                                    blurRadius: 10,
                                    spreadRadius: 3,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
