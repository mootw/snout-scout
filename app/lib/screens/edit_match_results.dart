import 'package:app/form_validators.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/services/tba_autofill.dart';
import 'package:app/widgets/confirm_exit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/event/matchresults.dart';
import 'package:snout_db/snout_db.dart';

class EditMatchResults extends StatefulWidget {
  final EventConfig config;
  final MatchResultValues? results;
  final String matchID; // used for tba autofill.

  const EditMatchResults({
    super.key,
    required this.config,
    required this.results,
    required this.matchID,
  });

  @override
  State<EditMatchResults> createState() => _EditMatchResultsState();
}

class _EditMatchResultsState extends State<EditMatchResults> {
  final _form = GlobalKey<FormState>();
  DateTime _matchEndTime = DateTime.now();

  late TextEditingController _redScore;
  late TextEditingController _blueScore;

  bool _isAutofillThinking = false;

  @override
  void initState() {
    super.initState();

    DateTime? date = widget.results?.time;
    if (date != null) {
      _matchEndTime = date.add(matchLength);
    } else {
      _matchEndTime = DateTime.now();
    }

    _redScore = TextEditingController(
      text: widget.results?.redScore.toString(),
    );
    _blueScore = TextEditingController(
      text: widget.results?.blueScore.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConfirmExitDialog(
      child: Scaffold(
        appBar: AppBar(
          actions: [
            TextButton(
              onPressed: () async {
                setState(() {
                  _isAutofillThinking = true;
                });
                try {
                  final result = await getMatchResultsDataFromTBA(
                    context.read<DataProvider>().event,
                    widget.matchID,
                  );
                  _redScore.text = result.redScore.toString();
                  _blueScore.text = result.blueScore.toString();
                  _matchEndTime = result.startTime.add(matchLength);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Match data has been filled in'),
                        duration: Duration(seconds: 4),
                      ),
                    );
                  }
                } catch (e, s) {
                  Logger.root.severe(
                    "error autofilling ${widget.matchID}",
                    e,
                    s,
                  );

                  setState(() {
                    _isAutofillThinking = false;
                  });
                }

                setState(() {
                  _isAutofillThinking = false;
                });
              },
              child:
                  _isAutofillThinking
                      ? const CircularProgressIndicator()
                      : const Text("AutoFill TBA"),
            ),
            IconButton(
              onPressed: () {
                if (_form.currentState?.validate() ?? false) {
                  //Input is valid
                  //Construct match results object
                  MatchResultValues results = MatchResultValues(
                    time: _matchEndTime.subtract(matchLength),
                    redScore: int.parse(_redScore.text),
                    blueScore: int.parse(_blueScore.text),
                  );
                  Navigator.pop(context, results);
                }
              },
              icon: const Icon(Icons.save),
            ),
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
                      initialDate: _matchEndTime,
                    );
                    if (d != null) {
                      _matchEndTime = DateTime(
                        d.year,
                        d.month,
                        d.day,
                        _matchEndTime.hour,
                        _matchEndTime.minute,
                      );
                    }

                    if (context.mounted) {
                      TimeOfDay? time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay(
                          hour: _matchEndTime.hour,
                          minute: _matchEndTime.minute,
                        ),
                      );
                      if (time != null) {
                        _matchEndTime = DateTime(
                          _matchEndTime.year,
                          _matchEndTime.month,
                          _matchEndTime.day,
                          time.hour,
                          time.minute,
                        );
                      }
                      setState(() {});
                    }
                  },
                ),
              ),
              DataTable(
                columns: const [
                  DataColumn(label: Text("Results")),
                  DataColumn(label: Text("Blue")),
                  DataColumn(label: Text("Red")),
                ],
                rows: [
                  DataRow(
                    cells: [
                      const DataCell(Text("Score")),
                      DataCell(
                        TextFormField(
                          controller: _blueScore,
                          validator: checkIsNumber,
                        ),
                      ),
                      DataCell(
                        TextFormField(
                          controller: _redScore,
                          validator: checkIsNumber,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}