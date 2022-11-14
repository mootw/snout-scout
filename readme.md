Design Goals:
- game agnostic; the app is fully configurable using a json file
- all processing is done on client for full offline support
- server does no processing other than autorizaton
- data server read/write API
- easy import and export of each event into multiple formats like csv and json
- be extensible with add-on support like TBA for automatically populating data
- heavily normalized database
- match predictions (predict the results of a match that has not happened)
- alliance selection
- client saves patches (changes) locally until it can sync with the server

Snout-scout is NOT designed to:
- analyse multiple events at once (multiple events can be queried at the server level)
- retain compatibility with older versions
- sync data between multiple clients peer-to-peer