import 'package:flame_audio/flame_audio.dart';

enum GameSe {
  connectButton('se/connect-button.mp3'),
  connectComplete('se/connect-complete.mp3'),
  disconnectButton('se/disconnect-button.mp3'),
  disconnectComplete('se/disconnect-complete.mp3'),
  sortieButton('se/sortie-button.mp3'),
  syncroCharge('se/syncro-charge.mp3'),
  syncroGuard('se/syncro-guard.mp3'),
  syncroAttack('se/syncro-attack.mp3'),
  yugarockRoll('se/yugarock-roll.mp3'),
  yugarockFillIn('se/yugarock-fill-in.mp3'),
  asyncStream('se/async-stream.mp3'),
  asyncVacuum('se/async-vacuum.mp3'),
  keepFightingButton('se/keep-fighting-button.mp3'),
  giveUpButton('se/give-up-button.mp3'),
  hpLow('se/hp-low.mp3');

  final String path;
  const GameSe(this.path);

  void play() => FlameAudio.play(path);
}
