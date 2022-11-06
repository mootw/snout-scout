### Each year the data needs to be different
There is little overlap each year for frc. Generally a list of tools can remain usable year over year or event per event. Though the overlap between pit scouting tools and match scouting tools is minimal.

#### Match Scouting tools
1. duration (time climbs, and other events)
3. event (disabled robot, ball upper, ball miss)
	1. Counts total quanitity of events for display and their point values

### Data Tools
1. generate meta-values like for instance AVERAGE TIME BETWEEN SHOTS or DURATION BETWEEN START OF CLIMB AND END OF CLIMB

Compare estimated performance in a match versus their actual performance, or their performance contribution within a match.


#### Pit scouting tools
1. text-box (comments, whatever else)
2. number (how many balls can it shoot)
3. toggle (Can the robot climb?)
4. map-boolean (shooting positions)
5. map-point (auto start position)
6. selector (no shooter, low goal, high goal, both)
7. picture (robot picture)
8. percent (percentage defense)

# Data/Network
1. There will be one authorative server which collects data.
2. Each event/year will have separate datasets.
3. Server will be configured with an event file (json) which will define the layout



# Season config
{
"team_number": 6749,
}
## Pit scouting
- List of items
	- {"id": "auto_high", "type": "number", "label": "Number of balls robot can score high in autonomous"}
	- {"id": "auto_low", "type": "number", "label": "Number of balls robot can score low in autonomous"}
	- {"id": "shooting_positions", "type": "map-boolean", "label": "Positions this robot can shoot from."}
	- {"id": "shooter_type", "type": "selector", "options": \["No Shooter", "Low Goal", "High Goal", "Any goal"\], "label": "Shooter type"}
	- {"id": "climb", "type": "selector", "options": \["No Climb", "Low", "Medium", "High", "Traversal"\], "label": "Shooter type"}
	- {"id": "climb_time", "type": "number", "label": "Climb time"}
	- {"id": "comments", "type": "text-box",  "label": "Extra comments"}
## Match scouting
{
"auto":  \[ 
	{"id": "cargo_upper", "label": "Cargo Upper", "type": "event", "points": 4, "rp": 0 },
	{"id": "cargo_lower", "type": "event", "points": 2, "rp": 0 },
	{"id": "cargo_miss", "type": "event", "points": 0, "rp": 0 },
	{"id": "exit_tarmac", "type": "event", "points": 2, "rp": 0 },
\],
"teleop":  \[
	{"id": "cargo_upper", "type": "event", "points": 2, "rp": 0, "visual_priority": 1 },
	{"id": "cargo_lower", "type": "event", "points": 1, "rp": 0, "visual_priority": 1 },
	{"id": "cargo_miss", "type": "event", "points": 0, "rp": 0, "visual_priority": 1 },
	{"id": "intake_jam", "type": "event", "points": 0, "rp": 0, "visual_priority": 2 },
\],
"endgame":  \[ 
	{"id": "climb_time", "type": "duration"},
	{"id": "climb_low", "type": "event", "points": 4, "rp": 0 },
	{"id": "climb_mid", "type": "event", "points": 6, "rp": 0 },
	{"id": "climb_high", "type": "event", "points": 10, "rp": 0 },
	{"id": "climb_traversal", "type": "event", "points": 15, "rp": 0 },
\],
"postgame": \[
	 {"id": "climb", "type": "selector", "options": \["No Climb", "Low", "Medium", "High", "Traversal"\], "rp": \[ 0, 4, 6, 10, 15\], "label": "Climb"},
	{"id": "cargo_bonus", "type": "toggle", "rp": 1},
	{"id": "comments", "type": "text-box",  "label": "Extra comments"},
\],
"results": \[
	"points",
	"rp",
	"penalty",
	"taxi",
	"cargo",
	"hangar",
\]
}