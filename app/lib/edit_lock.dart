//Allow for edit locking using a unique key.

import 'package:app/api.dart';
import 'package:app/providers/data_provider.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

//Route should return when editing is complete. This is the signal to clear the edit lock.
//This function will not throw an exception and always fail safe by navigating to the other page.
Future<T?> navigateWithEditLock<T>(BuildContext context, String key,
    Function(BuildContext context) navigteFunction) async {
  final editLockUri =
      context.read<DataProvider>().serverURI.resolve("/edit_lock");

  //Check if this key is being edited
  try {
    final isLocked = await apiClient.get(editLockUri,
        headers: {"key": key}).timeout(const Duration(seconds: 1));
    if (isLocked.body == "true") {
      //Warn that this key is locked
      if (context.mounted) {
        //Check if we are still mounted before showing the dialog
        final result = await showDialog(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                title: const Text("This item is already being edited"),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Edit Anyways'),
                    onPressed: () {
                      Navigator.of(dialogContext).pop(true);
                    },
                  ),
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.of(dialogContext).pop(false);
                    },
                  ),
                ],
              );
            });
        if (result == true && context.mounted) {
          //User wants to edit item anways, don't write a new edit lock in this case.
          return await navigteFunction(context);
        }
      }
    } else {
      //Apply lock
      try {
        await apiClient.post(editLockUri,
            headers: {"key": key}).timeout(const Duration(seconds: 1));
      } catch (e) {
        Logger.root.warning("Error applying edit lock", e);
      }
      //Navigate
      T? result;
      if (context.mounted) {
        result = await navigteFunction(context);
      }
      //Clear lock
      try {
        await apiClient.delete(editLockUri,
            headers: {"key": key}).timeout(const Duration(seconds: 1));
      } catch (e) {
        Logger.root.warning("Error clearing edit lock", e);
      }
      //Return data
      return result;
    }
  } catch (e) {
    Logger.root.warning("edit lock error", e);
    //Fail save and navigate anyways
    if (context.mounted) {
      return await navigteFunction(context);
    }
  }
  return null;
}
