import 'package:flutter/material.dart';

import '../../../core/models/portfolio_models.dart';
import '../../shared/section_card.dart';

class AssistantTab extends StatefulWidget {
  const AssistantTab({
    super.key,
    required this.messages,
    required this.onSend,
    required this.isProcessing,
  });

  final List<AssistantMessage> messages;
  final Future<void> Function(String) onSend;
  final bool isProcessing;

  @override
  State<AssistantTab> createState() => _AssistantTabState();
}

class _AssistantTabState extends State<AssistantTab> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant AssistantTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length != oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SectionCard(
              title: 'Conversational Wealth Brain',
              subtitle: 'Ask natural language questions and get explainable actions',
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: widget.messages.length,
                      itemBuilder: (context, index) {
                        final message = widget.messages[index];
                        final isUser = message.role == AssistantRole.user;
                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                            child: Card(
                              color: isUser
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceVariant.withOpacity(0.6),
                              elevation: 0,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.content,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: isUser
                                            ? theme.colorScheme.onPrimary
                                            : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    if (!isUser && message.rationale != null) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        'Why this matters',
                                        style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(message.rationale!),
                                    ],
                                    if (!isUser && message.supportingData.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        children: message.supportingData
                                            .map(
                                              (data) => Chip(
                                                avatar: const Icon(Icons.insights, size: 16),
                                                label: Text(data),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ],
                                    if (!isUser && message.confidence != null) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const Icon(Icons.shield_moon_outlined, size: 18),
                                          const SizedBox(width: 6),
                                          Text('Confidence ${(message.confidence! * 100).toStringAsFixed(0)}%'),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      children: [
                        _suggestionChip('Optimize my portfolio for 8% return at medium risk'),
                        _suggestionChip('Run a stress test for oil price shock'),
                        _suggestionChip('Show budget insights for this month'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (widget.isProcessing)
                    const LinearProgressIndicator(minHeight: 4),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Ask anything about your investments or finances...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        onPressed: widget.isProcessing ? null : _handleSend,
                        icon: const Icon(Icons.send),
                        label: const Text('Send'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _suggestionChip(String text) {
    return ActionChip(
      label: Text(text),
      onPressed: () {
        _controller.text = text;
        _controller.selection = TextSelection.fromPosition(TextPosition(offset: text.length));
      },
    );
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await widget.onSend(text);
    _controller.clear();
  }
}
