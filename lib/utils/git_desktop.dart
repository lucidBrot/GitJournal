/*
 * SPDX-FileCopyrightText: 2019-2021 Vishesh Handa <me@vhanda.in>
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

// GIT_SSH_COMMAND='ssh -i private_key_file -o IdentitiesOnly=yes' git clone user@host:repo.git

import 'dart:convert';

import 'package:dart_git/utils/file_extensions.dart';
import 'package:universal_io/io.dart';

import 'package:gitjournal/logger/logger.dart';
import 'package:gitjournal/settings/settings.dart';
import 'package:gitjournal/utils/result.dart';

Future<Result<void>> gitFetchViaExecutable({
  required String repoPath,
  required String privateKey,
  required String privateKeyPassword,
  required String remoteName,
}) =>
    _gitCommandViaExecutable(
      repoPath: repoPath,
      privateKey: privateKey,
      privateKeyPassword: privateKeyPassword,
      args: ["fetch", remoteName],
    );

Future<Result<void>> gitCloneViaExecutable({
  required String cloneUrl,
  required String repoPath,
  required String privateKey,
  required String privateKeyPassword,
}) =>
    _gitCommandViaExecutable(
      repoPath: null,
      privateKey: privateKey,
      privateKeyPassword: privateKeyPassword,
      args: ["clone", cloneUrl, repoPath],
    );

Future<Result<void>> gitPushViaExecutable({
  required String repoPath,
  required String privateKey,
  required String privateKeyPassword,
  required String remoteName,
}) =>
    _gitCommandViaExecutable(
      repoPath: repoPath,
      privateKey: privateKey,
      privateKeyPassword: privateKeyPassword,
      args: ["push", remoteName],
    );

Future<Result<void>> _gitCommandViaExecutable({
  required String? repoPath,
  required String privateKey,
  required String privateKeyPassword,
  required List<String> args,
}) async {
  if (repoPath != null) assert(repoPath.startsWith('/'));
  if (privateKeyPassword.isNotEmpty) {
    var ex = Exception("SSH Keys with passwords are not supported");
    return Result.fail(ex);
  }

  dynamic _;

  var dir = Directory.systemTemp.createTempSync();
  var temp = File("${dir.path}/key");
  _ = await temp.writeAsString(privateKey);
  temp.chmodSync(int.parse('0600', radix: 8));

  Log.i("Running git ${args.join(' ')}");
  var process = await Process.start(
    'git',
    args,
    workingDirectory: repoPath,
    environment: {
      if (privateKey.isNotEmpty)
        'GIT_SSH_COMMAND': 'ssh -i ${temp.path} -o IdentitiesOnly=yes',
    },
  );

  Log.d('env GIT_SSH_COMMAND="ssh -i ${temp.path} -o IdentitiesOnly=yes"');
  Log.d("git ${args.join(' ')}");

  var exitCode = await process.exitCode;
  _ = await dir.delete(recursive: true);

  var stdoutB = <int>[];
  await for (var d in process.stdout) {
    stdoutB.addAll(d);
  }
  var stdout = utf8.decode(stdoutB);

  if (exitCode != 0) {
    var ex = Exception("Failed to fetch - $stdout - exitCode: $exitCode");
    return Result.fail(ex);
  }

  return Result(null);
}

// Default branch - git remote show origin | grep 'HEAD branch'
Future<Result<String>> gitDefaultBranchViaExecutable({
  required String repoPath,
  required String privateKey,
  required String privateKeyPassword,
  required String remoteName,
}) async {
  assert(repoPath.startsWith('/'));
  if (privateKeyPassword.isNotEmpty) {
    var ex = Exception("SSH Keys with passwords are not supported");
    return Result.fail(ex);
  }

  dynamic _;

  var dir = Directory.systemTemp.createTempSync();
  var temp = File("${dir.path}/key");
  _ = await temp.writeAsString(privateKey);
  temp.chmodSync(int.parse('0600', radix: 8));

  var process = await Process.start(
    'git',
    [
      'remote',
      'show',
      remoteName,
    ],
    workingDirectory: repoPath,
    environment: {
      if (privateKey.isNotEmpty)
        'GIT_SSH_COMMAND': 'ssh -i ${temp.path} -o IdentitiesOnly=yes',
    },
  );

  Log.d('env GIT_SSH_COMMAND="ssh -i ${temp.path} -o IdentitiesOnly=yes"');
  Log.d('git remote show $remoteName');

  var exitCode = await process.exitCode;
  _ = await dir.delete(recursive: true);

  if (exitCode != 0) {
    var ex = Exception("Failed to fetch default branch, exitCode: $exitCode");
    return Result.fail(ex);
  }

  var stdoutB = <int>[];
  await for (var d in process.stdout) {
    stdoutB.addAll(d);
  }
  var stdout = utf8.decode(stdoutB);
  for (var line in LineSplitter.split(stdout)) {
    if (line.contains('HEAD branch:')) {
      var branch = line.split(':')[1].trim();
      if (branch == '(unknown)') {
        return Result(DEFAULT_BRANCH);
      }
      return Result(branch);
    }
  }

  var ex = Exception('Default Branch not found');
  return Result.fail(ex);
}
