# About
## Design Goals:
- make scouting have real time impact for match planning with completely automated digests.
- game agnostic; the app is fully configurable using a json file (available in the UI)
- device agnostic. PWA first with native apps for all platforms via Flutter
- all data processing is/can be done on client for offline support
- export of each event into multiple formats like csv and json
- function in low bandwidth scenarios and provide reliable low latency sync to origin
- origin only handles authentication/autorizaton (TBD) and as the source of truth
- data server read/write API
- Connect to the TBA API to populate event schedules (and results?)
- client saves all data locally until it can sync with origin
- Single compact (mostly) readable data JSON file to allow for durable data. The structure is also fully typed and null safe.
- Sound null safety in the app and data for maximum reliability.

## Snout-scout is NOT designed to:
- track standings or scores directly (official scores are linked if TBA event key is provided)
- analyse multiple events at once (multiple events can be queried at the server level)
- retain compatibility with older versions
- sync data between multiple clients peer-to-peer due to generally requiring human interaction to sync and thus have high latency (>1hr).

# Known Issues
- Emojis render in black and white due to canvaskit https://github.com/flutter/flutter/issues/119536 https://stackoverflow.com/questions/75439788/flutter-web-shows-emojis-in-blackwhite


# Network/sync methodologies
## Origin on Internet - Direct
- All devices have an internet connection to an origin server
- Devices can sync anywhere
- Latency is determined by the reliability of internet at competition
- Devices with no mobile data coverage need to use a hotspot connection or only sync when wifi is avaiable (this could be as infrequent as once per day).
- NOTE: A hotspot device can be used to proxy the internet connection into a local area network to get results similar to Origin at Event.

## Origin at Event
- A local area network is set up at compeition and origin server is on that network.
- This is the most durable network setup but requires devices to tether to the network to update meaning higher latency.
- Only devices physically located near the origin can update with it.
