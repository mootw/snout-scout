import 'package:app/providers/data_provider.dart';
import 'package:app/providers/loading_status_service.dart';
import 'package:app/screens/failed_patches.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoadOrErrorStatusBar extends StatelessWidget
    implements PreferredSizeWidget {
  const LoadOrErrorStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();

    if (data.remoteOutbox.outboxCache.isNotEmpty) {
      return InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FailedPatchStorage()),
        ),
        child: Container(
          alignment: Alignment.center,
          width: double.infinity,
          height: 28,
          color: Colors.indigo,
          child: Text(
            "${data.remoteOutbox.outboxCache.length} transactions in outbox",
          ),
        ),
      );
    }

    if (data.isDataSourceUriRemote && data.connected == false) {
      return Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: 20,
        color: Theme.of(context).colorScheme.errorContainer,
        child: const Text("No Connection"),
      );
    }

    return StreamBuilder<int>(
      stream: loadingService.loadingCount,
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.active:
            if (snapshot.hasData && snapshot.data! > 0) {
              return const LinearProgressIndicator();
            } else {
              return const SizedBox();
            }
          default:
            return const SizedBox();
        }
      },
    );
  }

  //so the larger widgets will just smoosh into the appbar :shrug:
  @override
  Size get preferredSize => const Size(double.infinity, 4);
}
