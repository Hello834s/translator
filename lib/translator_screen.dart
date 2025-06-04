import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';  // <-- добавил
import 'history_screen.dart';

class TranslatorScreen extends StatefulWidget {
  @override
  _TranslatorScreenState createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  final TextEditingController _textController = TextEditingController();
  String _translatedText = '';
  String _fromLang = 'en';
  String _toLang = 'es';

  final List<Map<String, String>> _languages = [
    {'code': 'en', 'name': 'English'},
    {'code': 'es', 'name': 'Spanish'},
    {'code': 'fr', 'name': 'French'},
    {'code': 'de', 'name': 'German'},
    {'code': 'ru', 'name': 'Russian'},
  ];

  Future<void> translateText() async {
    if (_textController.text.trim().isEmpty) {
      setState(() {
        _translatedText = 'Введите текст для перевода';
      });
      return;
    }

    final text = Uri.encodeComponent(_textController.text);
    final uri = 'https://api.mymemory.translated.net/get?q=$text&langpair=$_fromLang|$_toLang';

    try {
      final response = await http.get(Uri.parse(uri));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translated = data['responseData']['translatedText'] ?? 'Ошибка';

        setState(() {
          _translatedText = translated;
        });

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          print('Пользователь не вошёл в систему. Перевод не сохранён.');
          return;
        }

        await FirebaseFirestore.instance.collection('translations').add({
          'original': _textController.text,
          'translated': translated,
          'from': _fromLang,
          'to': _toLang,
          'timestamp': FieldValue.serverTimestamp(),
          'userId': user.uid,
        });
      } else {
        setState(() {
          _translatedText = 'Ошибка при подключении к API';
        });
      }
    } catch (e) {
      setState(() {
        _translatedText = 'Ошибка: $e';
      });
    }
  }

  Widget buildLanguageSelector(String currentLang, void Function(String?) onChanged) {
    return DropdownButton<String>(
      value: currentLang,
      dropdownColor: Theme.of(context).colorScheme.surface,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      items: _languages.map((lang) {
        return DropdownMenuItem(
          value: lang['code'],
          child: Text(lang['name']!),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Переводчик'),
        actions: [
          IconButton(
            icon: Icon(Icons.history_outlined),
            tooltip: 'История',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.logout_outlined),
            tooltip: 'Выйти',
            onPressed: () async {
              await GoogleSignIn().signOut();            // <-- здесь
              await FirebaseAuth.instance.signOut();      // <-- и здесь
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Введите текст',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                buildLanguageSelector(_fromLang, (val) {
                  if (val != null) setState(() => _fromLang = val);
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward, color: colorScheme.primary),
                ),
                buildLanguageSelector(_toLang, (val) {
                  if (val != null) setState(() => _toLang = val);
                }),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: translateText,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('Перевести', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _translatedText.isEmpty ? 'Перевод появится здесь' : _translatedText,
                    style: TextStyle(fontSize: 18, color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
