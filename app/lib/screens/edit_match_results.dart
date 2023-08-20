import 'package:app/confirm_exit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:snout_db/event/matchresults.dart';
import 'package:snout_db/snout_db.dart';

class EditMatchResults extends StatefulWidget {
  final EventConfig config;
  final MatchResultValues? results;

  const EditMatchResults(
      {super.key, required this.config, required this.results});

  @override
  State<EditMatchResults> createState() => _EditMatchResultsState();
}

class _EditMatchResultsState extends State<EditMatchResults> {
  final _form = GlobalKey<FormState>();
  DateTime _matchEndTime = DateTime.now();

  late TextEditingController _redScore;
  late TextEditingController _blueScore;
  late TextEditingController _redRP;
  late TextEditingController _blueRP;

  @override
  void initState() {
    super.initState();

    DateTime? date = widget.results?.time;
    if (date != null) {
      _matchEndTime = date.add(matchLength);
    } else {
      _matchEndTime = DateTime.now();
    }

    _redScore = TextEditingController(text: widget.results?.redScore.toString());
    _blueScore =
        TextEditingController(text: widget.results?.blueScore.toString());
    _redRP = TextEditingController(
        text: widget.results?.redRankingPoints.toString());
    _blueRP = TextEditingController(
        text: widget.results?.blueRankingPoints.toString());
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
                    MatchResultValues results = MatchResultValues(
                      time: _matchEndTime.subtract(matchLength),
                      redScore: int.parse(_redScore.text),
                      blueRankingPoints: int.parse(_blueRP.text),
                      blueScore: int.parse(_blueScore.text),
                      redRankingPoints: int.parse(_redRP.text)
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

                    if (mounted) {
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
                    }
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
                    DataRow(
                      cells: [
                        const DataCell(Text("Score")),
                        DataCell(TextFormField(
                          controller: _redScore,
                          validator: _checkIsNumber,
                        )),
                        DataCell(TextFormField(
                          controller: _blueScore,
                          validator: _checkIsNumber,
                        )),
                      ],
                    ),
                    DataRow(
                      cells: [
                        const DataCell(Text("RP")),
                        DataCell(TextFormField(
                          controller: _redRP,
                          validator: _checkIsNumber,
                        )),
                        DataCell(TextFormField(
                          controller: _blueRP,
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
