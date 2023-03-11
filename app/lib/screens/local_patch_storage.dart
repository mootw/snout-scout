import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:app/main.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr/qr.dart';
import 'package:snout_db/patch.dart';

class LocalPatchStorage extends StatefulWidget {
  const LocalPatchStorage({super.key});

  @override
  State<LocalPatchStorage> createState() => _LocalPatchStorageState();
}

final testData = '''"robot": {
        "3130": {
          "timeline": [
            {
              "time": 0,
              "id": "robot_position",
              "x": -0.508,
              "y": 0.815,
              "nx": 0.508,
              "ny": 0.815
            },
            {
              "time": 17,
              "id": "robot_position",
              "x": -0.205,
              "y": 0.99,
              "nx": 0.205,
              "ny": 0.99
            },
            {
              "time": 18,
              "id": "robot_position",
              "x": -0.154,
              "y": 0.846,
              "nx": 0.154,
              "ny": 0.846
            },
            {
              "time": 19,
              "id": "robot_position",
              "x": 0.164,
              "y": 0.846,
              "nx": -0.164,
              "ny": 0.846
            },
            {
              "time": 20,
              "id": "robot_position",
              "x": 0.154,
              "y": 0.456,
              "nx": -0.154,
              "ny": 0.456
            },
            {
              "time": 21,
              "id": "robot_position",
              "x": 0.333,
              "y": 0.508,
              "nx": -0.333,
              "ny": 0.508
            },
            {
              "time": 22,
              "id": "robot_position",
              "x": 0.313,
              "y": 0.262,
              "nx": -0.313,
              "ny": 0.262
            },
            {
              "time": 23,
              "id": "robot_position",
              "x": 0.133,
              "y": 0.405,
              "nx": -0.133,
              "ny": 0.405
            },
            {
              "time": 24,
              "id": "robot_position",
              "x": 0.195,
              "y": 0.446,
              "nx": -0.195,
              "ny": 0.446
            },
            {
              "time": 25,
              "id": "robot_position",
              "x": 0.205,
              "y": 0.077,
              "nx": -0.205,
              "ny": 0.077
            },
            {
              "time": 26,
              "id": "robot_position",
              "x": 0.164,
              "y": 0.282,
              "nx": -0.164,
              "ny": 0.282
            },
            {
              "time": 27,
              "id": "robot_position",
              "x": 0.092,
              "y": 0.118,
              "nx": -0.092,
              "ny": 0.118
            },
            {
              "time": 28,
              "id": "robot_position",
              "x": 0.103,
              "y": 0.2,
              "nx": -0.103,
              "ny": 0.2
            },
            {
              "time": 29,
              "id": "robot_position",
              "x": -0.231,
              "y": 0.364,
              "nx": 0.231,
              "ny": 0.364
            },
            {
              "time": 30,
              "id": "robot_position",
              "x": 0.051,
              "y": 0.938,
              "nx": -0.051,
              "ny": 0.938
            },
            {
              "time": 32,
              "id": "robot_position",
              "x": -0.015,
              "y": 0.344,
              "nx": 0.015,
              "ny": 0.344
            },
            {
              "time": 33,
              "id": "robot_position",
              "x": -0.149,
              "y": 0.323,
              "nx": 0.149,
              "ny": 0.323
            },
            {
              "time": 34,
              "id": "robot_position",
              "x": 0.067,
              "y": 0.282,
              "nx": -0.067,
              "ny": 0.282
            },
            {
              "time": 35,
              "id": "robot_position",
              "x": 0.364,
              "y": 0.159,
              "nx": -0.364,
              "ny": 0.159
            },
            {
              "time": 37,
              "id": "robot_position",
              "x": 0.144,
              "y": 0.19,
              "nx": -0.144,
              "ny": 0.19
            },
            {
              "time": 38,
              "id": "robot_position",
              "x": 0.21,
              "y": 0.026,
              "nx": -0.21,
              "ny": 0.026
            },
            {
              "time": 40,
              "id": "robot_position",
              "x": 0.19,
              "y": 0.262,
              "nx": -0.19,
              "ny": 0.262
            },
            {
              "time": 41,
              "id": "robot_position",
              "x": 0.072,
              "y": 0.405,
              "nx": -0.072,
              "ny": 0.405
            },
            {
              "time": 42,
              "id": "robot_position",
              "x": 0.041,
              "y": 0.138,
              "nx": -0.041,
              "ny": 0.138
            },
            {
              "time": 43,
              "id": "robot_position",
              "x": 0.138,
              "y": 0.128,
              "nx": -0.138,
              "ny": 0.128
            },
            {
              "time": 44,
              "id": "robot_position",
              "x": -0.015,
              "y": 0.241,
              "nx": 0.015,
              "ny": 0.241
            },
            {
              "time": 45,
              "id": "robot_position",
              "x": -0.097,
              "y": 0.128,
              "nx": 0.097,
              "ny": 0.128
            },
            {
              "time": 46,
              "id": "robot_position",
              "x": -0.118,
              "y": 0.149,
              "nx": 0.118,
              "ny": 0.149
            },
            {
              "time": 47,
              "id": "robot_position",
              "x": 0.303,
              "y": 0.097,
              "nx": -0.303,
              "ny": 0.097
            },
            {
              "time": 48,
              "id": "robot_position",
              "x": 0.369,
              "y": -0.036,
              "nx": -0.369,
              "ny": -0.036
            },
            {
              "time": 49,
              "id": "robot_position",
              "x": 0.282,
              "y": 0.149,
              "nx": -0.282,
              "ny": 0.149
            },
            {
              "time": 50,
              "id": "robot_position",
              "x": 0.128,
              "y": 0.272,
              "nx": -0.128,
              "ny": 0.272
            },
            {
              "time": 51,
              "id": "robot_position",
              "x": -0.062,
              "y": 0.169,
              "nx": 0.062,
              "ny": 0.169
            },
            {
              "time": 52,
              "id": "robot_position",
              "x": 0.246,
              "y": 0.005,
              "nx": -0.246,
              "ny": 0.005
            },
            {
              "time": 53,
              "id": "robot_position",
              "x": 0.251,
              "y": -0.385,
              "nx": -0.251,
              "ny": -0.385
            },
            {
              "time": 54,
              "id": "robot_position",
              "x": 0.308,
              "y": -0.087,
              "nx": -0.308,
              "ny": -0.087
            },
            {
              "time": 55,
              "id": "robot_position",
              "x": 0.385,
              "y": -0.221,
              "nx": -0.385,
              "ny": -0.221
            },
            {
              "time": 56,
              "id": "robot_position",
              "x": 0.385,
              "y": -0.651,
              "nx": -0.385,
              "ny": -0.651
            },
            {
              "time": 57,
              "id": "robot_position",
              "x": 0.61,
              "y": -0.795,
              "nx": -0.61,
              "ny": -0.795
            },
            {
              "time": 58,
              "id": "robot_position",
              "x": 0.944,
              "y": -0.744,
              "nx": -0.944,
              "ny": -0.744
            },
            {
              "time": 59,
              "id": "robot_position",
              "x": 0.856,
              "y": -0.538,
              "nx": -0.856,
              "ny": -0.538
            },
            {
              "time": 60,
              "id": "robot_position",
              "x": 0.954,
              "y": -0.641,
              "nx": -0.954,
              "ny": -0.641
            },
            {
              "time": 61,
              "id": "robot_position",
              "x": 0.41,
              "y": -0.713,
              "nx": -0.41,
              "ny": -0.713
            },
            {
              "time": 63,
              "id": "robot_position",
              "x": 0.082,
              "y": -0.426,
              "nx": -0.082,
              "ny": -0.426
            },
            {
              "time": 64,
              "id": "robot_position",
              "x": 0.318,
              "y": -0.405,
              "nx": -0.318,
              "ny": -0.405
            },
            {
              "time": 66,
              "id": "robot_position",
              "x": 0.236,
              "y": -0.272,
              "nx": -0.236,
              "ny": -0.272
            },
            {
              "time": 68,
              "id": "robot_position",
              "x": 0.364,
              "y": -0.467,
              "nx": -0.364,
              "ny": -0.467
            },
            {
              "time": 69,
              "id": "robot_position",
              "x": 0.154,
              "y": -0.815,
              "nx": -0.154,
              "ny": -0.815
            },
            {
              "time": 71,
              "id": "robot_position",
              "x": 0.128,
              "y": -0.6,
              "nx": -0.128,
              "ny": -0.6
            },
            {
              "time": 72,
              "id": "robot_position",
              "x": -0.205,
              "y": -0.651,
              "nx": 0.205,
              "ny": -0.651
            },
            {
              "time": 73,
              "id": "robot_position",
              "x": 0.077,
              "y": -0.19,
              "nx": -0.077,
              "ny": -0.19
            },
            {
              "time": 74,
              "id": "robot_position",
              "x": -0.138,
              "y": -0.415,
              "nx": 0.138,
              "ny": -0.415
            },
            {
              "time": 77,
              "id": "robot_position",
              "x": 0.154,
              "y": -0.364,
              "nx": -0.154,
              "ny": -0.364
            },
            {
              "time": 78,
              "id": "robot_position",
              "x": -0.138,
              "y": -0.282,
              "nx": 0.138,
              "ny": -0.282
            },
            {
              "time": 79,
              "id": "robot_position",
              "x": -0.4,
              "y": -0.026,
              "nx": 0.4,
              "ny": -0.026
            },
            {
              "time": 80,
              "id": "robot_position",
              "x": 0.031,
              "y": 0.313,
              "nx": -0.031,
              "ny": 0.313
            },
            {
              "time": 81,
              "id": "robot_position",
              "x": -0.2,
              "y": 0.097,
              "nx": 0.2,
              "ny": 0.097
            },
            {
              "time": 82,
              "id": "robot_position",
              "x": -0.251,
              "y": 0.497,
              "nx": 0.251,
              "ny": 0.497
            },
            {
              "time": 84,
              "id": "robot_position",
              "x": -0.051,
              "y": 0.385,
              "nx": 0.051,
              "ny": 0.385
            },
            {
              "time": 85,
              "id": "robot_position",
              "x": -0.041,
              "y": 0.2,
              "nx": 0.041,
              "ny": 0.2
            },
            {
              "time": 86,
              "id": "robot_position",
              "x": -0.164,
              "y": 0.282,
              "nx": 0.164,
              "ny": 0.282
            },
            {
              "time": 87,
              "id": "robot_position",
              "x": -0.185,
              "y": -0.108,
              "nx": 0.185,
              "ny": -0.108
            },
            {
              "time": 88,
              "id": "robot_position",
              "x": -0.267,
              "y": -0.005,
              "nx": 0.267,
              "ny": -0.005
            },
            {
              "time": 89,
              "id": "robot_position",
              "x": -0.277,
              "y": -0.241,
              "nx": 0.277,
              "ny": -0.241
            },
            {
              "time": 90,
              "id": "robot_position",
              "x": -0.205,
              "y": -0.528,
              "nx": 0.205,
              "ny": -0.528
            },
            {
              "time": 91,
              "id": "robot_position",
              "x": 0.005,
              "y": -0.764,
              "nx": -0.005,
              "ny": -0.764
            },
            {
              "time": 92,
              "id": "robot_position",
              "x": -0.144,
              "y": -0.221,
              "nx": 0.144,
              "ny": -0.221
            },
            {
              "time": 93,
              "id": "robot_position",
              "x": -0.231,
              "y": -0.179,
              "nx": 0.231,
              "ny": -0.179
            },
            {
              "time": 94,
              "id": "robot_position",
              "x": -0.497,
              "y": -0.231,
              "nx": 0.497,
              "ny": -0.231
            },
            {
              "time": 96,
              "id": "robot_position",
              "x": -0.641,
              "y": 0.026,
              "nx": 0.641,
              "ny": 0.026
            },
            {
              "time": 99,
              "id": "robot_position",
              "x": -0.821,
              "y": -0.108,
              "nx": 0.821,
              "ny": -0.108
            },
            {
              "time": 100,
              "id": "robot_position",
              "x": -0.877,
              "y": -0.046,
              "nx": 0.877,
              "ny": -0.046
            },
            {
              "time": 103,
              "id": "cone",
              "x": -0.877,
              "y": -0.046,
              "nx": 0.877,
              "ny": -0.046
            },
            {
              "time": 105,
              "id": "robot_position",
              "x": -0.805,
              "y": -0.005,
              "nx": 0.805,
              "ny": -0.005
            },
            {
              "time": 106,
              "id": "bottom",
              "x": -0.805,
              "y": -0.005,
              "nx": 0.805,
              "ny": -0.005
            },
            {
              "time": 107,
              "id": "robot_position",
              "x": -0.621,
              "y": -0.077,
              "nx": 0.621,
              "ny": -0.077
            },
            {
              "time": 108,
              "id": "robot_position",
              "x": -0.395,
              "y": -0.118,
              "nx": 0.395,
              "ny": -0.118
            },
            {
              "time": 109,
              "id": "robot_position",
              "x": -0.241,
              "y": -0.374,
              "nx": 0.241,
              "ny": -0.374
            },
            {
              "time": 110,
              "id": "robot_position",
              "x": -0.2,
              "y": -0.344,
              "nx": 0.2,
              "ny": -0.344
            },
            {
              "time": 111,
              "id": "robot_position",
              "x": -0.256,
              "y": -0.569,
              "nx": 0.256,
              "ny": -0.569
            },
            {
              "time": 113,
              "id": "robot_position",
              "x": -0.333,
              "y": -0.251,
              "nx": 0.333,
              "ny": -0.251
            },
            {
              "time": 115,
              "id": "robot_position",
              "x": -0.379,
              "y": -0.21,
              "nx": 0.379,
              "ny": -0.21
            },
            {
              "time": 118,
              "id": "intake",
              "x": -0.379,
              "y": -0.21,
              "nx": 0.379,
              "ny": -0.21
            },
            {
              "time": 119,
              "id": "robot_position",
              "x": -0.692,
              "y": -0.087,
              "nx": 0.692,
              "ny": -0.087
            },
            {
              "time": 120,
              "id": "robot_position",
              "x": -0.61,
              "y": 0.077,
              "nx": 0.61,
              "ny": 0.077
            },
            {
              "time": 123,
              "id": "robot_position",
              "x": -0.672,
              "y": -0.015,
              "nx": 0.672,
              "ny": -0.015
            },
            {
              "time": 124,
              "id": "robot_position",
              "x": -0.656,
              "y": 0.169,
              "nx": 0.656,
              "ny": 0.169
            },
            {
              "time": 129,
              "id": "robot_position",
              "x": -0.559,
              "y": -0.159,
              "nx": 0.559,
              "ny": -0.159
            },
            {
              "time": 131,
              "id": "robot_position",
              "x": -0.615,
              "y": -0.067,
              "nx": 0.615,
              "ny": -0.067
            },
            {
              "time": 132,
              "id": "robot_position",
              "x": -0.282,
              "y": -0.067,
              "nx": 0.282,
              "ny": -0.067
            },
            {
              "time": 134,
              "id": "robot_position",
              "x": -0.19,
              "y": 0.385,
              "nx": 0.19,
              "ny": 0.385
            },
            {
              "time": 135,
              "id": "robot_position",
              "x": -0.426,
              "y": 0.292,
              "nx": 0.426,
              "ny": 0.292
            },
            {
              "time": 136,
              "id": "robot_position",
              "x": -0.328,
              "y": 0.19,
              "nx": 0.328,
              "ny": 0.19
            },
            {
              "time": 137,
              "id": "robot_position",
              "x": -0.41,
              "y": 0.128,
              "nx": 0.41,
              "ny": 0.128
            },
            {
              "time": 138,
              "id": "robot_position",
              "x": -0.487,
              "y": 0.159,
              "nx": 0.487,
              "ny": 0.159
            },
            {
              "time": 142,
              "id": "robot_position",
              "x": -0.492,
              "y": 0.149,
              "nx": 0.492,
              "ny": 0.149
            },
            {
              "time": 143,
              "id": "robot_position",
              "x": -0.513,
              "y": 0.108,
              "nx": 0.513,
              "ny": 0.108
            },
            {
              "time": 145,
              "id": "robot_position",
              "x": -0.528,
              "y": 0.046,
              "nx": 0.528,
              "ny": 0.046
            },
            {
              "time": 146,
              "id": "robot_position",
              "x": -0.559,
              "y": 0.221,
              "nx": 0.559,
              "ny": 0.221
            },
            {
              "time": 147,
              "id": "robot_position",
              "x": -0.549,
              "y": 0.241,
              "nx": 0.549,
              "ny": 0.241
            },
            {
              "time": 149,
              "id": "robot_position",
              "x": -0.559,
              "y": 0.179,
              "nx": 0.559,
              "ny": 0.179
            },
            {
              "time": 150,
              "id": "robot_position",
              "x": -0.595,
              "y": 0.2,
              "nx": 0.595,
              "ny": 0.2
            }
          ],
          "survey": {
            "intake_issue": true,
            "driving_skill": "Low",
            "driving_awareness": "Medium",
            "defense_skill": "Medium",
            "comments": "i cant twll if they were defending or just really bad at picking up things",
            "auto_balance": "No attempt",
            "teleop_balance": "Successful"
          }
        }''';

