import 'package:app/api.dart';
import 'package:app/data/match_results.dart';
import 'package:app/data/matches.dart';
import 'package:app/data/season_config.dart';
import 'package:app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:intl/intl.dart';

Duration matchLength = const Duration(minutes: 2, seconds: 30);

class EditMatchResults extends StatefulWidget {
  final SeasonConfig config;
  final Match match;

  const EditMatchResults({required this.config, required this.match, Key? key})
      : super(key: key);

  @override
  State<EditMatchResults> createState() => _EditMatchResultsState();
}

class _EditMatchResultsState extends State<EditMatchResults> {
  final _form = GlobalKey<FormState>();

  DateTime matchEndTime = DateTime.now();

  final Map<String, TextEditingController> _red = {};
  final Map<String, TextEditingController> _blue = {};

  @override
  void initState() {
    super.initState();

    //Pre-fill result scores
    for (var resultValue in widget.config.matchScouting.results) {
      _red[resultValue] = TextEditingController();
      _blue[resultValue] = TextEditingController();
    }
  }

  //Converts text editing controller to number
  Map<String, double> _mapTo(Map<String, TextEditingController> input) {
    return input
        .map((key, value) => MapEntry(key, double.parse(input[key]!.text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () async {
                if (_form.currentState?.validate() ?? false) {
                  //Input is valid
                  //Construct match results object
                  MatchResults results = MatchResults(
                      scout: await getName(),
                      time: DateTime.now().toIso8601String(),
                      startTime:
                          matchEndTime.subtract(matchLength).toIso8601String(),
                      red: ResultsNumbers(values: _mapTo(_red)),
                      blue: ResultsNumbers(values: _mapTo(_blue)),
                    );

                  var result = apiClient.post(Uri.parse("${await getServer()}/match_results"), headers: {
                    "jsondata": matchResultsToJson(results),
                    "id": widget.match.id,
                  });
                  
                  Navigator.pop(context, true);
                }
              },
              icon: const Icon(Icons.save)),
        ],
        title:
            Text("Edit Match ${widget.match.section} ${widget.match.number}"),
      ),
      body: Form(
        key: _form,
        child: ListView(
          children: [
            ListTile(
              title: Text("Match End Time"),
              subtitle: Text(DateFormat.Hm().add_yMd().format(matchEndTime)),
              trailing: IconButton(
                icon: Icon(Icons.edit),
                onPressed: () async {
                  DateTime? d = await showDatePicker(
                      context: context,
                      firstDate: DateTime(1992),
                      lastDate: DateTime.now(),
                      initialDate: matchEndTime);
                  if (d != null) {
                    matchEndTime = DateTime(d.year, d.month, d.day,
                        matchEndTime.hour, matchEndTime.minute);
                  }

                  TimeOfDay? time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(
                          hour: matchEndTime.hour,
                          minute: matchEndTime.minute));
                  if (time != null) {
                    matchEndTime = DateTime(
                        matchEndTime.year,
                        matchEndTime.month,
                        matchEndTime.day,
                        time.hour,
                        time.minute);
                  }
                  setState(() {});
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Table(
                children: [
                  const TableRow(children: [
                    Text("Point type"),
                    Text("Blue"),
                    Text("Red"),
                  ]),
                  for (final item in widget.config.matchScouting.results)
                    TableRow(
                      children: [
                        //Make the height of the row
                        Center(child: Text(item)),
                        TextFormField(
                          controller: _blue[item],
                          validator: checkIsNumber,
                        ),
                        TextFormField(
                          controller: _red[item],
                          validator: checkIsNumber,
                        ),
                      ],
                    )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String? checkIsNumber(String? input) {
  if (input == null || num.tryParse(input) == null) {
    return "Input must be a number";
  }
}
