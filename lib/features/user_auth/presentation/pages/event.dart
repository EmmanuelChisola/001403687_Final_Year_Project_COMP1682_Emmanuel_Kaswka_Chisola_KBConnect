
class Event {
  String title;
  String id; // Add this field

  Event({required this.title, required this.id}); // Update constructor to include id

  // If you're using fromJson or toJson methods, make sure to include id there too
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      title: json['title'] as String,
      id: json['id'] as String, // Make sure to parse id
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'id': id, // Include id in the JSON map
    };
  }
}
