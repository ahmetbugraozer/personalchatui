import 'dart:async';
import '../models/chat_message.dart';
import '../enums/app.enum.dart';

/// Represents a token from either thinking or response phase
class StreamToken {
  final String text;
  final bool isThinking;

  const StreamToken(this.text, {this.isThinking = false});
}

class ChatService {
  // Simulated streaming completion: yields tokens gradually
  // When thinking is enabled, first yields thinking tokens, then response tokens
  Stream<StreamToken> streamCompletionWithThinking({
    required String prompt,
    List<Attachment> attachments = const [],
    bool thinking = false,
  }) async* {
    if (thinking) {
      // Simulate thinking phase
      final thinkingContent = _generateThinkingContent(prompt);
      final thinkingTokens = _tokenize(thinkingContent);

      for (final t in thinkingTokens) {
        await Future.delayed(Duration(milliseconds: 25 + (t.length % 2) * 20));
        yield StreamToken(t, isThinking: true);
      }

      // Small pause between thinking and response
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // Generate and stream response
    final p = prompt.trim();
    final base =
        '${AppStrings.responseIntro} '
        '${AppStrings.responseDash} '
        '$p ${AppStrings.responseAboutSuffix} '
        '${AppStrings.responseOutro}';
    final tokens = _tokenize(base);

    for (final t in tokens) {
      await Future.delayed(Duration(milliseconds: 30 + (t.length % 3) * 40));
      yield StreamToken(t, isThinking: false);
    }
  }

  // Legacy method for backward compatibility
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

  String _generateThinkingContent(String prompt) {
    // Simulated thinking process
    return 'Kullanıcının sorusunu analiz ediyorum... '
        '"$prompt" hakkında düşünüyorum. '
        'İlgili bilgileri topluyorum ve en iyi yanıtı oluşturuyorum. '
        'Farklı açıları değerlendiriyorum...';
  }

  Iterable<String> _tokenize(String text) sync* {
    // Simple whitespace tokenization but keep spacing
    final parts = text.split(' ');
    for (var i = 0; i < parts.length; i++) {
      yield (i == 0 ? '' : ' ') + parts[i];
    }
  }
}
