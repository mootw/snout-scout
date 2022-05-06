
const http = require('http');
const fs = require('fs');


let database = JSON.parse(fs.readFileSync('database.json'));

function write () {
    console.log(JSON.stringify(database));
    fs.writeFileSync('database.json', JSON.stringify(database));
}

console.log(database);


const rapid_react_config = {
    "season": "Rapid React",
    "pit_scouting": {
        "survey": [
            { "id": "auto_high", "type": "number", "label": "Cargo high in autonomous" },
            { "id": "auto_low", "type": "number", "label": "Cargo low in autonomous" },
            { "id": "teleop_high", "type": "number", "label": "Cargo high in teleop" },
            { "id": "teleop_low", "type": "number", "label": "Cargo low in teleop" },
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

    console.log(`request made ${req.url}`);

    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Headers', '*');
    res.setHeader('Access-Control-Allow-Methods', '*');
    res.setHeader('Access-Control-Request-Method', '*');

    if(req.method == "OPTIONS") {
        res.writeHead(200);
        res.end();
        return;
    }

    //Temporary before it can be selected in the app.
    const season_config = rapid_react_config;
    const event = "state";

    const eventData = database.events[event];

    if(req.url == "/config/scouting") {
        res.writeHead(200);
        res.end(JSON.stringify(season_config));
        return;
    }

    if(req.url == "/teams") {
        res.writeHead(200);
        //Array of team numbers
        res.end(JSON.stringify(eventData.teams));
        return;
    }

    if(req.url == "/pit_scout") {
        if(req.method == "POST") {
            const data = JSON.parse(req.headers.jsondata);
            eventData.pit_scouting[data.team.toString()] = data;
            write();
            res.writeHead(200);
            res.end();
            return;
        }
        if(req.method == "GET") {
            const data = eventData.pit_scouting[req.headers.team];
            if(data == undefined) {
                res.writeHead(404);
                res.end();
                return;
            }
            res.writeHead(200);
            //Team must be a string
            res.end(JSON.stringify(data));
            return;
        }
        
    }

    res.writeHead(200);
    res.end('Hello, World!');
}

const server = http.createServer(requestListener);
server.listen(8080);