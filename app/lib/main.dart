import 'dart:convert';

import 'package:app/api.dart';
import 'package:app/screens/analysis.dart';
import 'package:app/screens/matches_page.dart';
import 'package:app/screens/teams_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snout_db/event/frcevent.dart';
import 'package:snout_db/patch.dart';
import 'package:snout_db/snout_db.dart';

void main() async {
  runApp(const MyApp());
}

Future<String> getServer() async {
  var prefs = await SharedPreferences.getInstance();
  String result = prefs.getString("server") ?? "http://localhost:6749";
  return result;
}

Future setServer(String newServer) async {
  var prefs = await SharedPreferences.getInstance();
  prefs.setString("server", newServer);
  await snoutData.loadData();
}

class SnoutScoutData {
  List<String> get events => db?.events.keys.toList() ?? [];
  String? selectedEventID;

  String? serverURL;

  Season? season;
  SnoutDB? db;

  FRCEvent get currentEvent => db!.events[selectedEventID]!;

  Future loadData() async {
    serverURL = await getServer();

    try {
      var data = await apiClient.get(Uri.parse("$serverURL/season"));
      season = Season.fromJson(jsonDecode(data.body));
    } catch (e, s) {
      print(e);
      print(s);
    }

    try {
      var data = await apiClient.get(Uri.parse("$serverURL/data"));
      db = SnoutDB.fromJson(jsonDecode(data.body));
      selectedEventID = db!.events.keys.first;
    } catch (e, s) {
      print(e);
      print(s);
    }
  }


  //Writes a patch to local disk and submits it to the server.
  Future addPatch (Patch patch) async {
    var res = await apiClient.put(
      Uri.parse("${await getServer()}/data"),
      body: jsonEncode(patch));
    
    if(res.statusCode == 200) {
      //This was sucessful
      return true;
    }
    snoutData.db = patch.patch(snoutData.db!);
  }

}

var snoutData = SnoutScoutData();

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
      title: 'Flutter Demo',
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

  bool isLoaded = false;

  @override
  void initState() {
    super.initState();
    () async {
      await snoutData.loadData();
      setState(() {
        isLoaded = true;
      });
    }();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isLoaded == false
            ? Text("Loading")
            : DropdownButton<String>(
                onChanged: (value) {
                  setState(() {
                    snoutData.selectedEventID = value;
                  });
                },
                value: snoutData.selectedEventID,
                items: snoutData.events
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
      ),
      body: isLoaded == false
          ? CircularProgressIndicator.adaptive()
          : [
              AllMatchesPage(),
              AllTeamsPage(),
              Text("Display a spreadsheet like table with every metric (including performance metrics for ranking like win-loss) and allow sorting and filtering of the data"),
              AnalysisPage(),
            ][_currentPageIndex],
      drawer: Drawer(
        child: ListView(children: [
          SizedBox(height: 32),
          ListTile(
            title: Text("Config"),
          ),
          ListTile(
            title: Text("Server"),
            subtitle: FutureBuilder<String>(
                future: getServer(),
                builder: (BuildContext context, var snapshot) {
                  if (snapshot.hasData) {
                    return Text(snapshot.data!);
                  }
                  return Text("Loading");
                }),
            trailing: IconButton(
              icon: Icon(Icons.edit),
              onPressed: () async {
                var result = await showStringInputDialog(
                    context, "Server", await getServer());
                if (result != null) {
                  await setServer(result);
                  setState(() {});
                }
              },
            ),
          ),
          ListTile(
            title: Text("Season"),
            subtitle: Text(snoutData.season?.season ?? "not connected"),
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
            icon: Icon(Icons.bookmark_border),
            label: 'Matches',
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
