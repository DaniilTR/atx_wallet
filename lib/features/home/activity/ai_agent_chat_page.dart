import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:atx_wallet/services/ai_assistant_service.dart';
import 'package:atx_wallet/services/config.dart';

class AiAgentChatPage extends StatefulWidget {
  const AiAgentChatPage({super.key});

  @override
  State<AiAgentChatPage> createState() => _AiAgentChatPageState();
}

class _AiAgentChatPageState extends State<AiAgentChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final AiAssistantService _service;

  bool _isSending = false;
  final List<_ChatMessage> _messages = <_ChatMessage>[
    const _ChatMessage(
      isIncoming: true,
      text:
          'Привет! Я AI-ассистент кошелька. Могу подсказать по переводам, комиссиям и безопасности.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _service = AiAssistantService();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? presetText]) async {
    if (_isSending) return;

    final text = (presetText ?? _controller.text).trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(isIncoming: false, text: text));
      _isSending = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final reply = await _service.sendMessage(text);
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(isIncoming: true, text: reply));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(
            isIncoming: true,
            text: 'Не удалось получить ответ: $e',
            isError: true,
          ),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark
        ? const Color(0xFF9FB0E1)
        : const Color(0xFF475569);

    final aiEnabled =
        kEnableAiAssistant && kAiAssistantEndpoint.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Назад',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4D6CFF), Color(0xFF2F4BFF)],
                      ),
                    ),
                    child: const Icon(
                      Icons.psychology_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Агент',
                          style: GoogleFonts.inter(
                            color: primaryTextColor,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          aiEnabled ? 'online' : 'disabled',
                          style: GoogleFonts.inter(
                            color: aiEnabled
                                ? const Color(0xFF22C55E)
                                : secondaryTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (!aiEnabled)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Отключён в этой сборке',
                              style: GoogleFonts.inter(
                                color: secondaryTextColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                itemCount: _messages.length + 2,
                itemBuilder: (context, index) {
                  if (index < _messages.length) {
                    final msg = _messages[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MessageBubble(
                        isIncoming: msg.isIncoming,
                        text: msg.text,
                        isError: msg.isError,
                      ),
                    );
                  }
                  if (index == _messages.length) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 6),
                        Text(
                          'Быстрые действия',
                          style: GoogleFonts.inter(
                            color: secondaryTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _QuickActionChip(
                              text: 'Что такое крипта?',
                              onTap: (!aiEnabled || _isSending)
                                  ? null
                                  : () => _sendMessage('Что такое крипта?'),
                            ),
                            _QuickActionChip(
                              text: 'Как снизить комиссию?',
                              onTap: (!aiEnabled || _isSending)
                                  ? null
                                  : () => _sendMessage(
                                      'Как снизить комиссию при переводе?',
                                    ),
                            ),
                            _QuickActionChip(
                              text: 'Проверка адреса',
                              onTap: (!aiEnabled || _isSending)
                                  ? null
                                  : () => _sendMessage(
                                      'Как безопасно проверить адрес перед отправкой?',
                                    ),
                            ),
                            _QuickActionChip(
                              text: 'Сводка портфеля',
                              onTap: (!aiEnabled || _isSending)
                                  ? null
                                  : () => _sendMessage(
                                      'Как сделать базовую сводку крипто-портфеля?',
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  }

                  return _isSending
                      ? const Padding(
                          padding: EdgeInsets.only(top: 8, bottom: 4),
                          child: _TypingIndicator(),
                        )
                      : const SizedBox.shrink();
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color.fromARGB(18, 255, 255, 255)
                    : Colors.white.withValues(alpha: .88),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? const Color(0x22FFFFFF)
                        : const Color(0x14000000),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      enabled: !_isSending && aiEnabled,
                      textInputAction: TextInputAction.send,
                      onSubmitted: aiEnabled ? (_) => _sendMessage() : null,
                      style: GoogleFonts.inter(
                        color: primaryTextColor,
                        fontSize: 14,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Напишите сообщение...',
                        hintStyle: GoogleFonts.inter(
                          color: secondaryTextColor,
                          fontSize: 14,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0x1FFFFFFF)
                            : const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark
                                ? const Color(0x55FFFFFF)
                                : const Color(0xFF9AB2FF),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: (!aiEnabled || _isSending) ? null : _sendMessage,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4D6CFF), Color(0xFF2F4BFF)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF4D6CFF,
                            ).withValues(alpha: 0.35),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: _isSending
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.isIncoming,
    required this.text,
    this.isError = false,
  });

  final bool isIncoming;
  final String text;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final bubbleColor = isError
        ? (isDark ? const Color(0x55B91C1C) : const Color(0xFFFEE2E2))
        : isIncoming
        ? (isDark ? const Color(0x1FFFFFFF) : const Color(0xFFE2E8F0))
        : const Color(0xFF3B82F6);

    final baseTextStyle = GoogleFonts.inter(
      color: isError
          ? (isDark ? const Color(0xFFFECACA) : const Color(0xFF991B1B))
          : isIncoming
          ? primaryTextColor
          : Colors.white,
      height: 1.35,
      fontSize: 14,
    );

    final shouldRenderMarkdown = isIncoming && !isError;

    return Align(
      alignment: isIncoming ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 290),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(isIncoming ? 4 : 14),
              bottomRight: Radius.circular(isIncoming ? 14 : 4),
            ),
          ),
          child: shouldRenderMarkdown
              ? MarkdownBody(
                  data: text,
                  styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                    p: baseTextStyle,
                    a: baseTextStyle.copyWith(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                    code: GoogleFonts.robotoMono(
                      textStyle: baseTextStyle.copyWith(
                        backgroundColor: isDark
                            ? Colors.white.withValues(alpha: 0.10)
                            : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    codeblockPadding: const EdgeInsets.all(10),
                    codeblockDecoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    blockquoteDecoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    blockquotePadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    listBullet: baseTextStyle,
                    h1: baseTextStyle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                    h2: baseTextStyle.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                    h3: baseTextStyle.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  onTapLink: (linkText, href, title) async {
                    if (href == null) return;
                    final uri = Uri.tryParse(href);
                    if (uri == null) return;
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                )
              : Text(text, style: baseTextStyle),
        ),
      ),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  const _QuickActionChip({required this.text, this.onTap});

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isDark ? const Color(0x1AFFFFFF) : const Color(0xFFEAF0FF),
          border: Border.all(
            color: isDark ? const Color(0x26FFFFFF) : const Color(0xFFCDDAFF),
          ),
        ),
        child: Text(
          text,
          style: GoogleFonts.inter(
            color: isDark ? const Color(0xFFE5EBFF) : const Color(0xFF2F4BFF),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFFBBD1FF) : const Color(0xFF7C8BB2),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFFBBD1FF) : const Color(0xFF7C8BB2),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFFBBD1FF) : const Color(0xFF7C8BB2),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.isIncoming,
    required this.text,
    this.isError = false,
  });

  final bool isIncoming;
  final String text;
  final bool isError;
}
