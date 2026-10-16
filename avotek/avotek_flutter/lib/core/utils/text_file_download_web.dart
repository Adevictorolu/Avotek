// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;

Future<bool> downloadTextFile(String fileName, String contents) async {
  final blob = html.Blob(
    [utf8.encode(contents)],
    'text/plain;charset=utf-8',
  );
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..download = fileName
    ..style.display = 'none';
  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();
  Timer(const Duration(seconds: 1), () => html.Url.revokeObjectUrl(url));
  return true;
}
