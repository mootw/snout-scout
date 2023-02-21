import 'dart:async';
import 'dart:convert';

import 'package:app/api.dart';
import 'package:app/helpers.dart';
import 'package:app/screens/analysis.dart';
import 'package:app/screens/datapage.dart';
import 'package:app/screens/edit_json.dart';
import 'package:app/screens/edit_schedule.dart';
import 'package:app/screens/local_patch_storage.dart';
import 'package:app/screens/matches_page.dart';
import 'package:app/screens/teams_page.dart';
import 'package:app/search.dart';
import 'package:download/download.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snout_db/config/eventconfig.dart';
import 'package:snout_db/event/frcevent.dart';
import 'package:snout_db/patch.dart';
import 'package:snout_db/snout_db.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:url_launcher/url_launcher_string.dart';

late String serverURL;

Future setServer(String newServer) async {
  var prefs = await SharedPreferences.getInstance();
  prefs.setString("server", newServer);
  serverURL = newServer;

  //Reset the last origin sync value
  prefs.remove("lastoriginsync");

  //Literally re-initialize the app when changing the server.
  main();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //Load data and initialize the app
  var prefs = await SharedPreferences.getInstance();
  serverURL = prefs.getString("server") ?? "http://localhost:6749";

  FRCEvent event;

  try {
    //Load season config from server
    var data = await apiClient.get(Uri.parse(serverURL));
    event = FRCEvent.fromJson(jsonDecode(data.body));
    prefs.setString(serverURL, data.body);
    prefs.setString("lastoriginsync", DateTime.now().toIso8601String());
  } catch (e) {
    try {
      //Load from cache
      String? dbCache = prefs.getString(serverURL);
      event = FRCEvent.fromJson(jsonDecode(dbCache!));
      print("got data from cache");
    } catch (e) {
      //Really bad we have no cache or server connection
      runApp(const SetupApp());
      return;
    }
  }

  EventDB data = EventDB(event);

  runApp(ChangeNotifierProvider(
    create: (context) => data,
    child: const MyApp(),
  ));
}

class SetupApp extends StatefulWidget {
  const SetupApp({super.key});

  @override
  State<SetupApp> createState() => _SetupAppState();
}

class _SetupAppState extends State<SetupApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snout Scout',
      theme: defaultTheme,
      home: const SetupAppScreen(),
    );
  }
}

