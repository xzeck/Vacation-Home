import 'package:dal_vacation_home/property-agents/lookerstudio_webview_mobile.dart'
    if (dart.library.html) 'package:dal_vacation_home/property-agents/lookerstudio_webview_web.dart';
import 'package:flutter/material.dart';

class LookerstudioWebview extends StatelessWidget {
  const LookerstudioWebview({super.key});

  @override
  Widget build(BuildContext context) {
    registerWebViewFactory();

    return Scaffold(
        appBar: AppBar(
          title: const Text('DalVacationHome Analytics - Looker Studio'),
        ),
        body: Center(
          child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              height: MediaQuery.of(context).size.height * 0.8,
              child: const HtmlElementView(viewType: 'lookerstudio-webview')),
        ));
  }
}
