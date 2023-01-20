# About
## Design Goals:
- make scouting have real time impact for match planning with completely automated digests.
- game agnostic; the app is fully configurable using a json file (available in the UI)
- all data processing is/can be done on client for offline support
- server only handles autorizaton (TBD) and data handling.
- data server read/write API
- easy import and export of each event into multiple formats like csv and json
- Connect to the FRC API to populate event schedules (and results?)
- heavily normalized database
- client saves patches (changes) locally until it can sync with the server

## Snout-scout is NOT designed to:
- check standings or scores directly
- analyse multiple events at once (multiple events can be queried at the server level)
- retain compatibility with older versions
- sync data between multiple clients peer-to-peer


# TODO:
- [ ] Add creating a new event file in client
- [ ] Add available events query??
- [ ] Client stores all year's maps; and loads the one based on the season config.
- [ ] Add authentication to server and client
- [ ] Add raw data export to client (aka the json database)
- [ ] Add csv export for tables in client
- [ ] Add coloring to events for event recording
- [ ] Add saving patches in client storage until there is a connection to the server
- [ ] re-order the pages to make more sense
- [ ] Add sorting to **text** cells in the data-view page