/// Stores game type data and things



//0 seconds is reserved for events before the match starts like starting pos
//1 to 16 seconds are for auto (15 seconds)
//17; the delay between teleop and auto is ignored and treated as auto
//for scoring and scouting UI purposes. It is better that the scout records
//an auto event outside of auto than to miss the transition messing up the
//entire match recording
//18 to 153 are teleop
//because the time resolution is 1 second internally to snout-scout
Duration matchLength = const Duration(minutes: 2, seconds: 31);



// Team includes all of the field teams ("red" and "blue"), but also all possible match winning teams like "tie"
enum Alliance {red, blue, tie}