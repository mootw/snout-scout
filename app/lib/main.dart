import 'dart:convert';

import 'package:app/api.dart';
import 'package:app/screens/analysis.dart';
import 'package:app/screens/matches_page.dart';
import 'package:app/screens/teams_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snout_db/event/frcevent.dart';
import 'package:snout_db/patch.dart';
import 'package:snout_db/snout_db.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

late String serverURL;

Future setServer(String newServer) async {
  var prefs = await SharedPreferences.getInstance();
  prefs.setString("server", newServer);
  serverURL = newServer;
}

void main() async {
  //Load data and initialize the app
  var prefs = await SharedPreferences.getInstance();
  serverURL = prefs.getString("server") ?? "http://localhost:6749";

  Season season;
  SnoutDB db;
  bool connected = false;

  print(serverURL);

  try {
    //Load season config from server
    var data = await apiClient.get(Uri.parse("$serverURL/season"));
    season = Season.fromJson(jsonDecode(data.body));
    prefs.setString("season", data.body);

    //Load database from server
    var dbData = await apiClient.get(Uri.parse("$serverURL/data"));
    db = SnoutDB.fromJson(jsonDecode(dbData.body));
    prefs.setString("db", dbData.body);
  } catch (e) {
    connected = false;
    try {
      //Load from cache
      String? seasonCache = prefs.getString("season");
      season = Season.fromJson(jsonDecode(seasonCache!));
      String? dbCache = prefs.getString("db");
      db = SnoutDB.fromJson(jsonDecode(dbCache!));
      print("got data from cache");
    } catch (e) {
      //Really bad we have no cache or server connection
      runApp(SetupApp());
      return;
    }
  }

  SnoutScoutData data = SnoutScoutData(season, db, connected);

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
      home: SetupAppScree(),
    );
  }
}

class SetupAppScree extends StatelessWidget {
  const SetupAppScree({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Error Connecting"),
        ),
        body: ListView(
          children: [
            ListTile(
              title: Text("Server"),
              subtitle: Text(serverURL),
              trailing: IconButton(
                icon: Icon(Icons.edit),
                onPressed: () async {
                  print("pressed");
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


class SnoutScoutData extends ChangeNotifier {
  List<String> get events => db.events.keys.toList();

  late String selectedEventID;

  Season season;
  SnoutDB db;
  bool connected;

  FRCEvent get currentEvent => db.events[selectedEventID]!;

  SnoutScoutData(this.season, this.db, this.connected) {
    selectedEventID = db.events.keys.first;

    late WebSocketChannel channel;
    channel = WebSocketChannel.connect(
        Uri.parse('ws://${Uri.parse(serverURL).host}:${Uri.parse(serverURL).port}/patchlistener'));
    channel.stream.listen((event) async {
      print("new patch, applying to local db");
      db = Patch.fromJson(jsonDecode(event)).patch(db);

      final prefs = await SharedPreferences.getInstance();
      //Save the database to disk
      prefs.setString("db", jsonEncode(db));

      notifyListeners();
    });


  }

  //Writes a patch to local disk and submits it to the server.
  Future addPatch(Patch patch) async {
    var res = await apiClient.put(Uri.parse("$serverURL/data"),
        body: jsonEncode(patch));

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
    return Consumer<SnoutScoutData>(builder: (context, snoutData, child) {
      return Scaffold(
        appBar: AppBar(
          title: DropdownButton<String>(
            onChanged: (value) {
              setState(() {
                snoutData.selectedEventID = value!;
              });
            },
            value: snoutData.selectedEventID,
            items:
                snoutData.events.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ),
        body: [
          AllMatchesPage(),
          AllTeamsPage(),
          Text(
              "Display a spreadsheet like table with every metric (including performance metrics for ranking like win-loss) and allow sorting and filtering of the data"),
          AnalysisPage(),
        ][_currentPageIndex],
        drawer: Drawer(
          child: ListView(children: [
            ListTile(
              title: Text("Server"),
              subtitle: Text(serverURL),
              trailing: IconButton(
                icon: Icon(Icons.edit),
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
              title: Text("Season Config"),
              subtitle: Text(snoutData.season.season),
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
          destinations: [
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
