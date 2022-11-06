


String formatDuration (Duration duration) {
  String s = "";

  int mins = duration.inMinutes.abs();
  if(mins > 0) {
    s = "$mins hour${mins != 1 ? "s" : ""}";
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
    return "0 mins";
  }
  if(duration.isNegative) {
    return "$s ago";
  } else {
    return "in $s";
  }
  
}