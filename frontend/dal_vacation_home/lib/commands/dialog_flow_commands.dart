import 'package:dialog_flowtter/dialog_flowtter.dart';

class DialogFlowCommands {
  static Future<DialogAuthCredentials?> init() async {
    DialogAuthCredentials? credentials;
    try {
      String path =
          "assets/csci5410-groupproject-a9a880dea030-Dialogflow-API-Key.json";
      credentials = await DialogAuthCredentials.fromFile(path);
      return credentials;
    } catch (e) {
      print(e);
    }

    return credentials;
  }
}
