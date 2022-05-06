import 'package:app/api.dart';
import 'package:app/data/scouting_config.dart';
import 'package:app/matches_page.dart';
import 'package:app/teams_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

Future<String> getServer() async {
  var prefs = await SharedPreferences.getInstance();
  String result = prefs.getString("server") ?? "";
  return result;
}

Future setServer(String newServer) async {
  var prefs = await SharedPreferences.getInstance();
  prefs.setString("server", newServer);
  await snoutData.loadConfig();
}

Future<String> getName() async {
  var prefs = await SharedPreferences.getInstance();
  String result = prefs.getString("name") ?? "guest";
  return result;
}

Future setName(String newName) async {
  var prefs = await SharedPreferences.getInstance();
  prefs.setString("name", newName);
}

class SnoutScoutData {
  int currentEventId = 0;

  ScoutingConfig? scoutingConfig;

  Future loadConfig() async {
    try {
      var data = await apiClient
          .get(Uri.parse("${await getServer()}/config/scouting"));
      scoutingConfig = scoutingConfigFromJson(data.body);
    } catch (e, s) {
      print(e);
      print(s);
    }
  }
}

var snoutData = SnoutScoutData();

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.dark(),
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
  void initState() {
    super.initState();
    getStuff();
  }

  void getStuff() async {
    print("load data");
    await snoutData.loadConfig();
    setState(() {});
    print("loaded data");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("snout scout"),
      ),
      body: [
        Container(),
        AllTeamsPage(),
        AllMatchesPage(),
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
            title: Text("Connection Status"),
            subtitle: Text("Connected (11:10 PM)"),
          ),
          ListTile(
            title: Text("Name"),
            subtitle: FutureBuilder<String>(
                future: getName(),
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
                    context, "Name", await getName());
                if (result != null) {
                  await setName(result);
                  setState(() {});
                }
              },
            ),
          ),
          ListTile(
            title: Text("Season"),
            subtitle: Text("RapidReact"),
          ),
          ListTile(
            title: Text("Event"),
            subtitle: Text("State"),
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
            selectedIcon: Icon(Icons.view_timeline),
            icon: Icon(Icons.view_timeline_outlined),
            label: 'Timeline',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.people),
            icon: Icon(Icons.people_alt_outlined),
            label: 'Teams',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            label: 'Matches',
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
