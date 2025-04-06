import 'package:hive/hive.dart';

part 'detection.g.dart';

@HiveType(typeId: 0)
class Detection extends HiveObject {
  @HiveField(0)
  String label;

  @HiveField(1)
  double score;

  @HiveField(2)
  String? nickname;

  @HiveField(3)
  String? behaviorNote;

  @HiveField(4)
  String? condition;

  @HiveField(5)
  String? location;

  @HiveField(6)
  String? freeNote;

  // ✅ 🆕 座標情報を追加（Rectの代わり）
  @HiveField(7)
  double left;

  @HiveField(8)
  double top;

  @HiveField(9)
  double width;

  @HiveField(10)
  double height;

  Detection({
    required this.label,
    required this.score,
    this.nickname,
    this.behaviorNote,
    this.condition,
    this.location,
    this.freeNote,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
}