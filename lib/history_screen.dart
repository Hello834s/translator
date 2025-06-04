import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';  // <-- импорт для пользователя

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Пользователь не авторизован — можно показать сообщение или перенаправить
      return Scaffold(
        appBar: AppBar(title: Text('История переводов')),
        body: Center(child: Text('Пожалуйста, войдите в аккаунт, чтобы видеть историю')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('История переводов')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('translations')
            .where('userId', isEqualTo: user.uid)  // фильтр по userId
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('❌ Firestore ошибка: ${snapshot.error}');
            return Center(child: Text('Ошибка загрузки данных'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            print('ℹ️ Нет данных в истории');
            return Center(child: Text('История пуста'));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              try {
                final data = docs[index].data() as Map<String, dynamic>;
                final original = data['original'] ?? '';
                final translated = data['translated'] ?? '';
                final from = data['from'] ?? '';
                final to = data['to'] ?? '';
                final timestamp = data['timestamp'] as Timestamp?;
                final formattedTime = timestamp != null
                    ? DateFormat('dd.MM.yyyy HH:mm').format(timestamp.toDate())
                    : 'Без времени';

                return ListTile(
                  title: Text('$original → $translated'),
                  subtitle: Text('[$from → $to] • $formattedTime'),
                );
              } catch (e) {
                print('❌ Ошибка при обработке документа: $e');
                return ListTile(
                  title: Text('Ошибка при отображении'),
                  subtitle: Text('Документ повреждён'),
                );
              }
            },
          );
        },
      ),
    );
  }
}
