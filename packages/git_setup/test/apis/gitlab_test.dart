/*
 * SPDX-FileCopyrightText: 2019-2021 Vishesh Handa <me@vhanda.in>
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:test/test.dart';

import 'package:git_setup/apis/githost_factory.dart';
import 'package:git_setup/apis/gitlab.dart';
import 'lib.dart';

void main() {
  setUpAll(gjSetupAllTests);

  test('Parse json', () async {
    var testDataPath = '';

    var currentDir = Directory.current;
    var folderName = basename(currentDir.path);

    if (folderName == 'test') {
      testDataPath = join(currentDir.path, 'apis/data/gitlab.json');
    } else {
      testDataPath = join(currentDir.path, 'test/apis/data/gitlab.json');
    }

    var jsonString = File(testDataPath).readAsStringSync();

    List<dynamic> list = jsonDecode(jsonString);
    var repos = <GitHostRepo>[];
    for (var d in list) {
      var map = Map<String, dynamic>.from(d);
      var repo = GitLab.repoFromJson(map);
      repos.add(repo);
    }

    expect(repos.length, 2);
  });
}
