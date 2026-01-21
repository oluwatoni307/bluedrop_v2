import 'challenge_model.dart';
import '../../../../services/database_service.dart';

class SeedData {
  static Future<void> injectDummyChallenges() async {
    final db = DatabaseService();
    final boxName = 'challenges';

    // 1. Check if we already have data (Don't duplicate)
    // Note: We use the raw box length.
    // If you don't have a 'count' method, just skip this check or rely on IDs overwriting.
    if (db.count(boxName) > 0) {
      print("🌱 Database already seeded. Skipping.");
      return;
    }

    print("🌱 Seeding Challenges...");

    // CHALLENGE 1: The "Main Quest" (Water)
    // Replaces daily goal with 3000ml for 3 days.
    final c1 = Challenge(
      id: 'chal_water_3day',
      title: 'The 3-Day Reset',
      description: 'Flush your system! Drink 3000ml for 3 days.',
      detailsMarkdown: """
# The 3-Day Reset 🌊
Feel sluggish? This quick challenge is designed to **flush toxins** and rehydrate your brain.

### The Rules
* **Goal:** 3000ml per day
* **Duration:** 3 Days
* **Difficulty:** Medium

### Benefits
* Clearer skin
* Reduced brain fog
* Better digestion
""",
      type: ChallengeType.waterMain,
      durationDays: 3,
      targetVolume: 3000,
      status: ChallengeStatus.available,
    );

    // CHALLENGE 2: The "Side Quest" (Habit)
    // Walk & Drink habit.
    final c2 = Challenge(
      id: 'chal_habit_walk',
      title: 'Walk & Sip',
      description: 'Take a 15-min walk and finish a glass of water.',
      detailsMarkdown: """
# Walk & Sip 🚶‍♂️
Habit stacking is the easiest way to build a new routine. Connect hydration with movement!

### The Task
Every day for 7 days, take a **15-minute walk**.
* Drink 250ml (1 glass) BEFORE you go.
* Drink 250ml (1 glass) AFTER you return.

**Mark this challenge as "Done" only when you finish the walk!**
""",
      type: ChallengeType.habitSide,
      durationDays: 7,
      targetVolume: 0, // Not used for habits
      status: ChallengeStatus.available,
    );

    // CHALLENGE 3: The "Epic" (Long Term)
    final c3 = Challenge(
      id: 'chal_water_master',
      title: 'Hydration Master Class',
      description: 'Consistency is key. Hit 2500ml for 30 days.',
      detailsMarkdown: """
# Master Class 🏆
Can you keep the streak alive?

This is the ultimate test of discipline. Miss a day, and you hurt your average.
""",
      type: ChallengeType.waterMain,
      durationDays: 30,
      targetVolume: 2500,
      status: ChallengeStatus.available,
    );

    // Write to Hive using the generic add/update method
    // We use 'updateInCollection' because we want to specify the ID manually
    // OLD (Causes Error):
    // await db.updateInCollection(boxName, c1.id, c1.toMap());

    // NEW (Fixes Error):
    await db.saveDocument(boxName, c1.id, c1.toMap());
    await db.saveDocument(boxName, c2.id, c2.toMap());
    await db.saveDocument(boxName, c3.id, c3.toMap());

    print("✅ Seed Complete! 3 Challenges added.");
  }
}