class _LocalPatchStorageState extends State<LocalPatchStorage> {
  @override
  Widget build(BuildContext context) {
    final snoutData = context.watch<EventDB>();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Local Patch Storage"),
        actions: [
          IconButton(
              color: Colors.red,
              onPressed: () => showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: const Text(
                            "Are you sure you want to delete ALL failed patches?"),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel")),
                          FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .errorContainer),
                              onPressed: () async {
                                await snoutData.clearFailedPatches();
                                if (mounted) {
                                  Navigator.pop(context);
                                }
                              },
                              child: const Text("Delete")),
                        ],
                      )),
              icon: const Icon(Icons.delete)),
          IconButton(
              color: Colors.green,
              onPressed: () => showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: const Text(
                            "Are you sure you want to delete ALL successful patches?"),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancel")),
                          FilledButton.tonal(
                              style: FilledButton.styleFrom(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .errorContainer),
                              onPressed: () async {
                                await snoutData.clearSuccessfulPatches();
                                if (mounted) {
                                  Navigator.pop(context);
                                }
                              },
                              child: const Text("Delete")),
                        ],
                      )),
              icon: const Icon(Icons.delete)),
        ],
      ),
      body: ListView(
        children: [
          const Center(child: Text("Failed Patches")),
          for (final patch in snoutData.failedPatches.reversed)
            ListTile(
              onTap: () => showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: const Text("Patch Data"),
                        content: SelectableText(patch),
                      )),
              tileColor: Colors.red,
              title: Text(DateFormat.yMMMMEEEEd()
                  .add_Hms()
                  .format(Patch.fromJson(jsonDecode(patch)).time)),
              subtitle: Text(Patch.fromJson(jsonDecode(patch)).path.toString()),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      onPressed: () async {
                        await snoutData
                            .addPatch(Patch.fromJson(jsonDecode(patch)));
                        setState(() {});
                      },
                      icon: const Icon(Icons.refresh)),
                  IconButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    QRCodeDisplay(data: testData)));
                      },
                      icon: const Icon(Icons.qr_code)),
                ],
              ),
            ),
          const Center(child: Text("Successful Patches")),
          for (final patch in snoutData.successfulPatches.reversed)
            ListTile(
              onTap: () => showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                        title: const Text("Patch Data"),
                        content: SelectableText(patch),
                      )),
              tileColor: Colors.green,
              title: Text(DateFormat.yMMMMEEEEd()
                  .add_Hms()
                  .format(Patch.fromJson(jsonDecode(patch)).time)),
              subtitle: Text(Patch.fromJson(jsonDecode(patch)).path.toString()),
            ),
        ],
      ),
    );
  }
}

