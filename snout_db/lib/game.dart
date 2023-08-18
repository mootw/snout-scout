/// 0 seconds is reserved for events before the match starts like starting pos
/// 1 to 16 seconds are for auto (15 seconds)
/// 16-18; the delay between teleop and auto is treated as auto
/// for scoring and scouting UI purposes. It is better that the scout records
/// an auto event outside of auto than to miss the transition messing up the
/// entire match recording. The timing between auto and teleop changes slightly
/// each year but it does not seem significant enough to warrant a config value.
/// 18 to 153 are teleop
/// the time resolution is 1 second internally to snout-scout for match scouting.
Duration matchLength = const Duration(minutes: 2, seconds: 32);

/// Team includes all of the field teams ("red" and "blue"), but also all possible match winning teams like "tie"
enum Alliance { red, blue, tie }
