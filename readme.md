# About
## Design Goals:
- make scouting have real time impact for match planning with completely automated digests.
- game agnostic; the app is fully configurable using a json file (available in the UI)
- all data processing is/can be done on client for offline support
- server only handles authentication/autorizaton (TBD) and data handling.
- data server read/write API
- easy import and export of each event into multiple formats like csv and json
- Connect to the FRC API to populate event schedules (and results?)
- heavily normalized database
- client saves patches (changes) locally until it can sync with the server

## Snout-scout is NOT designed to:
- track standings or scores directly (official scores are linked if TBA event key is provided)
- analyse multiple events at once (multiple events can be queried at the server level)
- retain compatibility with older versions
- sync data between multiple clients peer-to-peer


# Known Issues
- Emojis render in black and white due to canvaskit https://github.com/flutter/flutter/issues/119536 https://stackoverflow.com/questions/75439788/flutter-web-shows-emojis-in-blackwhite