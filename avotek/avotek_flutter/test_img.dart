import 'dart:io';

void main() {
  for (var name in ['logo.png', 'logo_light.png', 'logo_large.png', 'logo_large_light.png', 'favicon.png']) {
    var f = File('assets/images/$name');
    var bytes = f.readAsBytesSync();
    print('$name: ${bytes.length} bytes');
  }
}
