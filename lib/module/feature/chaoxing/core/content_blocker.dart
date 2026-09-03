import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ChaoxingContentBlocker {
  static final jsBridgeBlocker = ContentBlocker(
    trigger: ContentBlockerTrigger(
      urlFilter: ".*CXJSBridge.*",
      resourceType: [.SCRIPT, .RAW, .DOCUMENT],
    ),
    action: ContentBlockerAction(type: .BLOCK),
  );
}
