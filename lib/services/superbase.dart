// a water function takes in title and body and uploads to to the db, that is all. the second function  is to tell the person that he has a side quest. so we just keeps the number of side quest.

// function template
// 1. Add 'async' after the parenthesis
Future<void> water(String? title, String? body) async {
  print("Starting...");

  Map<String, dynamic> data = {
    "field": "water",
    "title": title ?? "Your water buddy here",
    "body":
        body ??
        "Don't forget to drink water! Stay hydrated for better focus and energy during your study sessions.",
  };
  // 2. Use 'await' before a slow task
  final result = await uploadToDatabase(data, userId: "12345");
  // 3. This line only runs AFTER the await finishes
  print("Done! Result is $result");
}

// 1. Add 'async' after the parenthesis
Future<void> addsidechallenge(String id) async {
  print("Starting...");
  Map<String, dynamic> data = {"field": "side_challenge", "id": id};

  // 2. Use 'await' before a slow task
  final result = await uploadToDatabase(data, userId: "12345");

  // 3. This line only runs AFTER the await finishes
  print("Done! Result is $result");
}

// Simulated database upload function
Future<String> uploadToDatabase(
  Map<String, dynamic> data, {
  required String userId,
}) async {
  // Simulate a delay for the database operation
  await Future.delayed(Duration(seconds: 2));
  // Return a success message
  return "Data uploaded for user $userId with field ${data['field']}";
}
