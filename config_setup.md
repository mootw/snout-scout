# Event setup
Right now there is no way to create a new event on the server from the app. The event needs to be created on the server as a new file in the events directory (and then the server needs to be restarted).


> This file does not automatically generate/update from the schema. However the latest schema is always defined in [snout_db](snout_db/)


## event.json
The database file is an object with these properties:
```json
{
    "config": {},
    "teams": [],
    "matches": {},
    "pitscouting": {},
}
```


## config
All can be left empty except for config which contains these properties:
```json
{
    //Name of the event being recorded
    "name": String,
    //season year (determines field image)
    "season": int,
    //tba event ID (key is stored on server)
    "tbaEventId": String?,
    //If the field is mirrored or rotated
    "fieldStyle": FieldStyle,
    //YOUR team number
    "team": int,
    //Survey for pitscouting
    "pitscouting": List<SurveyItem>[],
    "matchscouting": MatchScouting {
        //Event buttons in the match recording like "Intake" or "fumble"
        "events": List<MatchEventConfig>[],
        //Processes that run to calculate anything from just displaying the number of an event, to calculating the score that team had, to calculating a teams pickability based on the match performance.
        "processes": List<MatchResultsProcess>[],
        //Survey for post game just like pit scouting except best used for things like climbing level, or whether they played defense.
        "postgame": List<SurveyItem>[],
        //Scoring is used to record match data rather than per robot data. In the future this could be expanded to include final scoring (through API) or match setup details.
        "scoring": List<String>[]
    },
}
```

## SurveyItem
`id "robot_picture" is used for full robot pictures in the app.`
```json
{
    //Must be unique, and is used to idenfity this item
    "id": String,
    //Label displayed in app
    "label" String,
    //whether it is a selector, picture, toggle, number, or text input
    "type": SurveyItemType,
    //required for selector type
    "options" List<String>?
}
```

## MatchEventConfig
This is something that can happen to or by a robot in a match
`id "robot_position" is reserved for robot position events when tapping on the map.`
```json
{
    //Must be unique, and is used to idenfity this item
    "id": String,
    //Label displayed in app
    "label" String,
    //hex color for use in the UI
    "color": String?,
}
```

## MatchResultsProcess
See [matchresultprocess.md](matchresultprocess.md) for how to create an expression and the syntax.
```json
{
    //Must be unique, and is used to idenfity this item
    "id": String,
    //Label displayed in app
    "label" String,
    //Math expression that calculates this value
    "expression": String?,
}
```