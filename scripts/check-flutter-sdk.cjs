const fs = require('node:fs');
const path = require('node:path');

const [sdkDirectory, expectedVersion] = process.argv.slice(2);

try {
  const metadata = JSON.parse(
    fs.readFileSync(path.join(sdkDirectory, 'bin/cache/flutter.version.json'), 'utf8'),
  );
  const requiredFields = [
    'frameworkVersion',
    'channel',
    'repositoryUrl',
    'frameworkRevision',
    'frameworkCommitDate',
    'engineRevision',
    'dartSdkVersion',
    'devToolsVersion',
    'flutterVersion',
  ];
  if (
    !expectedVersion ||
    metadata.frameworkVersion !== expectedVersion ||
    metadata.flutterVersion !== expectedVersion ||
    !requiredFields.every(field => typeof metadata[field] === 'string' && metadata[field].length > 0)
  ) {
    process.exitCode = 1;
  } else {
    fs.accessSync(path.join(sdkDirectory, 'bin/cache/dart-sdk/bin/dart'), fs.constants.X_OK);
    if (!fs.statSync(path.join(sdkDirectory, 'bin/cache/flutter_tools.snapshot')).isFile()) {
      process.exitCode = 1;
    }
  }
} catch {
  process.exitCode = 1;
}
