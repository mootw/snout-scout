# Docs
[scouting](scouting.md)

[config_setup](config_setup.md)

[matchresultprocess](matchresultprocess.md)

# About

Snout Scout is designed to make data work for you! Created and maintained by a team 6749 alumni, it is a source available all-in-one scouting solution that easily works for any year's game with just a json config file!


## Design Goals:
- make scouting have real time impact for match planning with automated digests.
- game agnostic; the app is fully configurable using a json file.
- device agnostic; PWA first with native apps for all platforms via Flutter
- FULL offline support (devices could hypothetically share data peer to peer)
- easy export of data into multiple formats like csv and json
- cryptography ensures data integrity
- Connect to the TBA API to autofill data like event schedules and match results (including support for year specific data mapping).
- no data loss
    - client saves all data locally until it can sync
    - Append only database with cryptographically signed messages
- strong separation between live stats (like ranking position/pick lists) and facts (like scouting match data)

- internet connection is assumed at >= 30KB/s (~400ms ping; <10% packet loss); and will provide a good experience
- use standardized technologies like Cbor for stability and portability. take advantage of novel techniques where value can be added

## Snout-scout is NOT designed to:
- track official standings or scores directly (official scores are linked if TBA event key is provided)
- analyse multiple events at once (multiple events can be queried at the server level)
- retain compatibility with previous year data (there is no obligation for backwards compatibility)
- have **extensive** security controls. a cryptographically authenticated user is assumed to be non-malicious and trusted, there is not validation of timestamps, IDs, or other information sent from clients.


# Data Size Estimate
Snout Scout stores all data in a single Cbor file. Here is an approximate breakdown of the rough **DISK** size of the a database file including some of the parts. This is an estimate and real world results will vary.

A typical event with 1 image per team will be about 2-4MB.

Message Sizes:
- Signed messages are typically ~250 bytes (including signature headers)
- Images are typically 30-50KB
- Config messages are at lease Image sizeed; as they contain the base64 encoded field image. Frequently modifying the config should be avoided!


# how TBA is used
the tba api is used to automate parts of scouting; functioning as an 'autofill service'.

the current architecture involves the client device directly making api requests to
TBA. at the moment, the secret key is distributed through the event config of a scouting
file. for obvious reasons this is not ideal, since it puts secrets in a database that
eventually might have access policies or potentially gets distributed outside of a team.
this could cause a secret leak; however, i am also lazy and do not want to implement a
spearate channel to distribute the secret to client devices, ideally the server distributes
the tba api key (the server cannot proxy because the client must be able to do all functions without a server).
encryption may be used in the future

# Example images (as of Feb 2024)

<img src="schedule_page.png" width="400">
<img src="team_list.png" width="400">
<img src="team_page.png" width="400">
<img src="match_page.png" width="400">
<img src="analysis.png" width="400">
<img src="boxplot.png" width="400">
<img src="table.png" width="400">