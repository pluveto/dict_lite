import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:dict_lite/SearchTextField.dart';
import 'package:dict_lite/dictionary_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dictionary_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Get.putAsync<DictionaryService>(() async {
    var svc = DictionaryService();
    await svc.init();
    return svc;
  });
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'DictLite 极简词典',
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.white,
          brightness: Brightness.light,
          background: Colors.white,
        ),
        // titlestyle
        appBarTheme: AppBarTheme(
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
          ),
        ),
        // textTheme: Theme.of(context).textTheme.apply(
        //       fontSizeFactor: 0.85, // 缩小字体大小
        //     ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with ClipboardListener {
  final TextEditingController wordController = TextEditingController();
  final Rx<QueryResult?> queryResult = Rx<QueryResult?>(null);
  final RxString clipboardText = ''.obs;
  final RxBool isClipboardListening = true.obs;
  late DictionaryService dictionaryService;

  @override
  void initState() {
    super.initState();
    dictionaryService = Get.find<DictionaryService>();

    wordController.addListener(() {
      final word = wordController.text.trim();
      queryResult.value = doQuery(word);
    });

    if (isClipboardListening.value) {
      clipboardWatcher.addListener(this);
      clipboardWatcher.start();
    }
  }

  @override
  void dispose() {
    if (isClipboardListening.value) {
      clipboardWatcher.stop();
      clipboardWatcher.removeListener(this);
    }
    wordController.dispose();
    super.dispose();
  }

  QueryResult? doQuery(String word) {
    QueryResult? r;
    if (word.isNotEmpty) {
      final wordTrimed = word.trim();
      r = dictionaryService.lookup(wordTrimed);
      r = dictionaryService.lookup(wordTrimed.toLowerCase());
      r ??= QueryResult(word: '', definition: "“$word” 不在已知词典内。");
    } else {
      r = QueryResult(word: '', definition: "请输入要查询的单词");
    }
    return r;
  }

  @override
  void onClipboardChanged() async {
    if (!isClipboardListening.value) return;
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data == null || data.text == null || data.text!.length > 30) {
      return;
    }

    clipboardText.value = data.text!;
    var r = doQuery(data.text!);
    if (r != null) {
      queryResult.value = r;
    }
  }

  void toggleClipboardListening() {
    if (isClipboardListening.value) {
      clipboardWatcher.stop();
      clipboardWatcher.removeListener(this);
    } else {
      clipboardWatcher.addListener(this);
      clipboardWatcher.start();
    }
    isClipboardListening.toggle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('DictLite 极简词典'),
      //   actions: [
      //     PopupMenuButton<String>(
      //       onSelected: (String result) {
      //         switch (result) {
      //           case 'toggleClipboard':
      //             toggleClipboardListening();
      //             break;
      //           case 'manageDictionaries':
      //             Get.to(() => DictionarySettingsScreen());
      //             break;
      //         }
      //       },
      //       itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
      //         CheckedPopupMenuItem<String>(
      //           value: 'toggleClipboard',
      //           checked: isClipboardListening.value,
      //           child: Text('监听剪贴板'),
      //         ),
      //         PopupMenuItem<String>(
      //           value: 'manageDictionaries',
      //           child: Text('管理词典'),
      //         ),
      //       ],
      //     ),
      //   ],
      // ),
      appBar: null,
      body: SafeArea(
        child: Container(
          width: 400,
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            children: [
              SearchTextField(
                controller: wordController,
              ),
              Expanded(
                child: Obx(() => queryResult.value != null
                    ? SingleChildScrollView(
                        child: Column(
                        children: [
                          Text(
                            queryResult.value!.word,
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            queryResult.value!.definition,
                            style: TextStyle(fontSize: 18),
                          )
                        ],
                      ))
                    : Text('请输入单词')),
              ),
              Container(
                child: Row(
                  children: [
                    Text('监听剪贴板', style: TextStyle(fontSize: 12)),
                    Transform.scale(
                      scale: 0.5,
                      child: Obx(
                        () => Switch(
                          value: isClipboardListening.value,
                          onChanged: (bool value) {
                            toggleClipboardListening();
                          },
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