class SetupAppScreen extends StatelessWidget {
  const SetupAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Error Connecting"),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text("Server"),
            subtitle: Text(serverURL),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                var result =
                    await showStringInputDialog(context, "Server", serverURL);
                if (result != null) {
                  await setServer(result);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EventDB extends ChangeNotifier {
  FRCEvent db;


  DateTime? lastOriginSync;
  bool connected = true;

  //This timer is set and will trigger a re-connect if a ping is not recieved
  //It will also
  //within a certain amount of time.
  Timer? connectionTimer;

  WebSocketChannel? channel;

  //Used in the UI to see failed and successful patches
  List<String> successfulPatches = <String>[];
  List<String> failedPatches = <String>[];

  void resetConnectionTimer() {
    connectionTimer?.cancel();
    connectionTimer = Timer(const Duration(seconds: 61), () {
      print("connection timer triggered");
      //No message has been recieved in 60 seconds, close down the connection.
      channel?.sink.close();
      connected = false;
    });
  }

  void reconnect() async {
    print("attempting a reconnection!");
    //Do not close the stream if it already exists idk how that behaves
    //it might reuslt in the onDone being called unexpetedly.
    Uri serverUri = Uri.parse(serverURL);
    channel = WebSocketChannel.connect(Uri.parse(
        '${serverURL.startsWith("https") ? "wss" : "ws"}://${serverUri.host}:${serverUri.port}/listen/${serverUri.pathSegments[1]}'));

    channel!.ready.then((_) {
      if(connected == false) {
        //Only do an origin sync if we were previouosly not connected
        //Since the db is syncronized before creating this object
        //we can assume that connection exists for the first reconnect
        //thus connected = true by default
        tryOriginSync();
      }
      connected = true;
      notifyListeners();
      resetConnectionTimer();
      print("On ready");
    });

    channel!.stream.listen((event) async {
      resetConnectionTimer();
      //REALLY JANK PING PONG SYSTEM THIS SHOULD BE FIXED!!!!
      if (event == "PING") {
        channel!.sink.add("PONG");
        return;
      }

      db = Patch.fromJson(jsonDecode(event)).patch(db);
      final prefs = await SharedPreferences.getInstance();
      //Save the database to disk
      prefs.setString("db", jsonEncode(db));
      notifyListeners();
    }, onDone: () {
      connected = false;
      notifyListeners();
      //Re-attempt a connection after a minute
      Timer(const Duration(seconds: 30), () {
        print("attempting to reconnect");
        if (connected == false) {
          reconnect();
        }
      });
    }, onError: (e) {
      print("On error");
      //Dont try and reconnect on an error
      print(e);
      notifyListeners();
    });
  }
  
  //Attempts to sync with the server
  Future tryOriginSync () async {
    print("Attempted origin sync");
    final prefs = await SharedPreferences.getInstance();
    try {
      //Load season config from server
      var data = await apiClient.get(Uri.parse(serverURL));
      db = FRCEvent.fromJson(jsonDecode(data.body));
      prefs.setString(serverURL, data.body);
      prefs.setString("lastoriginsync", DateTime.now().toIso8601String());
      lastOriginSync = DateTime.now(); //FOR easy UI update. This is slowly becoming spaghetti
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  EventDB(this.db) {
    reconnect();

    //Initialize the patches array to be used in the UI.
    () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      successfulPatches = prefs.getStringList("successful_patches") ?? [];
      failedPatches = prefs.getStringList("failed_patches") ?? [];
      lastOriginSync = DateTime.tryParse(prefs.getString("lastoriginsync") ?? "");
    }();
  }

  //Writes a patch to local disk and submits it to the server.
  Future addPatch(Patch patch) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      var res =
          await apiClient.put(Uri.parse(serverURL), body: jsonEncode(patch));
      if (res.statusCode == 200) {
        //This was successful
        successfulPatches = prefs.getStringList("successful_patches") ?? [];
        successfulPatches.add(jsonEncode(patch));
        prefs.setStringList("successful_patches", successfulPatches);
        //Remove it from the failed patches if it exists there
        if(failedPatches.contains(jsonEncode(patch))) {
          failedPatches.remove(jsonEncode(patch));
          prefs.setStringList("failed_patches", failedPatches);
        }
        //Apply the patch to the local only if it was successful!
        db = patch.patch(db);
        return true;
      } else {
        failedPatches = prefs.getStringList("failed_patches") ?? [];
        if (failedPatches.contains(jsonEncode(patch)) == false) {
          //Do not add the same patch multiple times into the failed patches!
          failedPatches.add(jsonEncode(patch));
        }
        prefs.setStringList("failed_patches", failedPatches);
      }
    } catch (e) {
      failedPatches = prefs.getStringList("failed_patches") ?? [];
      if (failedPatches.contains(jsonEncode(patch)) == false) {
        //Do not add the same patch multiple times into the failed patches!
        failedPatches.add(jsonEncode(patch));
      }
      prefs.setStringList("failed_patches", failedPatches);
    }
    notifyListeners();
  }

  //Clears all of the failed patches.
  Future clearFailedPatches () async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    failedPatches.clear(); //For UI update
    prefs.setStringList("failed_patches", []);
    notifyListeners();
  }

