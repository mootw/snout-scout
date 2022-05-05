import 'package:flutter/material.dart';

const TextStyle whiteText = TextStyle(color: Colors.white70);

class MatchCard extends StatelessWidget {
  const MatchCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: () {},
        child: Column(
          children: [
            Text("Qualification 1"),
            SizedBox(height: 4),
            Row(
              children: [
                Column(
                  children: [
                    Text("10:38 AM"),
                  ],
                ),
                Column(
                  children: [
                    Container(
                      color: Colors.redAccent,
                      child: Row(children: [
                        TextButton(
                            onPressed: () {},
                            child: Text("6749", style: whiteText)),
                        TextButton(
                            onPressed: () {},
                            child: Text("6749", style: whiteText)),
                        TextButton(
                            onPressed: () {},
                            child: Text("6749", style: whiteText)),
                        Container(
                          alignment: Alignment.center,
                          width: 52,
                          child: Text(
                            "69",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ]),
                    ),
                    Container(
                      color: Colors.blueAccent,
                      child: Row(children: [
                        TextButton(
                            onPressed: () {},
                            child: Text("6749", style: whiteText)),
                        TextButton(
                            onPressed: () {},
                            child: Text("6749", style: whiteText)),
                        TextButton(
                            onPressed: () {},
                            child: Text("6749", style: whiteText)),
                        Container(
                          alignment: Alignment.center,
                          width: 52,
                          child: Text(
                            "420",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ),
                      ]),
                    ),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
