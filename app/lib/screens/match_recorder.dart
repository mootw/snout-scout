import 'dart:async';
import 'dart:convert';

import 'package:app/providers/cache_memory_imageprovider.dart';
import 'package:app/providers/local_config_provider.dart';
import 'package:app/screens/view_team_page.dart';
import 'package:app/widgets/confirm_exit_dialog.dart';
import 'package:app/widgets/datasheet.dart';
import 'package:app/providers/data_provider.dart';
import 'package:app/widgets/fieldwidget.dart';
import 'package:app/style.dart';
import 'package:app/widgets/scouting_tool.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/config/matcheventconfig.dart';
import 'package:snout_db/event/matchevent.dart';
import 'package:snout_db/event/pitscoutresult.dart';
import 'package:snout_db/event/robotmatchresults.dart';
import 'dart:math' as math;

import 'package:snout_db/snout_db.dart';

class MatchRecorderPage extends StatefulWidget {
  final int team;
  final Alliance teamAlliance;

  const MatchRecorderPage(
      {super.key, required this.team, required this.teamAlliance});

  @override
  State<MatchRecorderPage> createState() => _MatchRecorderPageState();
}

enum MatchMode { setup, playing, finished }

class _MatchRecorderPageState extends State<MatchRecorderPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  MatchMode _mode = MatchMode.setup;
  List<MatchEvent> _events = [];
  final PitScoutResult _postGameSurvey = {};
  int _time = 0;
  bool _rotateField = false;
  Timer? _t;

  bool _showSurvey = false;

  MatchEvent? get _lastMoveEvent =>
      _events.toList().lastWhereOrNull((event) => event.isPositionEvent);
  FieldPosition? get _robotPosition => _lastMoveEvent?.position;

  //Only use in buildcontext
  List<MatchEventConfig> get scoutingEvents =>
      context.watch<DataProvider>().event.config.matchscouting.events;

  @override
  void initState() {
    super.initState();
    _rotateField = context.read<LocalConfigProvider>().flipFieldImage;
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  Widget _getEventButton(MatchEventConfig tool) {
    Color? toolColor = tool.color != null ? colorFromHex(tool.color!) : null;

    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: FilledButton.tonal(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          foregroundColor: (toolColor?.computeLuminance() ?? 0) < 0.5
              ? Colors.white
              : Colors.black,
          backgroundColor: toolColor,
        ),
        onPressed: _mode == MatchMode.setup || _lastMoveEvent == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                setState(() {
                  if (_mode != MatchMode.setup && _robotPosition != null) {
                    _events.add(MatchEvent.fromEventConfig(
                        time: _time, event: tool, position: _robotPosition!));
                  }
                });
              },
        child: Text(tool.label, textAlign: TextAlign.center),
      ),
    );
  }

  Widget _getTimeline() {
    return ScrollConfiguration(
      behavior: MouseInteractableScrollBehavior(),
      child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: Row(
            children: [
              Text(
                "Tap to delete an event",
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
              for (final item in _events)
                TextButton(
                    onPressed: () => setState(() {
                          _events.remove(item);
                        }),
                    child: Text(
                        '${item.time.round()}  ${item.getLabelFromConfig(context.watch<DataProvider>().event.config)}',
                        style: TextStyle(
                            color: item.isPositionEvent
                                ? Theme.of(context).colorScheme.onBackground
                                : item.getColorFromConfig(context
                                            .watch<DataProvider>()
                                            .event
                                            .config) !=
                                        null
                                    ? colorFromHex(item.getColorFromConfig(
                                        context
                                            .watch<DataProvider>()
                                            .event
                                            .config)!)
                                    : null))),

              // Text(
              //     "Check to see the map is rotated correctly! Press 'start' when you hear the field buzzer and see the field lights. It is more important to know the location of each event rather than the position of the robot at all times. Event buttons will disable if no position has been recently input."),
            ],
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
    //Allow slightly wide to be considered vertical for foldable devices or near-square devices
    final isHorizontal = MediaQuery.of(context).size.aspectRatio > 1.2;

    if (_showSurvey || _mode == MatchMode.finished) {
      return ConfirmExitDialog(
        child: Scaffold(
          appBar: AppBar(
            title: Text("${widget.team}"),
            actions: [
              if (_mode != MatchMode.finished)
                FilledButton.tonal(
                    onPressed: () => setState(() {
                          _showSurvey = !_showSurvey;
                        }),
                    child: const Text("Show Recorder")),
              IconButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate() == false) {
                      //Do not save with pending form errors.
                      return;
                    }
                    Navigator.pop(
                        context,
                        RobotMatchResults(
                            alliance: widget.teamAlliance,
                            timeline: _events,
                            survey: _postGameSurvey));
                  },
                  icon: const Icon(Icons.save)),
            ],
          ),
          body: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final item in context
                    .watch<DataProvider>()
                    .event
                    .config
                    .matchscouting
                    .survey)
                  Container(
                      padding: const EdgeInsets.all(12),
                      child: ScoutingToolWidget(
                        tool: item,
                        survey: _postGameSurvey,
                      )),
              ],
            ),
          ),
        ),
      );
    }

    if (isHorizontal) {
      return ConfirmExitDialog(
        child: Scaffold(
          appBar: AppBar(
            title: Text("${widget.team}"),
            actions: [
              FilledButton.tonal(
                  onPressed: () => setState(() {
                        _showSurvey = !_showSurvey;
                      }),
                  child: const Text("Show Survey")),
              _statusAndToolBar()
            ],
          ),
          body: Row(
            children: [
              SizedBox(
                width: 130 * 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _getTimeline(),
                    Expanded(
                      child: LayoutBuilder(builder: (context, constraints) {
                        final newConstraints = constraints.tighten(height: 500);
                        return Wrap(
                          children: [
                            for (int i = 0; i < scoutingEvents.length; i++)
                              SizedBox(
                                height: newConstraints.maxHeight /
                                    ((scoutingEvents.length +
                                            (scoutingEvents.length % 2)) /
                                        2),
                                width: 130,
                                child: _getEventButton(scoutingEvents[i]),
                              ),
                          ],
                        );
                      }),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 690),
                  alignment: Alignment.bottomRight,
                  child: Transform.rotate(
                    angle: _rotateField ? math.pi : 0,
                    child: FieldPositionSelector(
                      coverAlignment: _mode != MatchMode.setup
                          ? null
                          : widget.teamAlliance == Alliance.red
                              ? -1
                              : 1,
                      teamNumber: widget.team,
                      alliance: widget.teamAlliance,
                      robotPosition: _robotPosition,
                      onTap: (robotPosition) {
                        HapticFeedback.lightImpact();
                        setState(() {
                          for (final event in _events.toList()) {
                            if (event.isPositionEvent) {
                              //Is position event
                              if (event.time == _time) {
                                //Event is the same time, overrwite
                                _events.remove(event);
                              }
                            }
                          }
                          _events.add(MatchEvent.robotPositionEvent(
                              time: _time, position: robotPosition));
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ConfirmExitDialog(
      child: Scaffold(
        appBar: AppBar(
          title: Text("${widget.team}"),
          actions: [
            FilledButton.tonal(
                onPressed: () => setState(() {
                      _showSurvey = !_showSurvey;
                    }),
                child: const Text("Show Survey")),
            const SizedBox(width: 32),
          ],
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _statusAndToolBar(),
            const Divider(),
            _getTimeline(),
            const SizedBox(height: 8),
            Container(
              width: 690,
              alignment: Alignment.bottomRight,
              child: Transform.rotate(
                angle: _rotateField ? math.pi : 0,
                child: FieldPositionSelector(
                  teamNumber: widget.team,
                  coverAlignment: _mode != MatchMode.setup
                      ? null
                      : widget.teamAlliance == Alliance.red
                          ? -1
                          : 1,
                  alliance: widget.teamAlliance,
                  robotPosition: _robotPosition,
                  onTap: (robotPosition) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      for (final event in _events.toList()) {
                        if (event.isPositionEvent) {
                          //Is position event
                          if (event.time == _time) {
                            //Event is the same time, overrwite
                            _events.remove(event);
                          }
                        }
                      }
                      _events.add(MatchEvent.robotPositionEvent(
                          time: _time, position: robotPosition));
                    });
                  },
                ),
              ),
            ),
            Wrap(
              children: [
                for (int i = 0; i < scoutingEvents.length; i++)
                  SizedBox(
                    height: 54,
                    width: (MediaQuery.of(context).size.width / 2),
                    child: _getEventButton(scoutingEvents[i]),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusAndToolBar() {
    Image? robotPicture;
    final pictureData = context
        .watch<DataProvider>()
        .event
        .pitscouting[widget.team.toString()]?[robotPictureReserved];
    if (pictureData != null) {
      robotPicture = Image(
          image: CacheMemoryImageProvider(
              Uint8List.fromList(base64Decode(pictureData).cast<int>())));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              tooltip: "Rotate Map",
              onPressed: () => setState(() {
                    _rotateField = !_rotateField;
                    context
                        .read<LocalConfigProvider>()
                        .setFlipFieldImage(_rotateField);
                  }),
              icon: const Icon(Icons.rotate_right)),
          const SizedBox(width: 8),
          Text("time $_time"),
          const SizedBox(width: 8),
          if (robotPicture == null) const Text("No Picture"),
          if (robotPicture != null)
            Center(
              child: TextButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => Scaffold(
                            appBar: AppBar(),
                            body: PhotoView(
                              imageProvider: robotPicture!.image,
                            ),
                          ))),
                  child: const Text("Robot Picture")),
            ),
          const SizedBox(width: 8),
          FilledButton.icon(
            icon: const Icon(Icons.arrow_forward),
            style: _mode == MatchMode.playing
                ? FilledButton.styleFrom(
                    backgroundColor: Colors.red, foregroundColor: Colors.white)
                : null,
            onPressed: _lastMoveEvent == null ? null : _handleNextSection,
            label: Text(_mode == MatchMode.setup
                ? "Start"
                : _mode == MatchMode.playing
                    ? "End"
                    : ""),
          ),
        ],
      ),
    );
  }

  void _handleNextSection() {
    HapticFeedback.heavyImpact();
    if (_mode == MatchMode.playing) {
      //Stop timer
      _t?.cancel();
      _mode = MatchMode.finished;
      //Scale event times to be within the match length
      _events = List.generate(_events.length, (index) {
        final event = _events[index];
        return MatchEvent(
            time: ((event.time / _time) * matchLength.inSeconds).round(),
            x: event.x,
            y: event.y,
            id: event.id);
      });
      _time = matchLength.inSeconds;
    }
    if (_mode == MatchMode.setup) {
      _mode = MatchMode.playing;
      _time = 1; //Second 0 is reserved for pre-game events
      //Start timer
      _t = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_mode != MatchMode.finished) {
          setState(() {
            _time++;
            if (_time == 17) {
              //Buzz the device for end of auto
              HapticFeedback.heavyImpact();
              Timer(const Duration(milliseconds: 500), () {
                HapticFeedback.heavyImpact();
              });
              Timer(const Duration(milliseconds: 1000), () {
                HapticFeedback.heavyImpact();
              });
            }
          });
        }
      });
    }
    setState(() {});
  }
}
