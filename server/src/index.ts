import * as fs from "fs";
import * as http from "http";
import { DataStore, FrcEvent, MatchResults, MatchTimeline, PitSurveyResult } from "./database";
import { editLock } from "./edit_lock";
import { PitSurveyItem, Season } from "./season";

//Get list of seasons and load the config
const season: Season = JSON.parse(fs.readFileSync(`./season.json`).toString());
console.log(season);

let database: DataStore | undefined;
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

    //Returns true if lock has been set within ttl, false if lock is not set or expired.
    if (req.url === "/edit_lock") {
        if (req.method === "GET") {
            if (editLock.get(req.headers.key)) {
                res.writeHead(200);
                res.end("true");
                return;
            }
            res.writeHead(200);
            res.end("false");
            return;
        }
        if (req.method === "POST") {
            editLock.set(req.headers.key);
            res.writeHead(200);
            res.end();
            return;
        }
        if (req.method === "DELETE") {
            editLock.clear(req.headers.key);
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
        res.end(JSON.stringify(getMatches(eventData, team_filter)));
        return;
    }

    //Returns one match
    if (req.url == "/match") {
        res.writeHead(200);
        //Array of team numbers
        const id = req.headers.id;
        const match = getMatch(eventData, id);
        if(match != undefined) {
            res.end(JSON.stringify(match));
            return;
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
            //assign the match results
            getMatch(eventData, id).results = data;
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
            //assign data
            getMatch(eventData, id).timelines[team] = data;
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


    if (req.url == "/timeline") {
        if (req.method == "GET") {

            const team_matches = getMatches(eventData, season.team);

            res.end(
                {
                    "event_match_delay": 123, //Minutes
                    "cards": [
                        {
                            "type": "match",
                            "id": "somematchidlol",
                        },
                        {
                            "type": "match",
                            "id": "somematchidlol2",
                        },
                        {
                            "type": "match",
                            "id": "somematchidlol3",
                        },
                        {
                            "type": "match",
                            "id": "somematchidlol4",
                        },
                    ],
                }
            );

        }
    }


    res.writeHead(200);
    res.end('Hello, World!');
}


function getMatches(eventData: FrcEvent, teamFilter: number) {
    //create new array to modify
    let matches = eventData.matches.slice();
    if (teamFilter != undefined) {
        matches = matches.filter(match => [...match.blue, ...match.red].includes(+teamFilter));
    }
    return matches;
}

function getMatch(eventData: FrcEvent, matchid: string) {
    for (const match of eventData.matches) {
        if (match.id === matchid) {
            return match;
        }
    }
}




const server = http.createServer(requestListener);
server.listen(6749);