class QRCodeDisplay extends StatefulWidget {
  const QRCodeDisplay({super.key, required this.data});

  final String data;

  @override
  State<QRCodeDisplay> createState() => _QRCodeDisplayState();
}

class _QRCodeDisplayState extends State<QRCodeDisplay> {

  int _currentCode = 0;
  final int _maxBytesPerCode = 1000;

  final List<List<int>> _splitData = [];

  late Timer _t;

  @override
  void initState() {
    super.initState();
    List<int> encodedCompressed =
        GZipEncoder().encode(utf8.encode(widget.data))!;

    for (int i = 0; i < encodedCompressed.length; i += _maxBytesPerCode) {
      _splitData.add(encodedCompressed.sublist(
          i, min(i + _maxBytesPerCode, encodedCompressed.length)));
    }

    //Add metadata to code data
    //the first byte is how many total codes there are (0 means 1 code)
    //the second byte is the current code being scanned
    //This allows for up to 256 codes to be scanned.
    for (int i = 0; i < _splitData.length; i++) {
      _splitData[i] = [_splitData.length - 1, i, ..._splitData[i]];
    }

    print(_splitData);

    _t = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _currentCode++;
      if(_currentCode >= _splitData.length) {
        _currentCode = 0;
      }
      });
    });
  }

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final code = QrCode.fromUint8List(
        data: Uint8List.fromList(_splitData[_currentCode]),
        errorCorrectLevel: QrErrorCorrectLevel.L);
    final image = QrImage(code);

    final width = MediaQuery.of(context).size.width;
    //QR codes have a safe zone of 4 blocks on each side
    final pixelSize = width / (image.moduleCount + 8);
    return Scaffold(
        appBar: AppBar(
          title: Text("Showing code $_currentCode of ${_splitData.length - 1}"),
        ),
        body: Container(
          color: Colors.white,
          padding: EdgeInsets.all(pixelSize * 4),
          child: Column(
            children: [
              for (var y = 0; y < image.moduleCount; y++)
                Row(
                  children: [
                    for (var x = 0; x < image.moduleCount; x++)
                      Container(
                          color: image.isDark(x, y) ? Colors.black : null,
                          width: pixelSize,
                          height: pixelSize),
                  ],
                )
            ],
          ),
        ));
  }
}
