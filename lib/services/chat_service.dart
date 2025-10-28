import 'dart:async';
import '../models/chat_message.dart';
import '../enums/app.enum.dart';

class ChatService {
  // Simulated streaming completion: yields tokens gradually
  Stream<String> streamCompletion({
    required String prompt,
    List<Attachment> attachments = const [],
  }) async* {
    final p = prompt.trim();
    final base =
        '${AppStrings.responseIntro} '
        '${AppStrings.responseDash} '
        '$p ${AppStrings.responseAboutSuffix} '
        '${AppStrings.responseOutro}';
    final tokens = _tokenize(base);

    for (final t in tokens) {
      await Future.delayed(Duration(milliseconds: 30 + (t.length % 3) * 40));
      yield t;
    }
  }

  Iterable<String> _tokenize(String text) sync* {
    // Simple whitespace tokenization but keep spacing
    final parts = text.split(' ');
    for (var i = 0; i < parts.length; i++) {
      yield (i == 0 ? '' : ' ') + parts[i];
    }
  }
}
