/*
 * SPDX-FileCopyrightText: 2019-2021 Vishesh Handa <me@vhanda.in>
 *
 * SPDX-License-Identifier: AGPL-3.0-or-later
 */

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gitjournal/l10n.dart';
import 'package:gitjournal/settings/settings.dart';
import 'package:gitjournal/settings/settings_bottom_menu_bar.dart';
import 'package:gitjournal/settings/settings_display_images.dart';
import 'package:gitjournal/settings/settings_misc.dart';
import 'package:gitjournal/settings/settings_screen.dart';
import 'package:gitjournal/settings/settings_theme.dart';
import 'package:gitjournal/settings/widgets/language_selector.dart';
import 'package:gitjournal/settings/widgets/settings_header.dart';
import 'package:gitjournal/settings/widgets/settings_list_preference.dart';
import 'package:gitjournal/widgets/pro_overlay.dart';
import 'package:provider/provider.dart';

const feature_themes = false;

class SettingsUIScreen extends StatelessWidget {
  static const routePath = '/settings/ui';

  const SettingsUIScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var settings = Provider.of<Settings>(context);

    var list = ListView(
      children: [
        SettingsHeader(context.loc.settingsDisplayTitle),
        ListPreference(
          title: context.loc.settingsDisplayTheme,
          currentOption: settings.theme.toPublicString(context),
          options: SettingsTheme.options
              .map((f) => f.toPublicString(context))
              .toList(),
          onChange: (String publicStr) {
            var s = SettingsTheme.fromPublicString(context, publicStr);
            settings.theme = s;
            settings.save();
          },
        ),
        if (feature_themes)
          SettingsTile(
            title: context.loc.settingsThemeLight,
            iconData: FontAwesomeIcons.sun,
            onTap: () {
              var route = MaterialPageRoute(
                builder: (context) =>
                    const SettingsThemeScreen(Brightness.light),
                settings:
                    const RouteSettings(name: SettingsThemeScreen.routePath),
              );
              var _ = Navigator.push(context, route);
            },
          ),
        if (feature_themes)
          SettingsTile(
            title: context.loc.settingsThemeDark,
            iconData: FontAwesomeIcons.solidMoon,
            onTap: () {
              var route = MaterialPageRoute(
                builder: (context) =>
                    const SettingsThemeScreen(Brightness.dark),
                settings:
                    const RouteSettings(name: SettingsThemeScreen.routePath),
              );
              var _ = Navigator.push(context, route);
            },
          ),
        const LanguageSelector(),
        ListTile(
          title: Text(context.loc.settingsDisplayImagesTitle),
          subtitle: Text(context.loc.settingsDisplayImagesSubtitle),
          onTap: () {
            var route = MaterialPageRoute(
              builder: (context) => SettingsDisplayImagesScreen(),
              settings: const RouteSettings(
                name: SettingsDisplayImagesScreen.routePath,
              ),
            );
            var _ = Navigator.push(context, route);
          },
        ),
        ProOverlay(
          child: ListPreference(
            title: context.loc.settingsDisplayHomeScreen,
            currentOption: settings.homeScreen.toPublicString(context),
            options: SettingsHomeScreen.options
                .map((f) => f.toPublicString(context))
                .toList(),
            onChange: (String publicStr) {
              var s = SettingsHomeScreen.fromPublicString(context, publicStr);
              settings.homeScreen = s;
              settings.save();
            },
          ),
        ),
        ProOverlay(
          child: ListTile(
            title: Text(context.loc.settingsBottomMenuBarTitle),
            subtitle: Text(context.loc.settingsBottomMenuBarSubtitle),
            onTap: () {
              var route = MaterialPageRoute(
                builder: (context) => BottomMenuBarSettings(),
                settings:
                    const RouteSettings(name: BottomMenuBarSettings.routePath),
              );
              var _ = Navigator.push(context, route);
            },
          ),
        ),
        ListTile(
          title: Text(context.loc.settingsMiscTitle),
          onTap: () {
            var route = MaterialPageRoute(
              builder: (context) => SettingsMisc(),
              settings: const RouteSettings(name: SettingsMisc.routePath),
            );
            var _ = Navigator.push(context, route);
          },
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(context.loc.settingsListUserInterfaceTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: list,
    );
  }
}
