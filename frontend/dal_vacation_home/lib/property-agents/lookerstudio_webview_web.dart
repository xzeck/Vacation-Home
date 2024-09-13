import 'package:universal_html/html.dart' as html;
import 'dart:ui' as ui;

void registerWebViewFactory() {
  // ignore: undefined_prefixed_name
  ui.platformViewRegistry.registerViewFactory(
      'lookerstudio-webview',
      (int viewId) => html.IFrameElement()
        ..src =
            'https://lookerstudio.google.com/embed/reporting/e25b083f-91a6-4661-8fc9-779c764fb4f2/page/ebr6D'
        ..style.border = 'none');
}
