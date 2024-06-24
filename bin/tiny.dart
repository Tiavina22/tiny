#!/usr/bin/env dart

import 'dart:io';
import 'package:args/args.dart';
import 'dart:convert';

// For terminal colors
import 'package:ansicolor/ansicolor.dart';

void main(List<String> arguments) {
  printTinyAsciiArt();

  final parser = ArgParser()
    ..addFlag('version', abbr: 'v', negatable: false, help: 'Display version')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Display help')
    ..addCommand('add')
    ..addCommand('list')
    ..addCommand('delete')
    ..addCommand('update')
    ..addCommand('search');

  final argResults = parser.parse(arguments);

  if (argResults['help'] as bool) {
    printHelp(parser);
    return;
  }

  if (argResults['version'] as bool) {
    print('Tiny version 1.1.0');
    return;
  }

  switch (argResults.command?.name) {
    case 'add':
      if (argResults.command!.rest.isEmpty) {
        printError('Please provide the note text.');
      } else {
        addNote(argResults.command!.rest.join(' '));
      }
      break;
    case 'list':
      listNotes();
      break;
    case 'delete':
      if (argResults.command!.rest.isEmpty) {
        printError('Please provide the ID of the note to delete.');
      } else {
        try {
          final id = int.parse(argResults.command!.rest[0]);
          confirmDeletion(id);
        } catch (e) {
          printError('Invalid ID. Please provide a numeric ID.');
        }
      }
      break;
    case 'update':
      if (argResults.command!.rest.length < 2) {
        printError('Please provide the ID of the note and the new text.');
      } else {
        try {
          final id = int.parse(argResults.command!.rest[0]);
          final newNote = argResults.command!.rest.sublist(1).join(' ');
          updateNote(id, newNote);
        } catch (e) {
          printError('Invalid ID. Please provide a numeric ID.');
        }
      }
      break;
    case 'search':
      if (argResults.command!.rest.isEmpty) {
        printError('Please provide the search keyword.');
      } else {
        searchNotes(argResults.command!.rest.join(' '));
      }
      break;
    default:
      printError('Unknown command. Use --help to see options.');
  }
}

void printHelp(ArgParser parser) {
  print('Usage:');
  print(parser.usage);
  print('Commands:');
  print('  add <note>          Add a new note');
  print('  list                List all notes');
  print('  delete <id>         Delete a note by its ID');
  print('  update <id> <note>  Update a note by its ID');
  print('  search <keyword>    Search notes by keyword');
}

void addNote(String note) {
  final notes = _loadNotes();
  final id = notes.isNotEmpty ? notes.keys.last + 1 : 1;
  notes[id] = note;
  _saveNotes(notes);
  printSuccess('Note added with ID $id.');
}

void listNotes() {
  final notes = _loadNotes();
  if (notes.isEmpty) {
    printWarning('No notes available.');
  } else {
    print('Available notes:');
    notes.forEach((id, note) {
      print('[$id] $note');
    });
  }
}

void deleteNote(int id) {
  final notes = _loadNotes();
  if (notes.containsKey(id)) {
    notes.remove(id);
    _saveNotes(notes);
    printSuccess('Note with ID $id deleted.');
  } else {
    printError('No note found with ID $id.');
  }
}

void confirmDeletion(int id) {
  stdout.write('Are you sure you want to delete the note with ID $id ? (y/N) ');
  final response = stdin.readLineSync();
  if (response != null && response.toLowerCase() == 'y') {
    deleteNote(id);
  } else {
    printWarning('Deletion canceled.');
  }
}

void updateNote(int id, String newNote) {
  final notes = _loadNotes();
  if (notes.containsKey(id)) {
    notes[id] = newNote;
    _saveNotes(notes);
    printSuccess('Note with ID $id updated.');
  } else {
    printError('No note found with ID $id.');
  }
}

void searchNotes(String keyword) {
  final notes = _loadNotes();
  final results =
      notes.entries.where((entry) => entry.value.contains(keyword)).toList();
  if (results.isEmpty) {
    printWarning('No notes found containing the keyword "$keyword".');
  } else {
    print('Search results for "$keyword" :');
    results.forEach((entry) {
      print('[$entry.key] $entry.value');
    });
  }
}

Map<int, String> _loadNotes() {
  final file = File('${Platform.environment['HOME']}/notes.json');
  if (file.existsSync()) {
    final jsonString = file.readAsStringSync();
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    return jsonMap
        .map((key, value) => MapEntry(int.parse(key), value as String));
  }
  return {};
}

void _saveNotes(Map<int, String> notes) {
  final file = File('${Platform.environment['HOME']}/notes.json');
  // Convert Map<int, String> to Map<String, String>
  final jsonMap = notes.map((key, value) => MapEntry(key.toString(), value));
  final jsonString = json.encode(jsonMap);
  file.writeAsStringSync(jsonString);
}

// Functions for colored messages
void printError(String message) {
  var pen = AnsiPen()..red();
  print(pen(message));
}

void printWarning(String message) {
  var pen = AnsiPen()..yellow();
  print(pen(message));
}

void printSuccess(String message) {
  var pen = AnsiPen()..green();
  print(pen(message));
}

void printTinyAsciiArt() {
  print(
      'Tiny is a command-line CLI note manager developed in Dart. It enables users to add, list, delete, update, and search notes stored locally in a JSON file. Each note is identified by a unique ID, providing basic yet effective management of textual information.');
  print('''
 #######   #####   #     #  #     #
    #        #     ##    #   #   #
    #        #     # #   #    # #
    #        #     #  #  #     #
    #        #     #   # #     #
    #        #     #    ##     #
    #      #####   #     #     #
''');
}
