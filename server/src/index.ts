import * as fs from "fs";
import * as http from "http";
import { DataStore, MatchResults, MatchTimeline, PitSurveyResult } from "./database";
import { PitSurveyItem, Season } from "./season";

//used to warn about multiple people editing the same document.
//Format is key: time
let editLocks = {};

//Get list of seasons and load the config
const season: Season = JSON.parse(fs.readFileSync(`./season.json`).toString());
console.log(season);

let database: DataStore|undefined;
//Load season databases
if (fs.existsSync(`./database.json`)) {
    database = JSON.parse(fs.readFileSync(`./database.json`).toString());
} else {
    database = {
        version: 1,
        events: {},
    };
}

//Saves databases to disk
function write() {
    fs.writeFileSync(`./database.json`, JSON.stringify(database));
    console.log(`wrote database`);
}

console.log(database);

const requestListener = async function (req, res) {

    console.log(`request made ${req.url}`);

    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Headers', '*');
    res.setHeader('Access-Control-Allow-Methods', '*');
    res.setHeader('Access-Control-Request-Method', '*');

    if (req.method == "OPTIONS") {
        res.writeHead(200);
        res.end();
        return;
    }

    console.log(editLocks);

    //Returns true if lock has been set within ttl, false if lock is not set or expired.
    if (req.url === "/edit_lock") {
        if (req.method === "GET") {
            var value = editLocks[req.headers.key];
            if (value !== undefined) {
                //300 seconds
                if (Date.now() - value <= 1000 * 300) {
                    res.writeHead(200);
                    res.end("true");
                    return;
                }
            }
            res.writeHead(200);
            res.end("false");
            return;
        }
        if (req.method === "POST") {
            editLocks[req.headers.key] = Date.now();
            res.writeHead(200);
            res.end();
            return;
        }
        if (req.method === "DELETE") {
            delete editLocks[req.headers.key];
            res.writeHead(200);
            res.end();
            return;
        }
    }

    if (req.url === "/field_map.png") {
        fs.readFile("field_map.png", function (err, data) {
            if (err) {
                res.writeHead(404);
                res.end(JSON.stringify(err));
                return;
            }
            res.writeHead(200);
            res.end(data);
        });
        return;
    }

    if (req.url == "/events") {
        res.writeHead(200);
        res.end(JSON.stringify(Object.keys(database.events)));
        return;
    }

    if (req.url == "/config") {
        res.writeHead(200);
        res.end(JSON.stringify(season));
        return;
    }

    //Temporary before it can be selected in the app.
    const event = req.headers.event;

    const eventData = database.events[event];

    //TODO sort matches by their scheduled_time

    if (event === undefined) {
        res.writeHead(403);
        res.end('No event defined and it is required');
        return;
    }


    if (req.url == "/teams") {
        res.writeHead(200);
        //Array of team numbers
        res.end(JSON.stringify(eventData.teams));
        return;
    }

    if (req.url == "/matches") {
        res.writeHead(200);
        //Array of team numbers
        const team_filter = req.headers.team;
        //Create new array to modify
        let matches = eventData.matches.slice();
        if (team_filter != undefined) {
            matches = matches.filter(match => [...match.blue, ...match.red].includes(+team_filter));
        }

        console.log(matches);

        res.end(JSON.stringify(matches));
        return;
    }

    //Returns one match
    if (req.url == "/match") {
        res.writeHead(200);
        //Array of team numbers
        const id = req.headers.id;
        //Create new array to modify
        for(const match of eventData.matches) {
            if(match.id === id) {
                res.end(JSON.stringify(match));
                return;
            }
        }
        //Not found
        res.writeHead(404);
        res.end();
        return;
    }

    if (req.url == "/match_results") {
        if (req.method === "POST") {
            //Submit match results.
            //Get match data from query
            const data: MatchResults = JSON.parse(req.headers.jsondata);
            const id: string = req.headers.id;
            //Filter only matches that are not the same number and section.
            for(let i = 0; i < eventData.matches.length; i++) {
                if(eventData.matches[i].id === id) {
                    eventData.matches[i].results = data;
                }
            }
            write();
            res.writeHead(200);
            res.end();
            return;
        }
    }

    if (req.url == "/match_timeline") {
        if (req.method === "POST") {
            //Submit match results.
            //Get match data from query
            const data: MatchTimeline = JSON.parse(req.headers.jsondata);
            const id = req.headers.id;
            const team = req.headers.team;
            //Filter only matches that are not the same number and section.
            for(let i = 0; i < eventData.matches.length; i++) {
                if(eventData.matches[i].id === id) {
                    eventData.matches[i].timelines[team] = data;
                }
            }
            write();
            res.writeHead(200);
            res.end();
            return;
        }
    }

    if (req.url == "/pit_scout") {
        if (req.method == "POST") {
            const data: PitSurveyResult = JSON.parse(req.headers.jsondata);
            eventData.pit_scouting[data.team.toString()] = data;
            write();
            res.writeHead(200);
            res.end();
            return;
        }
        if (req.method == "GET") {
            const data = eventData.pit_scouting[req.headers.team];
            if (data == undefined) {
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
server.listen(6749);
