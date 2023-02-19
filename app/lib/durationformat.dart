


String formatDuration (Duration duration) {
  String s = "";

  int mins = duration.inMinutes.abs();
  if(mins > 0) {
    s = "$mins min${mins != 1 ? "s" : ""}";
  }
  int hours = duration.inHours.abs();
  if(hours > 0) {
    s = "$hours hour${hours != 1 ? "s" : ""}";
  }
  int days = duration.inDays.abs();
  if(days > 0) {
    s = "$days day${days != 1 ? "s" : ""}";
  }

  if(duration.inMinutes == 0) {
    return "now";
  }
  if(duration.isNegative) {
    return "$s ago";
  } else {
    return "in $s";
  }
}

String offsetDurationInMins(Duration duration) {
  //Do not add a negative sign since it is already included in the minutes.
  return "${duration.isNegative == true ? "" : "+"}${duration.inMinutes} min${duration.inMinutes == 1 ? "" : "s"}";
}