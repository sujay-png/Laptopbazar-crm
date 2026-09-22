class ReminderModel {
  final String title;
  final DateTime dateTime;
  final bool isCompleted;

  ReminderModel({
    required this.title, 
    required this.dateTime, 
    this.isCompleted = false,
  });
}