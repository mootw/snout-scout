import 'package:app/providers/data_provider.dart';
import 'package:app/providers/identity_provider.dart';
import 'package:app/screens/scout_authenticator_dialog.dart';
import 'package:app/widgets/confirm_exit_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snout_db/action.dart';

Future submitMultipleActions(
  BuildContext context,
  List<ChainAction> actions,
) async {
  final dataProvider = context.read<DataProvider>();
  //TODO make this flash and only pushReplacement the route at the save button, then show leaderboard while saving
  final AuthorizedScoutData? login = await showDialog(
    context: context,
    builder: (context) => ConfirmExitDialog(
      child: ScoutAuthorizationDialog(allowBackButton: true),
    ),
  );

  if (login != null && context.mounted) {
    // Update the current login
    context.read<IdentityProvider>().setIdentity(login.pubkey);

    List<int> lastHash = await dataProvider.database.actions.last.hash;

    for (final action in actions) {
      final signed = await ChainActionData(
        time: DateTime.now(),
        previousHash: lastHash,
        action: action,
      ).encodeAndSign(login.secretKey);
      await dataProvider.newTransaction(signed);
      lastHash = await signed.hash;
    }
  }
}

Future submitData(BuildContext context, ChainAction action) async =>
    submitMultipleActions(context, [action]);

class HoldScreen extends StatelessWidget {
  const HoldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar());
  }
}

class SaveScreen extends StatefulWidget {
  final Action action;

  const SaveScreen({required this.action, super.key});

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
