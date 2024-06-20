import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

class QueryResult {
  final String word;
  final String definition;

  QueryResult({required this.word, required this.definition});
}

class DictionaryService extends GetxService {
  final Map<String, Map<String, String>> _dictionaries = {};
  final Map<String, String> _lemmaIndex = {};
  final RxList<String> _enabledDictionaries = <String>[].obs;
  final RxList<Map<String, String>> _customDictionaries =
      <Map<String, String>>[].obs;
  final RxList<String> _customDictionaryPaths = <String>[].obs;

  get enabledDictionariesList => _enabledDictionaries;
  get customDictionariesList => _customDictionaries;
  get dictionaries => _dictionaries;

  Future<void> loadDictionary() async {
    final dictionaryFiles = {
      'z8': 'assets/z8.csv',
      'zk': 'assets/zk.csv',
      'ielts': 'assets/ielts.csv',
      'gre': 'assets/gre.csv',
    };
    for (var entry in dictionaryFiles.entries) {
      final file = entry.value;
      final dictName = entry.key;
      final data = await rootBundle.loadString(file);
      final lines = const LineSplitter().convert(data);
      final Map<String, String> dict = {};
      for (var line in lines) {
        final parts = line.split(',');
        if (parts.length == 2) {
          dict[parts[0].trim()] = parts[1].trim();
        }
      }
      _dictionaries[dictName] = dict;
    }
  }

  Future<void> loadLemmaIndex() async {
    final data = await rootBundle.loadString('assets/lemma.en.txt');
    final lines = const LineSplitter().convert(data);
    for (var line in lines) {
      if (line.startsWith(';') || line.trim().isEmpty) continue;
      final parts = line.split('->');
      if (parts.length == 2) {
        final lemma = parts[0].split('/')[0].trim();
        final forms = parts[1].split(',').map((e) => e.trim()).toList();
        for (var form in forms) {
          _lemmaIndex[form] = lemma;
        }
      }
    }
  }

  Future<void> init() async {
    await loadDictionary();
    await loadLemmaIndex();
    await _loadSettings();
    await _loadCustomDictionaries();
  }

  QueryResult? lookup(String query) {
    String? definition;
    String word = query;

    for (var dictName in _enabledDictionaries) {
      final dict = _dictionaries[dictName] ?? {};
      definition = dict[query];
      if (definition != null) {
        return QueryResult(word: word, definition: definition);
      }

      // 尝试通过词形还原查找单词
      final lemma = _lemmaIndex[query];
      if (lemma != null) {
        definition = dict[lemma];
        if (definition != null) {
          word = lemma;
          return QueryResult(word: word, definition: definition);
        }
      }
    }

    // 尝试在自定义词典中查找
    for (var path in _customDictionaryPaths) {
      final customDict = _loadCustomDictionaryFromFile(path);
      if (customDict.containsKey(query)) {
        return QueryResult(word: query, definition: customDict[query]!);
      }
    }

    return null;
  }

  Future<void> _loadSettings() async {
    final directory = await getApplicationDocumentsDirectory();
    final settingsFile = File('${directory.path}/settings.json');
    if (settingsFile.existsSync()) {
      final settingsData = jsonDecode(await settingsFile.readAsString());
      _enabledDictionaries.value =
          List<String>.from(settingsData['enabledDictionaries'] ?? []);
      _customDictionaryPaths.value =
          List<String>.from(settingsData['customDictionaryPaths'] ?? []);
    }
  }

  Future<void> saveSettings() async {
    final directory = await getApplicationDocumentsDirectory();
    final settingsFile = File('${directory.path}/settings.json');
    final settingsData = {
      'enabledDictionaries': _enabledDictionaries,
      'customDictionaryPaths': _customDictionaryPaths,
    };
    await settingsFile.writeAsString(jsonEncode(settingsData));
  }

  void addCustomDictionary(String filePath) {
    _customDictionaryPaths.add(filePath);
    saveSettings();
  }

  void removeCustomDictionary(String filePath) {
    _customDictionaryPaths.remove(filePath);
    saveSettings();
  }

  void toggleDictionary(String dictionary) {
    if (_enabledDictionaries.contains(dictionary)) {
      _enabledDictionaries.remove(dictionary);
    } else {
      _enabledDictionaries.add(dictionary);
    }
    saveSettings();
  }

  List<String> get enabledDictionaries => _enabledDictionaries;
  List<String> get customDictionaryPaths => _customDictionaryPaths;

  Future<void> _loadCustomDictionaries() async {
    for (var path in _customDictionaryPaths) {
      await _loadCustomDictionaryFromFile(path);
    }
  }

  Map<String, String> _loadCustomDictionaryFromFile(String path) {
    final File file = File(path);
    final lines = file.readAsLinesSync();
    final Map<String, String> dict = {};
    for (var line in lines) {
      final parts = line.split(',');
      if (parts.length == 2) {
        dict[parts[0].trim()] = parts[1].trim();
      }
    }
    return dict;
  }
}
