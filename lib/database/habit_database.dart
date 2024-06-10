import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:task_tally/models/app_settings.dart';
import 'package:task_tally/models/habit.dart';

class HabitDatabase extends ChangeNotifier {
  static late Isar isar;

  // Setup

  // Initialize Database
  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [HabitSchema, AppSettingsSchema],
      directory: dir.path,
    );
  }

  // Save first date of app startup(for heatmap)
  Future<void> saveFirstLaunchDate() async {
    final existingSettings = await isar.appSettings.where().findFirst();
    if (existingSettings == null) {
      final settings = AppSettings()..firstLaunchDate = DateTime.now();
      await isar.writeTxn(() => isar.appSettings.put(settings));
    }
  }

  // Get first date of app startup (for heatmap)
  Future<DateTime?> getFirstLaunchDate() async {
    final settings = await isar.appSettings.where().findFirst();
    return settings?.firstLaunchDate;
  }

  // CRUD Operations

  // List of habits
  final List<Habit> currentHabits = [];

  // Create - add a new habit
  Future<void> addHabit(String habitName) async {
    // create a new habit
    final newHabit = Habit()..name = habitName;
    // save to db
    await isar.writeTxn(() => isar.habits.put(newHabit));
    // re-read from db
    readHabits();
  }

  // Read - read saved habits from db
  Future<void> readHabits() async {
    // fetch all habits from db
    List<Habit> fetchedHabits = await isar.habits.where().findAll();
    // give to current habits
    currentHabits.clear();
    currentHabits.addAll(fetchedHabits);
    // update UI
    notifyListeners();
  }

  // Update - Check habit on and off
  Future<void> updateHabitCompletion(int id, bool isCompleted) async {
    // find specific habit
    final habit = await isar.habits.get(id);

    // update completion status
    if (habit != null) {
      await isar.writeTxn(() async {
        // if habit is completed - add the current date to the completedDays list
        if (isCompleted && !habit.completedDays.contains(DateTime.now())) {
          // today
          final today = DateTime.now();

          // add current date if it's not already in the list
          habit.completedDays.add(
            DateTime(
              today.year,
              today.month,
              today.day,
            ),
          );
        }
        // if habit is not completed - remove the current date from the list
        else {
          // remove the current date if the habit is marked as not completed
          habit.completedDays.removeWhere(
            (date) =>
                date.year == DateTime.now().year &&
                date.month == DateTime.now().month &&
                date.day == DateTime.now().day,
          );
        }
        // save updated habits back to the db
        await isar.habits.put(habit);
      });
    }
    // re-read from db
    readHabits();
  }

  // Update - edit habit name
  Future<void> updateHabitName(int id, String newName) async {
    // find specific habit
    final habit = await isar.habits.get(id);

    // update habit name
    if (habit != null) {
      habit.name = newName;
      // update name
      await isar.writeTxn(() async {
        // save updated habit back to the db
        await isar.habits.put(habit);
      });
    }
    // re-read from db
    readHabits();
  }

  // Delete - delete habit
  Future<void> deleteHabit(int id) async {
    await isar.writeTxn(() async {
      await isar.habits.delete(id);
    });

    // re-read from db
    readHabits();
  }

  // Retrieve habit data for a specific day
  Future<List<Habit>> getHabitsForDay(DateTime day) async {
    final formattedDay = DateTime(day.year, day.month, day.day);
    List<Habit> habitsForDay = [];

    for (var habit in currentHabits) {
      if (habit.completedDays.contains(formattedDay)) {
        habitsForDay.add(habit);
      }
    }

    return habitsForDay;
  }
}
