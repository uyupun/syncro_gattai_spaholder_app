import 'dart:async';

import 'package:flutter/material.dart';

import '../interfaces/ble_service.dart';
import '../models/ble_device_role.dart';
import '../widgets/connect_button.dart';
import '../widgets/connection_status_label.dart';
import '../widgets/start_button.dart';

enum _ConnectionUiState { idle, connecting, connected, disconnecting }

class TitleScreen extends StatefulWidget {
  final VoidCallback onStart;
  final BleService bleService;

  const TitleScreen({
    super.key,
    required this.onStart,
    required this.bleService,
  });

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen> {
  BleService get _bleService => widget.bleService;

  static const _messageDuration = Duration(seconds: 2);

  _ConnectionUiState _blueState = _ConnectionUiState.idle;
  _ConnectionUiState _redState = _ConnectionUiState.idle;
  String? _blueMessage;
  String? _redMessage;
  Timer? _blueMessageTimer;
  Timer? _redMessageTimer;

  StreamSubscription<Set<BleDeviceRole>>? _rolesSub;

  @override
  void initState() {
    super.initState();

    final connectedRoles = _bleService.connectedRoles;
    _blueState = connectedRoles.contains(BleDeviceRole.blue)
        ? _ConnectionUiState.connected
        : _ConnectionUiState.idle;
    _redState = connectedRoles.contains(BleDeviceRole.red)
        ? _ConnectionUiState.connected
        : _ConnectionUiState.idle;

    _rolesSub = _bleService.connectedRolesStream.listen((roles) {
      if (!mounted) return;
      setState(() {
        if (roles.contains(BleDeviceRole.blue)) {
          if (_blueState != _ConnectionUiState.connected) {
            _blueState = _ConnectionUiState.connected;
            _showMessage(BleDeviceRole.blue, '接続しました');
          }
        } else if (_blueState == _ConnectionUiState.connected ||
            _blueState == _ConnectionUiState.disconnecting) {
          _blueState = _ConnectionUiState.idle;
          _showMessage(BleDeviceRole.blue, '切断完了');
        }

        if (roles.contains(BleDeviceRole.red)) {
          if (_redState != _ConnectionUiState.connected) {
            _redState = _ConnectionUiState.connected;
            _showMessage(BleDeviceRole.red, '接続しました');
          }
        } else if (_redState == _ConnectionUiState.connected ||
            _redState == _ConnectionUiState.disconnecting) {
          _redState = _ConnectionUiState.idle;
          _showMessage(BleDeviceRole.red, '切断完了');
        }
      });
    });
  }

  // 新たな接続/切断操作を開始する際は、表示中のメッセージを打ち切って消去する
  void _setState(
    BleDeviceRole role,
    _ConnectionUiState state, {
    String? message,
  }) {
    setState(() {
      if (role == BleDeviceRole.blue) {
        _blueState = state;
        _blueMessageTimer?.cancel();
        _blueMessageTimer = null;
        _blueMessage = null;
      } else {
        _redState = state;
        _redMessageTimer?.cancel();
        _redMessageTimer = null;
        _redMessage = null;
      }

      if (message != null) {
        _showMessage(role, message);
      }
    });
  }

  // 接続/切断状態が`connectedRolesStream`経由で切り替わるタイミングに合わせて
  // メッセージを表示するため、setState内から呼び出すこと
  void _showMessage(BleDeviceRole role, String message) {
    if (role == BleDeviceRole.blue) {
      _blueMessageTimer?.cancel();
      _blueMessage = message;
    } else {
      _redMessageTimer?.cancel();
      _redMessage = message;
    }

    final timer = Timer(_messageDuration, () {
      if (!mounted) return;
      setState(() {
        if (role == BleDeviceRole.blue) {
          _blueMessage = null;
        } else {
          _redMessage = null;
        }
      });
    });

    if (role == BleDeviceRole.blue) {
      _blueMessageTimer = timer;
    } else {
      _redMessageTimer = timer;
    }
  }

  Future<void> _connect(BleDeviceRole role) async {
    _setState(role, _ConnectionUiState.connecting);

    try {
      await _bleService.connectDevice(role);
    } catch (e) {
      debugPrint('接続エラー: $e');
      _setState(role, _ConnectionUiState.idle, message: '接続に失敗しました');
    }
  }

  Future<void> _disconnect(BleDeviceRole role) async {
    _setState(role, _ConnectionUiState.disconnecting);

    try {
      await _bleService.disconnectDevice(role);
    } catch (e) {
      debugPrint('切断エラー: $e');
      _setState(role, _ConnectionUiState.idle);
    }
  }

  String _labelFor(_ConnectionUiState state) {
    switch (state) {
      case _ConnectionUiState.idle:
        return '接続';
      case _ConnectionUiState.connecting:
        return '接続中...';
      case _ConnectionUiState.connected:
        return '切断';
      case _ConnectionUiState.disconnecting:
        return '切断中...';
    }
  }

  bool _isDisabled(_ConnectionUiState state) {
    return state == _ConnectionUiState.connecting ||
        state == _ConnectionUiState.disconnecting;
  }

  VoidCallback? _onTapFor(BleDeviceRole role, _ConnectionUiState state) {
    switch (state) {
      case _ConnectionUiState.idle:
        return () => _connect(role);
      case _ConnectionUiState.connected:
        return () => _disconnect(role);
      case _ConnectionUiState.connecting:
      case _ConnectionUiState.disconnecting:
        return null;
    }
  }

  bool get _canStart =>
      _blueState == _ConnectionUiState.connected &&
      _redState == _ConnectionUiState.connected;

  Widget _buildConnectButton({
    required ConnectButtonColor color,
    required BleDeviceRole role,
    required _ConnectionUiState state,
    required String? message,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        ConnectButton(
          label: _labelFor(state),
          color: color,
          disabled: _isDisabled(state),
          onTap: _onTapFor(role, state),
        ),
        if (message != null)
          Positioned(top: -36, child: ConnectionStatusLabel(text: message)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/title_screen_background.png',
            fit: BoxFit.cover,
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/title.png',
                width: 500,
                height: 230,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
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
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildConnectButton(
                      color: ConnectButtonColor.blue,
                      role: BleDeviceRole.blue,
                      state: _blueState,
                      message: _blueMessage,
                    ),
                    StartButton(
                      label: '出動',
                      disabled: !_canStart,
                      onTap: widget.onStart,
                    ),
                    _buildConnectButton(
                      color: ConnectButtonColor.red,
                      role: BleDeviceRole.red,
                      state: _redState,
                      message: _redMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _rolesSub?.cancel();
    _blueMessageTimer?.cancel();
    _redMessageTimer?.cancel();
    super.dispose();
  }
}