  //Clears all of the successful patches.
  Future clearSuccessfulPatches () async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    successfulPatches.clear(); //For UI update
    prefs.setStringList("successful_patches", []);
    notifyListeners();
  }

}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snout Scout',
      theme: defaultTheme,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentPageIndex = 0;

  PreferredSize? getErrorBar() {
    final data = context.read<EventDB>();

    if (data.failedPatches.isNotEmpty) {
      return PreferredSize(
        preferredSize: const Size.fromHeight(36),
        child: InkWell(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LocalPatchStorage(),
              )),
          child: Container(
              alignment: Alignment.center,
              width: double.infinity,
              height: 36,
              color: Colors.orange,
              child: Text(
                  "You have ${data.failedPatches.length} failed patches! Tap to see")),
        ),
      );
    }

    if (data.connected == false) {
      return PreferredSize(
        preferredSize: const Size.fromHeight(36),
        child: Container(
            alignment: Alignment.center,
            width: double.infinity,
            height: 36,
            color: Theme.of(context).colorScheme.errorContainer,
            child: const Text("No Live Connection to server!!!")),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<EventDB>();
    String? tbaKey = context.watch<EventDB>().db.config.tbaEventId;

    return Scaffold(
      appBar: AppBar(
        bottom: getErrorBar(),
        titleSpacing: 0,
        title: Text(data.db.config.name),
        actions: [
          if (tbaKey != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.tonal(
                  onPressed: () => launchUrlString(
                      "https://www.thebluealliance.com/event/$tbaKey#rankings"),
                  child: const Text("Rankings")),
            ),
          IconButton(
              onPressed: () {
                showSearch(context: context, delegate: SnoutScoutSearch());
              },
              icon: const Icon(Icons.search))
        ],
      ),
      body: [
        const AllMatchesPage(),
        const AllTeamsPage(),
        const DataTablePage(),
        const AnalysisPage(),
      ][_currentPageIndex],
      drawer: Drawer(
        child: ListView(children: [
          ListTile(
            title: const Text("Server"),
            subtitle: Text(serverURL),
            trailing: IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                var result =
                    await showStringInputDialog(context, "Server", serverURL);
                if (result != null) {
                  await setServer(result);
                  setState(() {});
                }
              },
            ),
          ),
          ListTile(
            title: const Text("Last Origin Sync"),
            subtitle: data.lastOriginSync == null ? const Text("Never") : Text(DateFormat.yMMMMEEEEd().add_Hms().format(data.lastOriginSync!)),
          ),
          ListTile(
            title: const Text("Local Patch Storage"),
            trailing: const Icon(Icons.data_object),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LocalPatchStorage(),
                  ));
            },
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: FilledButton(
                  onPressed: () {
                    final data = context.read<EventDB>().db;
                    final stream =
                        Stream.fromIterable(utf8.encode(jsonEncode(data)));
                    download(stream, '${data.config.name}.json');
                  },
                  child: const Text("Download Event Data to File")),
            ),
          ),
          const Divider(height: 64),
          ListTile(
            title: const Text("Event Config"),
            subtitle: Text(data.db.config.name),
            trailing: IconButton(
                onPressed: () async {
                  final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JSONEditor(
                          validate: EventConfig.fromJson,
                          source: const JsonEncoder.withIndent("    ")
                              .convert(context.read<EventDB>().db.config),
                        ),
                      ));

                  if (result != null) {
                    Patch patch = Patch(
                        time: DateTime.now(), path: ['config'], data: result);
                    //Save the scouting results to the server!!
                    await data.addPatch(patch);
                  }
                },
                icon: const Icon(Icons.edit)),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: FilledButton.tonal(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditSchedulePage(matches: data.db.matches),
                        ));
                  },
                  child: const Text("Edit Schedule")),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: FilledButton.tonal(
                  onPressed: () async {
                    final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JSONEditor(
                            validate: (item) {},
                            source: const JsonEncoder.withIndent("    ")
                                .convert(context.watch<EventDB>().db.teams),
                          ),
                        ));

                    if (result != null) {
                      Patch patch = Patch(
                          time: DateTime.now(), path: ['teams'], data: result);
                      //Save the scouting results to the server!!
                      await data.addPatch(patch);
                    }
                  },
                  child: const Text("Edit Teams")),
            ),
          ),
        ]),
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        selectedIndex: _currentPageIndex,
        destinations: const [
          NavigationDestination(
            selectedIcon: Icon(Icons.table_rows),
            icon: Icon(Icons.table_rows_outlined),
            label: 'Schedule',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.people),
            icon: Icon(Icons.people_alt_outlined),
            label: 'Teams',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.table_chart),
            icon: Icon(Icons.table_chart_outlined),
            label: 'Data',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.analytics),
            icon: Icon(Icons.analytics_outlined),
            label: 'Analysis',
          ),
        ],
      ),
    );
  }
}

Future<String?> showStringInputDialog(
    BuildContext context, String label, String currentValue) async {
  final myController = TextEditingController();
  myController.text = currentValue;
  return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(label),
          content: TextField(
            controller: myController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(null);
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                Navigator.of(context).pop(myController.text);
              },
            ),
          ],
        );
      });
}
