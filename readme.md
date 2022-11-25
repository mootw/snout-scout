Design Goals:
- make scouting have real time impact for match planning with completely automated digests.
- game agnostic; the app is fully configurable using a json file (available in the UI)
- all data processing is/can be done on client for offline support
- server only handles autorizaton (TBD) and data handling.
- data server read/write API
- easy import and export of each event into multiple formats like csv and json
- Connect to the FRC API to populate event schedules
- heavily normalized database
- client saves patches (changes) locally until it can sync with the server

Snout-scout is NOT designed to:
- check standings or scores directly
- analyse multiple events at once (multiple events can be queried at the server level)
- retain compatibility with older versions
- sync data between multiple clients peer-to-peer