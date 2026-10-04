import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

bool downloadFinancialReport(String filename, String csv) {
  final blob = web.Blob(
    ['\uFEFF$csv'.toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename
    ..style.display = 'none';
  final body = web.document.body;
  if (body == null) {
    web.URL.revokeObjectURL(url);
    return false;
  }
  body.append(anchor);
  anchor.click();
  anchor.remove();
  Timer(const Duration(seconds: 1), () => web.URL.revokeObjectURL(url));
  return true;
}
