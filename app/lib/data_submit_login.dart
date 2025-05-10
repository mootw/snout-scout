import 'package:app/providers/data_provider.dart';
import 'package:app/providers/identity_provider.dart';
import 'package:app/screens/scout_authenticator_dialog.dart';
import 'package:app/widgets/confirm_exit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/patch.dart';

Future submitMultiplePatches(BuildContext context, List<Patch> patches) async {
  //TODO make this flash and only pushReplacement the route at the save button, then show leaderboard while saving
  final login = await showDialog(
    context: context,
    builder:
        (context) => ConfirmExitDialog(
          child: ScoutAuthorizationDialog(allowBackButton: true),
        ),
  );

  if (login != null && context.mounted) {
    // Update the current login
    final dataProvider = context.read<DataProvider>();
    context.read<IdentityProvider>().setIdentity(login);

    for (final patch in patches) {
      final newPatch = Patch(
        // Force the identity for the patch to be the login user!
        identity: login,
        path: patch.path,
        time: patch.time,
        value: patch.value,
      );
      await dataProvider.newTransaction(newPatch);
    }
    // if (context.mounted) {
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(builder: (_) => ScoutLeaderboardPage()),
    //   );
    // }
  }
}

Future submitData(BuildContext context, Patch patch) async =>
    submitMultiplePatches(context, [patch]);

class HoldScreen extends StatelessWidget {
  const HoldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar());
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
