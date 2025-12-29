Data schema for snout-scout

to rebuild the generated classes use: `dart run build_runner build`

`dart doc .`

TODO include the dart docs in the server docker and have the server serve the docs for clients?

use https://dart.dev/tools/dart-doc to generate docs

---

# SnoutDB

SnoutDB is a chain of Transactions. Each authorized public key can append Transactions to the chain.
This architecture allows for client-to-client updates and ensures a consistent state.

Nearly everything is defined as a dataItem. A data item is essentially a key-value item tied to a parent "entity"
For example, a specific team could be an entity, and each kv would would be a DataItem
/team/6749:
- team_name: tERAbytes
- robot_picture: .image_bytes.

DataItems are unique on their author, parent, and id.
This allows for each public key (scout) to submit their own separate feedback items


## Data Item Objects
Team - DataItems per Team
Match - DataItems per Match
MatchTrace - Timeline Trace of a robot and actions during match
MatchSurvey - DataItems of robot performance per match



## Data Items
EventConfig - utf8 encoded JSON
RobotTrace - utf8 encoded JSON
DataPoint - encoded defined by the 


## Messages

```
// enum TransactionType {

//   /// Updates a pubkey alias (pubkey, newAlias).
//   writeKeyAlias(3),




//   /// adds match results to a match (or null)
//   writeMatchResults(24);


```





