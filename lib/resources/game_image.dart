enum GameImage {
  // スパホルダー
  upperBody('spaholder/body.png'),
  upperArm('spaholder/arm1.png'),
  drill('spaholder/arm2.png'),
  // ユガロック
  yugarock('yugarock/combat_stance.png'),
  yugarockRolling('yugarock/rolling.png'),
  yugarockFillIn('yugarock/fill_in.png'),
  // アシンクロン
  asyncron('asyncron/combat_stance.png'),
  asyncronStream('asyncron/stream.png'),
  asyncronVacuum('asyncron/vacuum.png');

  final String path;
  const GameImage(this.path);
}
