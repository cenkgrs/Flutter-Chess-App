import 'package:flutter/foundation.dart';

const sourceRepository = 'https://github.com/cenkgrs/Flutter-Chess-App';
const sourceRevision = String.fromEnvironment('ROK_SOURCE_REVISION');

String get effectiveSourceRevision =>
    sourceRevision.isEmpty ? 'master' : sourceRevision;

Uri sourceUriForRevision(String revision) =>
    Uri.parse('$sourceRepository/tree/$revision');

Uri get correspondingSourceUri => sourceUriForRevision(effectiveSourceRevision);

bool isValidSourceRevision(String revision) =>
    RegExp(r'^[0-9a-f]{40}$').hasMatch(revision);

/// A release binary must identify the exact public source tree used to build
/// it. Debug/profile builds may use the moving `master` branch for convenience.
void verifyReleaseSourceIsPinned() {
  if (kReleaseMode && !isValidSourceRevision(sourceRevision)) {
    throw StateError(
      'Release requires --dart-define=ROK_SOURCE_REVISION=<40-character public commit>',
    );
  }
}
