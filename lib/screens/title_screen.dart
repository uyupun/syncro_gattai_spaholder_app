import 'dart:async';

import 'package:flutter/material.dart';

import '../interfaces/ble_service.dart';

class TitleScreen extends StatefulWidget {
  final VoidCallback onStart;
  final BleService bleService;

  const TitleScreen({super.key, required this.onStart, required this.bleService});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  BleService get _bleService => widget.bleService;
  bool _isConnecting = false;
  List<String> _connectedDevices = [];
  StreamSubscription<List<String>>? _devicesSub;

  @override
  void initState() {
    super.initState();
    _connectedDevices = _bleService.connectedDevices.toList();
    _devicesSub = _bleService.connectedDevicesStream.listen((devices) {
      if (mounted) {
        setState(() {
          _connectedDevices = devices;
          _isConnecting = devices.length < 2 ? _isConnecting : false;
        });
      }
    });
  }

  Future<void> _connectDevices() async {
    if (_connectedDevices.length >= 2) return; // 既に2台接続済み

    setState(() {
      _isConnecting = true;
    });

    try {
      await _bleService.scanAndConnect();
    } catch (e) {
      debugPrint('接続エラー: $e');
      setState(() {
        _isConnecting = false;
      });
    }
  }

  bool get _canStart => _connectedDevices.length >= 2;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFFFF),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // タイトル画像
            Image.asset(
              'assets/images/title.png',
              width: 500,
              height: 230,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // 画像読み込みエラー時のフォールバック
                return const Text(
                  'ROBOT ARM',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 8,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.blueAccent,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                );
              },
            ),

            // 接続状況表示
            Text(
              '接続デバイス数: ${_connectedDevices.length}/2',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 接続ボタン
                if (!_canStart)
                  ElevatedButton(
                    onPressed: _isConnecting ? null : _connectDevices,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: _isConnecting
                        ? const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text('接続中...'),
                            ],
                          )
                        : const Text('デバイス接続'),
                  ),
                if ( _canStart)
                  ElevatedButton(
                    onPressed: () {
                      _bleService.disconnectAll();
                      setState(() {
                        _isConnecting = false;
                        _connectedDevices.clear();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: const Text('デバイス解除'),
                  ),

                const SizedBox(width: 20),

                // スタートボタン
                ElevatedButton(
                  onPressed: _canStart ? widget.onStart : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _canStart ? Colors.green : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('ゲームスタート'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _devicesSub?.cancel();
    super.dispose();
  }
}
