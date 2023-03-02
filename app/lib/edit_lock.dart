//Allow for edit locking using a unique key.

import 'package:app/api.dart';
import 'package:app/main.dart';
import 'package:flutter/material.dart';

//Route should return when editing is complete. This is the signal to clear the edit lock.
//This function will not throw an exception and always fail safe by navigating to the other page.
Future<dynamic> navigateWithEditLock(
    BuildContext context, String key, Function navigteFunction) async {
  Uri editLockUri = Uri.parse(
      "${Uri.parse(serverURL).scheme}://${Uri.parse(serverURL).host}:${Uri.parse(serverURL).port}/edit_lock");
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
            builder: (context) {
              return AlertDialog(
                title: const Text("This item is already being edited"),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Edit Anyways'),
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                  ),
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                  ),
                ],
              );
            });
        if (result == true) {
          //User wants to edit item anways, don't write a new edit lock in this case.
          return await navigteFunction();
        }
      }
    } else {
      //Apply lock
      try {
        await apiClient.post(editLockUri,
            headers: {"key": key}).timeout(const Duration(seconds: 1));
      } catch (e) {
        print(e);
      }

      //Navigate
      final result = await navigteFunction();
      //Clear lock

      try {
        await apiClient.delete(editLockUri,
            headers: {"key": key}).timeout(const Duration(seconds: 1));
      } catch (e) {
        print(e);
      }

      //Return data
      return result;
    }
  } catch (e) {
    print(e);
    //Fail save and navigate anyways
    return await navigteFunction();
  }
}
