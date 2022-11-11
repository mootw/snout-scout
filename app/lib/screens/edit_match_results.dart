import 'dart:convert';

import 'package:app/confirm_exit_dialog.dart';
import 'package:app/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/event/match.dart';
import 'package:snout_db/event/matchresults.dart';
import 'package:snout_db/patch.dart';
import 'package:snout_db/snout_db.dart';

class EditMatchResults extends StatefulWidget {
  final Season config;
  final FRCMatch match;

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

    DateTime? date = widget.match.results?.time;
    if(date != null) {
      matchEndTime = date.add(matchLength);
    } else {
      matchEndTime = DateTime.now();
    }

    //Pre-fill result scores
    for (var resultValue in widget.config.matchscouting.scoring) {
      _red[resultValue] = TextEditingController(text: widget.match.results?.red[resultValue]?.toString());
      _blue[resultValue] = TextEditingController(text: widget.match.results?.blue[resultValue]?.toString());
    }
  }

  //Converts text editing controller to number
  Map<String, int> _mapTo(Map<String, TextEditingController> input) {
    return input
        .map((key, value) => MapEntry(key, int.parse(input[key]!.text)));
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmExitDialog(
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
                onPressed: () async {
                  if (_form.currentState?.validate() ?? false) {
                    //TODO this is probably not the right way to do this.
                    final snoutData = Provider.of<SnoutScoutData>(context, listen: false);
                    //Input is valid
                    //Construct match results object
                    MatchResults results = MatchResults(
                        time: matchEndTime.subtract(matchLength),
                        red: _mapTo(_red),
                        blue: _mapTo(_blue),
                      );
                    Patch patch = Patch(
                        user: "anon",
                        time: DateTime.now(),
                        path: [
                          'events',
                          snoutData.selectedEventID,
                          'matches',
                          //Index of the match to modify. This could cause issues if
                          //the index of the match changes inbetween this database
                          //being updated and not. Ideally matches should have a unique key
                          //like their scheduled date to uniquely identify them.
                          snoutData.currentEvent.matches
                              .indexOf(widget.match)
                              .toString(),
                          'results'
                        ],
                        data: jsonEncode(results));
    
                    await snoutData.addPatch(patch);
                    setState(() {});
                    
                    Navigator.pop(context, true);
                  }
                },
                icon: const Icon(Icons.save)),
          ],
          title:
              Text("Results: ${widget.match.description}"),
        ),
        body: Form(
          key: _form,
          child: ListView(
            children: [
              ListTile(
                title: const Text("Match End Time"),
                subtitle: Text(DateFormat.Hm().add_yMd().format(matchEndTime)),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
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
              DataTable(
                columns: const [
                  DataColumn(label: Text("Score")),
                  DataColumn(label: Text("Red")),
                  DataColumn(label: Text("Blue")),
                ],
                  rows: [
                    for (final item in widget.config.matchscouting.scoring)
                    DataRow(
                      cells: [
                        DataCell(Text(item)),
                        DataCell(TextFormField(
                          controller: _blue[item],
                          validator: _checkIsNumber,
                        )),
                        DataCell(TextFormField(
                          controller: _red[item],
                          validator: _checkIsNumber,
                        )),
                      ],
                    )
                  
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String? _checkIsNumber(String? input) {
  if (input == null || num.tryParse(input) == null) {
    return "Input must be a number";
  }
  return null;
}
