import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dictionary_service.dart';

class DictionarySettingsScreen extends StatelessWidget {
  final DictionaryService dictionaryService = Get.find<DictionaryService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('管理词典'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(
              () => ListView(
                children:
                    dictionaryService.dictionaries.keys.map<Widget>((dict) {
                  return CheckboxListTile(
                    title: Text(dict),
                    tileColor: Colors.white60,
                    value: dictionaryService.enabledDictionaries.contains(dict),
                    onChanged: (bool? value) {
                      if (value != null) {
                        dictionaryService.toggleDictionary(dict);
                      }
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          ListTile(
            title: Text('添加自定义词典'),
            onTap: () => _pickAndAddCustomDictionary(context),
          ),
          Expanded(
            child: Obx(
              () => ListView(
                children: dictionaryService.customDictionaryPaths.map((path) {
                  return ListTile(
                    title: Text(path.split('/').last), // 显示文件名
                    subtitle: Text(path),
                    tileColor: Colors.white60,
                    trailing: IconButton(
                      icon: Icon(Icons.delete),
                      onPressed: () =>
                          dictionaryService.removeCustomDictionary(path),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _pickAndAddCustomDictionary(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null && result.files.single.path != null) {
      String filePath = result.files.single.path!;
      dictionaryService.addCustomDictionary(filePath);
      Get.snackbar('成功', '自定义词典已添加：$filePath',
          snackPosition: SnackPosition.BOTTOM);
    } else {
      Get.snackbar('错误', '未选择任何文件', snackPosition: SnackPosition.BOTTOM);
    }
  }
}
