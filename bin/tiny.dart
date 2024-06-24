#!/usr/bin/env dart

import 'dart:io';
import 'package:args/args.dart';
import 'dart:convert';

// Pour les couleurs dans le terminal
import 'package:ansicolor/ansicolor.dart';

void main(List<String> arguments) {
  printTinyAsciiArt();

  final parser = ArgParser()
    ..addFlag('version',
        abbr: 'v', negatable: false, help: 'Afficher la version')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Afficher l\'aide')
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
        printError('Veuillez fournir le texte de la note.');
      } else {
        addNote(argResults.command!.rest.join(' '));
      }
      break;
    case 'list':
      listNotes();
      break;
    case 'delete':
      if (argResults.command!.rest.isEmpty) {
        printError('Veuillez fournir l\'ID de la note à supprimer.');
      } else {
        try {
          final id = int.parse(argResults.command!.rest[0]);
          confirmDeletion(id);
        } catch (e) {
          printError('ID invalide. Veuillez fournir un ID numérique.');
        }
      }
      break;
    case 'update':
      if (argResults.command!.rest.length < 2) {
        printError('Veuillez fournir l\'ID de la note et le nouveau texte.');
      } else {
        try {
          final id = int.parse(argResults.command!.rest[0]);
          final newNote = argResults.command!.rest.sublist(1).join(' ');
          updateNote(id, newNote);
        } catch (e) {
          printError('ID invalide. Veuillez fournir un ID numérique.');
        }
      }
      break;
    case 'search':
      if (argResults.command!.rest.isEmpty) {
        printError('Veuillez fournir le mot-clé de recherche.');
      } else {
        searchNotes(argResults.command!.rest.join(' '));
      }
      break;
    default:
      printError('Commande inconnue. Utilisez --help pour voir les options.');
  }
}

void printHelp(ArgParser parser) {
  print('Utilisation :');
  print(parser.usage);
  print('Commandes :');
  print('  add <note>          Ajouter une nouvelle note');
  print('  list                Afficher toutes les notes');
  print('  delete <id>         Supprimer une note par son ID');
  print('  update <id> <note>  Mettre à jour une note par son ID');
  print('  search <keyword>    Rechercher des notes par mot-clé');
}

void addNote(String note) {
  final notes = _loadNotes();
  final id = notes.isNotEmpty ? notes.keys.last + 1 : 1;
  notes[id] = note;
  _saveNotes(notes);
  printSuccess('Note ajoutée avec l\'ID $id.');
}

void listNotes() {
  final notes = _loadNotes();
  if (notes.isEmpty) {
    printWarning('Aucune note disponible.');
  } else {
    print('Notes disponibles :');
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
    printSuccess('Note avec l\'ID $id supprimée.');
  } else {
    printError('Aucune note trouvée avec l\'ID $id.');
  }
}

void confirmDeletion(int id) {
  stdout.write(
      'Êtes-vous sûr de vouloir supprimer la note avec l\'ID $id ? (y/N) ');
  final response = stdin.readLineSync();
  if (response != null && response.toLowerCase() == 'y') {
    deleteNote(id);
  } else {
    printWarning('Suppression annulée.');
  }
}

void updateNote(int id, String newNote) {
  final notes = _loadNotes();
  if (notes.containsKey(id)) {
    notes[id] = newNote;
    _saveNotes(notes);
    printSuccess('Note avec l\'ID $id mise à jour.');
  } else {
    printError('Aucune note trouvée avec l\'ID $id.');
  }
}

void searchNotes(String keyword) {
  final notes = _loadNotes();
  final results =
      notes.entries.where((entry) => entry.value.contains(keyword)).toList();
  if (results.isEmpty) {
    printWarning('Aucune note trouvée contenant le mot-clé "$keyword".');
  } else {
    print('Résultats de la recherche pour "$keyword" :');
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
  // Convertir le Map<int, String> en Map<String, String>
  final jsonMap = notes.map((key, value) => MapEntry(key.toString(), value));
  final jsonString = json.encode(jsonMap);
  file.writeAsStringSync(jsonString);
}

// Fonctions pour les messages colorés
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
