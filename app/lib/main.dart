import 'dart:convert';

import 'package:app/api.dart';
import 'package:app/screens/analysis.dart';
import 'package:app/screens/datapage.dart';
import 'package:app/screens/edit_json.dart';
import 'package:app/screens/matches_page.dart';
import 'package:app/screens/teams_page.dart';
import 'package:flutter/material.dart';
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
    var data = await apiClient.get(Uri.parse("$serverURL"));
    event = FRCEvent.fromJson(jsonDecode(data.body));
    prefs.setString("$serverURL", data.body);
  } catch (e) {
    try {
      //Load from cache
      String? dbCache = prefs.getString("$serverURL");
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

  EventDB(this.db) {
    Uri serverUri = Uri.parse(serverURL);
    WebSocketChannel channel = WebSocketChannel.connect(Uri.parse(
        '${serverURL.startsWith("https") ? "wss" : "ws"}://${serverUri.host}:${serverUri.port}/listen/${serverUri.pathSegments[1]}'));

    channel.stream.listen((event) async {
      print("got notification");


      //REALLY JANK PING PONG SYSTEM THIS SHOULD BE FIXED!!!!
      if(event == "PING") {
        channel.sink.add("PONG");
        return;
      }

      db = Patch.fromJson(jsonDecode(event)).patch(db);
      final prefs = await SharedPreferences.getInstance();
      //Save the database to disk
      prefs.setString("db", jsonEncode(db));
      notifyListeners();
    });
  }

  //Writes a patch to local disk and submits it to the server.
  Future addPatch(Patch patch) async {
    var res =
        await apiClient.put(Uri.parse("$serverURL"), body: jsonEncode(patch));

    if (res.statusCode == 200) {
      //This was sucessful
      return true;
    }
    db = patch.patch(db);

    notifyListeners();
  }
}

//Set up theme
const primaryColor = Color.fromARGB(255, 49, 219, 43);
final darkScheme =
    ColorScheme.fromSeed(seedColor: primaryColor, brightness: Brightness.dark);
ThemeData defaultTheme =
    ThemeData.from(colorScheme: darkScheme, useMaterial3: true);

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

  @override
  Widget build(BuildContext context) {
    return Consumer<EventDB>(builder: (context, snoutData, child) {
      return Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: Text(snoutData.db.name),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.tonal(onPressed: () {
                      String url = Uri.parse(serverURL).pathSegments[1];
            
                      launchUrlString("https://www.thebluealliance.com/event/${url.substring(0, url.length-5)}#rankings");
                    }, child: const Text("Rankings")),
            ),
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
              title: const Text("Event Config"),
              subtitle: Text(snoutData.db.name),
              trailing: IconButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => JSONEditor(
                            validate: EventConfig.fromJson,
                            source: const JsonEncoder.withIndent("    ")
                                .convert(
                                    Provider.of<EventDB>(context, listen: false)
                                        .db
                                        .config),
                          ),
                        ));

                    if (result != null) {
                      Patch patch = Patch(
                          time: DateTime.now(), path: ['config'], data: result);
                      //Save the scouting results to the server!!
                      await snoutData.addPatch(patch);
                    }
                  },
                  icon: const Icon(Icons.edit)),
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
    });
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
