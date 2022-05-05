import 'package:app/api.dart';
import 'package:app/matches_page.dart';
import 'package:app/teams_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

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

  final pages = [
    Container(),
    AllTeamsPage(),
    AllMatchesPage(),
  ];

  @override
  void initState() {
    super.initState();
    getStuff();
  }

  void getStuff() async {
    var result = await apiClient.get(Uri.parse("http://localhost:8080/"));
    print(result.statusCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text("snout scout"),
      ),
      body: pages[_currentPageIndex],
      drawer: Drawer(
        child: ListView(children: [
          SizedBox(height: 32),
          ListTile(
            title: Text("Config"),
          ),
          ListTile(
            title: Text("Server"),
            subtitle: Text("snoutscout.xqkz.net"),
            trailing: IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {},
            ),
          ),
          ListTile(
            title: Text("Connection Status"),
            subtitle: Text("Connected (11:10 PM)"),
          ),
          ListTile(
            title: Text("Name"),
            subtitle: Text("spencer"),
            trailing: IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {},
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
