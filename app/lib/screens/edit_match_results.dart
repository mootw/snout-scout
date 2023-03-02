import 'package:app/confirm_exit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:snout_db/event/matchresults.dart';
import 'package:snout_db/snout_db.dart';

class EditMatchResults extends StatefulWidget {
  final EventConfig config;
  final MatchResults? results;

  const EditMatchResults(
      {super.key, required this.config, required this.results});

  @override
  State<EditMatchResults> createState() => _EditMatchResultsState();
}

class _EditMatchResultsState extends State<EditMatchResults> {
  final _form = GlobalKey<FormState>();
  DateTime _matchEndTime = DateTime.now();

  final Map<String, TextEditingController> _red = {};
  final Map<String, TextEditingController> _blue = {};

  @override
  void initState() {
    super.initState();

    DateTime? date = widget.results?.time;
    if (date != null) {
      _matchEndTime = date.add(matchLength);
    } else {
      _matchEndTime = DateTime.now();
    }

    //Pre-fill result scores
    for (final resultValue in widget.config.matchscouting.scoring) {
      _red[resultValue] = TextEditingController(
          text: widget.results?.red[resultValue]?.toString());
      _blue[resultValue] = TextEditingController(
          text: widget.results?.blue[resultValue]?.toString());
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
                onPressed: () {
                  if (_form.currentState?.validate() ?? false) {
                    //Input is valid
                    //Construct match results object
                    MatchResults results = MatchResults(
                      time: _matchEndTime.subtract(matchLength),
                      red: _mapTo(_red),
                      blue: _mapTo(_blue),
                    );
                    Navigator.pop(context, results);
                  }
                },
                icon: const Icon(Icons.save)),
          ],
          title: const Text("Edit Results"),
        ),
        body: Form(
          key: _form,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            children: [
              ListTile(
                title: const Text("Match End Time"),
                subtitle: Text(DateFormat.Hm().add_yMd().format(_matchEndTime)),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    DateTime? d = await showDatePicker(
                        context: context,
                        firstDate: DateTime(1992),
                        lastDate: DateTime.now(),
                        initialDate: _matchEndTime);
                    if (d != null) {
                      _matchEndTime = DateTime(d.year, d.month, d.day,
                          _matchEndTime.hour, _matchEndTime.minute);
                    }

                    TimeOfDay? time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                            hour: _matchEndTime.hour,
                            minute: _matchEndTime.minute));
                    if (time != null) {
                      _matchEndTime = DateTime(
                          _matchEndTime.year,
                          _matchEndTime.month,
                          _matchEndTime.day,
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
                          controller: _red[item],
                          validator: _checkIsNumber,
                        )),
                        DataCell(TextFormField(
                          controller: _blue[item],
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
