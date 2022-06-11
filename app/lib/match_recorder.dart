import 'dart:async';

import 'package:app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';

class MatchRecorderPage extends StatefulWidget {
  const MatchRecorderPage({Key? key}) : super(key: key);

  @override
  State<MatchRecorderPage> createState() => _MatchRecorderPageState();
}

class _MatchRecorderPageState extends State<MatchRecorderPage> {

  List<Widget> timeline = [
    Container(
      width: double.infinity,
      height: 50,
      alignment: Alignment.center,
    child: Text("Start of timeline")
    )
    ];


  @override
  void initState() {
    super.initState();

    Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        timeline.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text("${timer.tick}"),
              IconButton(
              onPressed: () {

              },
              icon: Icon(Icons.cancel)),
            ],
          ));
          timeline.add(Divider(height: 0));
      });
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Team 1234 - Teleop - 212"),
      ),
      body: Flex(
        direction: Axis.vertical,
        children: [
          Expanded(
            child: ListView(
              reverse: true,
              children: timeline.reversed.toList(),
            ),
          ),
          Container(
            color: Colors.black,
            padding: EdgeInsets.only(left: 8, right: 8),
            width: double.infinity,
            child: Image.network("${snoutData.serverURL}/field_map.png", height: 200),
          ),


          Wrap(
              children: [
                for(int i = 0; i < 9; i++)
                  SizedBox(
                    height: 90,
                    width: MediaQuery. of(context). size. width/3,
                    child: Card(
                      child: MaterialButton(
                        onPressed: () {
                          
                        },
                        child: Text("Event button name"),
                      ),
                    ),
                  ),
              ],
            ),

          // Container(
          //   height: 200,
          //   child: Table(
          //     children: <TableRow>[
          //       TableRow(children: [
          //         MaterialButton(
          //             child: Text("Event Button Name"), onPressed: () {}),
          //         MaterialButton(
          //             child: Text("Event Button Name"), onPressed: () {}),
          //         MaterialButton(
          //             child: Text("Event Button Name"), onPressed: () {}),
          //       ]),
          //       TableRow(
          //         children: [
          //         MaterialButton(
          //             child: Text("Event Button Name"), onPressed: () {}),
          //         MaterialButton(
          //             child: Text("Event Button Name"), onPressed: () {}),
          //         MaterialButton(
          //             child: Text("Event Button Name"), onPressed: () {}),
          //       ]),
          //       TableRow(children: [
          //         MaterialButton(
          //             child: Text("Event Button Name"), onPressed: () {}),
          //         MaterialButton(
          //             child: Text("Event Button Name"), onPressed: () {}),
          //         MaterialButton(
          //             child: Text("Event Button Name"), onPressed: () {}),
          //       ]),
          //       TableRow(children: [
          //         MaterialButton(
          //             child: Text("Event Button Name"), onPressed: () {}),
          //         MaterialButton(
          //             child: Text("Event Button Name"), onPressed: () {}),
          //         MaterialButton(
          //             child: Text("Event Button Name"), onPressed: () {}),
          //       ])
          //     ],
          //   ),
          // ),
          Container(
            margin: const EdgeInsets.all(16),
            // color: Colors.amber,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
                          content: Text("Long press to move to next section")));
                    },
                    onLongPress: () {},
                    //Start recording
                    //Teleop
                    //Finish recording
                    child: Text("Next segment: Start recording"),
                  ),
                ]),
          ),
        ],
      ),
    );
  }
}


/*
MaterialButton(
                  child: Text("Event Button Name"),
                  onPressed: () {
                    
                }),
                MaterialButton(
                  child: Text("Event Button Name"),
                  onPressed: () {
                    
                }),
                MaterialButton(
                  child: Text("Event Button Name"),
                  onPressed: () {
                    
                }),
                MaterialButton(
                  child: Text("Event Button Name"),
                  onPressed: () {
                    
                }),
                MaterialButton(
                  child: Text("Event Button Name"),
                  onPressed: () {
                    
                }),
                MaterialButton(
                  child: Text("Event Button Name"),
                  onPressed: () {
                    
                }),
                MaterialButton(
                  child: Text("Event Button Name"),
                  onPressed: () {
                    
                }),
*/