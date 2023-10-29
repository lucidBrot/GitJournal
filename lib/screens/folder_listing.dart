/*
 * SPDX-FileCopyrightText: 2019-2021 Vishesh Handa <me@vhanda.in>
 *
 * SPDX-License-Identifier: Apache-2.0
 */

import 'package:flutter/material.dart';
import 'package:gitjournal/core/folder/flattened_notes_folder.dart';
import 'package:gitjournal/core/folder/notes_folder.dart';
import 'package:gitjournal/core/folder/notes_folder_fs.dart';
import 'package:gitjournal/folder_views/folder_view.dart';
import 'package:gitjournal/l10n.dart';
import 'package:gitjournal/repository.dart';
import 'package:gitjournal/settings/app_config.dart';
import 'package:gitjournal/utils/utils.dart';
import 'package:gitjournal/widgets/app_bar_menu_button.dart';
import 'package:gitjournal/widgets/app_drawer.dart';
import 'package:gitjournal/widgets/folder_tree_view.dart';
import 'package:gitjournal/widgets/rename_dialog.dart';
import 'package:provider/provider.dart';

class FolderListingScreen extends StatefulWidget {
  static const routePath = '/folders';

  @override
  _FolderListingScreenState createState() => _FolderListingScreenState();
}

class _FolderListingScreenState extends State<FolderListingScreen> {
  final _folderTreeViewKey = GlobalKey<FolderTreeViewState>();
  NotesFolderFS? _selectedFolder;

  @override
  Widget build(BuildContext context) {
    final notesFolder = Provider.of<NotesFolderFS>(context);

    // Load experimental setting
    var settings = Provider.of<AppConfig>(context);

    var treeView = FolderTreeView(
      key: _folderTreeViewKey,
      rootFolder: notesFolder,
      onFolderEntered: (NotesFolderFS folder) {
        late NotesFolder destination;
        if (settings.experimentalSubfolders) {
          destination = FlattenedNotesFolder(folder, title: folder.name);
        } else {
          destination = folder;
        }

        var route = MaterialPageRoute(
          builder: (context) => FolderView(
            notesFolder: destination,
          ),
          settings: const RouteSettings(name: '/folder/'),
        );
        var _ = Navigator.push(context, route);
      },
      onFolderSelected: (folder) {
        setState(() {
          _selectedFolder = folder;
        });
      },
      onFolderUnselected: () {
        setState(() {
          _selectedFolder = null;
        });
      },
    );

    Widget? action;
    if (_selectedFolder != null) {
      action = PopupMenuButton(
        itemBuilder: (context) {
          return [
            PopupMenuItem<String>(
              value: "Rename",
              child: Text(context.loc.screensFoldersActionsRename),
            ),
            PopupMenuItem<String>(
              value: "Create",
              child: Text(context.loc.screensFoldersActionsSubFolder),
            ),
            PopupMenuItem<String>(
              value: "Delete",
              child: Text(context.loc.screensFoldersActionsDelete),
            ),
          ];
        },
        onSelected: (String value) async {
          if (value == "Rename") {
            if (_selectedFolder!.folderPath.isEmpty) {
              var _ = await showDialog(
                context: context,
                builder: (_) => RenameFolderErrorDialog(),
              );
              _folderTreeViewKey.currentState!.resetSelection();
              return;
            }
            var folderName = await showDialog(
              context: context,
              builder: (_) => RenameDialog(
                oldPath: _selectedFolder!.folderPath,
                inputDecoration: context.loc.screensFoldersActionsDecoration,
                dialogTitle: context.loc.screensFoldersActionsRename,
              ),
            );
            if (folderName is String) {
              var container = context.read<GitJournalRepo>();
              container.renameFolder(_selectedFolder!, folderName);
            }
          } else if (value == "Create") {
            var folderName = await showDialog(
              context: context,
              builder: (_) => CreateFolderAlertDialog(),
            );
            if (folderName is String) {
              var repo = context.read<GitJournalRepo>();
              var r = await repo.createFolder(_selectedFolder!, folderName);
              showResultError(context, r);
            }
          } else if (value == "Delete") {
            if (_selectedFolder!.hasNotesRecursive) {
              var _ = await showDialog(
                context: context,
                builder: (_) => DeleteFolderErrorDialog(),
              );
            } else {
              var container = context.read<GitJournalRepo>();
              container.removeFolder(_selectedFolder!);
            }
          }

          _folderTreeViewKey.currentState!.resetSelection();
        },
      );
    }

    var backButton = IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        _folderTreeViewKey.currentState!.resetSelection();
      },
    );

    var title = Text(context.loc.screensFoldersTitle);
    if (_selectedFolder != null) {
      title = Text(context.loc.screensFoldersSelected);
    }

    return Scaffold(
      appBar: AppBar(
        title: title,
        leading: _selectedFolder == null ? GJAppBarMenuButton() : backButton,
        actions: <Widget>[
          if (_selectedFolder != null) action!,
        ],
      ),
      body: Scrollbar(child: treeView),
      drawer: AppDrawer(),
      floatingActionButton: CreateFolderButton(),
    );
  }
}

class CreateFolderButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      key: const ValueKey("FAB"),
      onPressed: () async {
        var folderName = await showDialog(
          context: context,
          builder: (_) => CreateFolderAlertDialog(),
        );
        if (folderName is String) {
          var repo = context.read<GitJournalRepo>();
          final notesFolder =
              Provider.of<NotesFolderFS>(context, listen: false);

          var r = await repo.createFolder(notesFolder, folderName);
          showResultError(context, r);
        }
      },
      child: const Icon(Icons.add),
    );
  }
}

class CreateFolderAlertDialog extends StatefulWidget {
  @override
  _CreateFolderAlertDialogState createState() =>
      _CreateFolderAlertDialogState();
}

class _CreateFolderAlertDialogState extends State<CreateFolderAlertDialog> {
  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var form = Form(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextFormField(
            decoration: InputDecoration(
              labelText: context.loc.screensFoldersActionsDecoration,
            ),
            validator: (value) {
              if (value!.isEmpty) {
                return context.loc.screensFoldersActionsEmpty;
              }
              return "";
            },
            autofocus: true,
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.words,
            controller: _textController,
          ),
        ],
      ),
    );

    return AlertDialog(
      title: Text(context.loc.screensFoldersDialogTitle),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            context.loc.screensFoldersDialogDiscard,
          ),
        ),
        TextButton(
          onPressed: () {
            var newFolderName = _textController.text;
            return Navigator.of(context).pop(newFolderName);
          },
          child: Text(context.loc.screensFoldersDialogCreate),
        ),
      ],
      content: form,
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

class FolderErrorDialog extends StatelessWidget {
  final String content;

  const FolderErrorDialog(this.content);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.loc.screensFoldersErrorDialogTitle),
      content: Text(content),
      actions: <Widget>[
        TextButton(
          child: Text(context.loc.screensFoldersErrorDialogOk),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

class DeleteFolderErrorDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var text = context.loc.screensFoldersErrorDialogDeleteContent;
    return FolderErrorDialog(text);
  }
}

class RenameFolderErrorDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var text = context.loc.screensFoldersErrorDialogRenameContent;
    return FolderErrorDialog(text);
  }
}
