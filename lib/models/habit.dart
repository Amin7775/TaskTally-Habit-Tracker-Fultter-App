import 'package:isar/isar.dart';

//cmd to generate file : dart run build_runner build
part 'habit.g.dart';

@Collection()
class Habit {
  //habit id
  Id id = Isar.autoIncrement;
  //habit name
  late String name;

  //habit days
  List<DateTime> completedDays = [];
}
