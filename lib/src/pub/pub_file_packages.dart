import 'dart:io';

import '../common/package.dart';
import '../common/utils.dart' as utils;
import '../common/workspace.dart';
import '../pub/pub_file.dart';

class PackagesPubFile extends PubFile {
  Map<String, String> _entries;

  Map<String, String> get entries {
    if (_entries != null) return _entries;

    var input = File(filePath).readAsStringSync();

    // ignore: omit_local_variable_types
    Map<String, String> packages = {};

    final regex = RegExp('^([a-z_A-Z0-9-]*):(.*)\$', multiLine: true);

    regex.allMatches(input).forEach((match) {
      return packages[match[1]] = match[2];
    });

    _entries = packages;
    return _entries;
  }

  PackagesPubFile._(String rootDirectory) : super(rootDirectory, '.packages');

  factory PackagesPubFile.fromDirectory(String fileRootDirectory) {
    return PackagesPubFile._(fileRootDirectory);
  }

  factory PackagesPubFile.fromWorkspacePackage(
      MelosWorkspace workspace, MelosPackage package) {
    var workspacePackagesPubFile =
        PackagesPubFile.fromDirectory(workspace.path);

    // ignore: omit_local_variable_types
    Map<String, String> newEntries = {};
    var dependencyGraph = package.getDependencyGraph();

    workspacePackagesPubFile.entries.forEach((name, path) {
      if (!dependencyGraph.contains(name)) {
        return;
      }

      var _path = path;
      if (!path.startsWith('file://')) {
        // path is relative to the workspace root, make it relative to the package
        _path = utils.relativePath(
            '${workspace.path}${Platform.pathSeparator}$_path', package.path);
      }

      newEntries[name] = _path;
    });

    var packagesFile = PackagesPubFile._(package.path);
    packagesFile._entries = newEntries;
    return packagesFile;
  }

  @override
  String toString() {
    var string = '# Generated by pub on ${DateTime.now().toString()}';
    _entries.forEach((key, value) {
      string += '\n$key:$value';
    });
    return string;
  }
}
