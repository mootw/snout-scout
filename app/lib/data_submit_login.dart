import 'package:app/providers/data_provider.dart';
import 'package:app/screens/scout_leaderboard.dart';
import 'package:app/screens/scout_selector_screen.dart';
import 'package:app/widgets/confirm_exit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/patch.dart';

Future submitData(BuildContext context, Patch patch) async {

  final login = await showDialog(
        context: context,
        builder:
            (context) => ConfirmExitDialog(
              child: ScoutAuthorizationDialog(allowBackButton: true),
            ),
      );
      if(context.mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (login != null && context.mounted) {
        final dataProvider = context.read<DataProvider>();

        await dataProvider.newTransaction(patch);
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ScoutLeaderboardPage()),
          );
        }
      }
}


class HoldScreen extends StatelessWidget {
  const HoldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
    );
  }
}



class SaveScreen extends StatefulWidget {
  final Patch patch;

  const SaveScreen({required this.patch, super.key});

  @override
  State<SaveScreen> createState() => _SaveScreenState();
}

class _SaveScreenState extends State<SaveScreen> {

  @override
  Widget build(BuildContext contexxt) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Saving :)\nPlease wait"),
          ],
        ),
      ),
    );
  }
}
