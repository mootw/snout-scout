import 'package:flutter/material.dart';
import 'package:snout_db/snout_db.dart';


/// Returns a UI color for a given alliance.
Color getAllianceColor (Alliance alliance) => alliance == Alliance.red ? Colors.red : Colors.blue;