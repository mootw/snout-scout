String formatDuration(Duration duration) {
  String s = "";

  int mins = duration.inMinutes.abs();
  if (mins > 0) {
    s = "$mins min${mins != 1 ? "s" : ""}";
  }
  int hours = duration.inHours.abs();
  if (hours > 0) {
    s = "$hours hour${hours != 1 ? "s" : ""}";
  }
  int days = duration.inDays.abs();
  if (days > 0) {
    s = "$days day${days != 1 ? "s" : ""}";
  }

  if (duration.inMinutes == 0) {
    return "now";
  }
  if (duration.isNegative) {
    return "$s ago";
  } else {
    return "in $s";
  }
}

String offsetDurationInMins(Duration duration) {
  // Positive delay means it is behind.
  if (duration.abs() < Duration(minutes: 2)) {
    return 'on time';
  }
  return '${duration.abs().inMinutes} mins ${duration.isNegative ? 'ahead' : 'behind'}';
}
