import 'text_file_download_stub.dart'
    if (dart.library.html) 'text_file_download_web.dart'
    as platform;

Future<bool> downloadTextFile(String fileName, String contents) =>
    platform.downloadTextFile(fileName, contents);
