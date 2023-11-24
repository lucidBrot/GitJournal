/*
 * SPDX-FileCopyrightText: 2019-2021 Vishesh Handa <me@vhanda.in>
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:gitjournal/app.dart';
import 'package:gitjournal/error_reporting.dart';
import 'package:gitjournal/settings/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stack_trace/stack_trace.dart';

Future<void> main() async {

  FlutterError.onError = flutterOnErrorHandler;

  Isolate.current.addErrorListener(RawReceivePort((dynamic pair) async {
    var isolateError = pair as List<dynamic>;
    assert(isolateError.length == 2);
    assert(isolateError.first.runtimeType == Error);
    assert(isolateError.last.runtimeType == StackTrace);

    await reportError(isolateError.first, isolateError.last);
  }).sendPort);

  await runZonedGuarded(() async {
    await Chain.capture(() async {
      // ensureInitialized() must be run inside the same zone as runApp()
      //    which is inside the app.dart JournalApp.main()
      var _ = WidgetsFlutterBinding.ensureInitialized();
      var pref = await SharedPreferences.getInstance();
      AppConfig.instance.load(pref);

      if (Platform.isIOS || Platform.isAndroid) {
        // requires ensureInitialized() to have been run before.
        await FlutterDisplayMode.setHighRefreshRate();
      }

      await JournalApp.main(pref);
    });
  }, reportError);
}
