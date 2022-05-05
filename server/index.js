
const http = require('http');
const fs = require('fs');


const rapid_react_config = {
    "season": "Rapid React",
    "events": [
        {
            "id": "state",
            "teams": [
                1816,
                2052,
                2169,
                2220,
                2239,
                2470,
                2491,
                2502,
                2503,
                2509,
                2531,
                2823,
                2847,
                2883,
                3018,
                3082,
                3130,
                3184,
                3206,
                3293,
                3630,
                3883,
                4009,
                4607,
                4728,
                5172,
                5434,
                5653,
                5690,
                5913,
                5914,
                6453,
                6749,
                7028,
                7541,
                8516
            ],
            "matches": [
                {
                    "number": 1,
                    "section": "Qualifications",
                    "time": "05 May 2022 08:30:00 CST",
                    "blue": [2823, 2503, 7028],
                    "red": [5653, 4728, 2509],
                },
                {
                    "number": 2,
                    "section": "Qualifications",
                    "time": "05 May 2022 08:38:00 CST",
                    "blue": [7541, 3630, 5172],
                    "red": [4607, 2239, 5914],
                },
                {
                    "number": 3,
                    "section": "Qualifications",
                    "time": "05 May 2022 08:46:00 CST",
                    "blue": [3018, 3883, 3184],
                    "red": [3130, 8516, 2470],
                },
            ],
        },
    ],
    "team_number": 6749,
    "pit_scouting": {
        "survey": [
            { "id": "auto_high", "type": "number", "label": "Number of balls robot can score high in autonomous" },
            { "id": "auto_low", "type": "number", "label": "Number of balls robot can score low in autonomous" },
            { "id": "shooting_positions", "type": "map-boolean", "label": "Positions this robot can shoot from." },
            { "id": "shooter_type", "type": "selector", "options": ["No Shooter", "Low Goal", "High Goal", "Any goal"], "label": "Shooter type" },
            { "id": "climb", "type": "selector", "options": ["No Climb", "Low", "Medium", "High", "Traversal"], "label": "Climb" },
            { "id": "climb_time", "type": "number", "label": "Climb time" },
            { "id": "can_defense", "type": "toggle", "label": "Can this robot play defense?" },
            { "id": "comments", "type": "text-box", "label": "Extra comments" },
        ],
    },
    "match_scouting": {
        "pregame": [
            { "id": "start_position", "type": "map-point", "label": "Starting position of the robot" },
        ],
        "auto": [
            { "id": "cargo_upper", "label": "Cargo Upper", "type": "event", "points": 4, "rp": 0 },
            { "id": "cargo_lower", "type": "event", "points": 2, "rp": 0 },
            { "id": "cargo_miss", "type": "event", "points": 0, "rp": 0 },
            { "id": "exit_tarmac", "type": "event", "points": 2, "rp": 0 },
        ],
        "teleop": [
            { "id": "cargo_upper", "type": "event", "points": 2, "rp": 0, "visual_priority": 1 },
            { "id": "cargo_lower", "type": "event", "points": 1, "rp": 0, "visual_priority": 1 },
            { "id": "cargo_miss", "type": "event", "points": 0, "rp": 0, "visual_priority": 1 },
            { "id": "intake_jam", "type": "event", "points": 0, "rp": 0, "visual_priority": 2 },
        ],
        "endgame": [
            { "id": "climb_time", "type": "duration" },
            { "id": "climb_low", "type": "event", "points": 4, "rp": 0 },
            { "id": "climb_mid", "type": "event", "points": 6, "rp": 0 },
            { "id": "climb_high", "type": "event", "points": 10, "rp": 0 },
            { "id": "climb_traversal", "type": "event", "points": 15, "rp": 0 },
        ],
        "postgame": [
            { "id": "climb", "type": "selector", "options": ["No Climb", "Low", "Medium", "High", "Traversal"], "options_values": [0, 4, 6, 10, 15], "label": "Climb" },
            { "id": "cargo_bonus", "type": "toggle", "rp": 1 },
            { "id": "comments", "type": "text-box", "label": "Extra comments" },
        ],
        "results": [
            "points",
            "rp",
            "penalty",
            "taxi",
            "cargo",
            "hangar",
        ]
    }
};

const requestListener = function (req, res) {

    //Cors stuff
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Headers', '*');
    res.setHeader('Access-Control-Allow-Methods', '*');

    //Temporary before it can be selected in the app.
    const season_config = rapid_react_config;
    const event = "state";

    if(req.url == "/config/scouting") {
        res.writeHead(200);
        res.end(JSON.stringify({
            "pit_scouting": season_config.pit_scouting,
            "match_scouting": season_config.match_scouting,
        }));
        return;
    }

    if(req.url == "/config/scouting") {
        res.writeHead(200);
        res.end(JSON.stringify({
            "pit_scouting": season_config.pit_scouting,
            "match_scouting": season_config.match_scouting,
        }));
        return;
    }

    res.writeHead(200);
    res.end('Hello, World!');
}

const server = http.createServer(requestListener);
server.listen(8080);