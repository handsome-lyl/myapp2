import 'dart:async';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../widgets/page_body.dart';

class WebSocketPage extends StatefulWidget {
  const WebSocketPage({super.key});

  @override
  State<WebSocketPage> createState() => _WebSocketPageState();
}

class _WebSocketPageState extends State<WebSocketPage> {
  final TextEditingController _urlController = TextEditingController(
    text: 'wss://ws.postman-echo.com/raw',
  );
  final TextEditingController _messageController = TextEditingController();
  final List<_ChatMessage> _messages = <_ChatMessage>[];

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  String _status = '未连接';
  bool _connecting = false;

  @override
  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    _urlController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      return;
    }
    await _disconnect();
    setState(() {
      _connecting = true;
      _status = '连接中…';
    });
    try {
      final channel = WebSocketChannel.connect(Uri.parse(url));
      await channel.ready;
      _channel = channel;
      _subscription = channel.stream.listen(
        (dynamic data) => _addMessage(data.toString(), fromMe: false),
        onError: (Object error) {
          _addMessage('连接错误：$error', fromMe: false);
          if (mounted) {
            setState(() => _status = '错误');
          }
        },
        onDone: () {
          if (mounted) {
            setState(() => _status = '已断开');
          }
        },
        cancelOnError: false,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _connecting = false;
        _status = '已连接';
      });
      _addMessage('已连接：$url', fromMe: false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _connecting = false;
        _status = '连接失败';
      });
      _addMessage('连接失败：$error', fromMe: false);
    }
  }

  Future<void> _disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    final channel = _channel;
    _channel = null;
    await channel?.sink.close();
    if (mounted) {
      setState(() => _status = '未连接');
    }
  }

  void _send() {
    final text = _messageController.text.trim();
    final channel = _channel;
    if (text.isEmpty) {
      return;
    }
    if (channel == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('请先连接 WebSocket 服务器')));
      return;
    }
    channel.sink.add(text);
    _messageController.clear();
    _addMessage(text, fromMe: true);
  }

  void _addMessage(String text, {required bool fromMe}) {
    if (!mounted) {
      return;
    }
    setState(() {
      _messages.insert(
        0,
        _ChatMessage(text: text, fromMe: fromMe, time: DateTime.now()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('WebSocket')),
      body: PageBody(
        child: ListView(
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('连接地址', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _urlController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'WebSocket URL',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        ActionChip(
                          label: const Text('Postman Echo'),
                          onPressed: () => _urlController.text =
                              'wss://ws.postman-echo.com/raw',
                        ),
                        ActionChip(
                          label: const Text('echo.websocket.org'),
                          onPressed: () =>
                              _urlController.text = 'wss://echo.websocket.org',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        FilledButton.icon(
                          onPressed: _connecting ? null : _connect,
                          icon: const Icon(Icons.link),
                          label: const Text('连接'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _channel == null ? null : _disconnect,
                          icon: const Icon(Icons.link_off),
                          label: const Text('断开'),
                        ),
                        Chip(
                          avatar: const Icon(Icons.circle, size: 10),
                          label: Text(_status),
                          visualDensity: VisualDensity.compact,
                          labelStyle: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 420,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: _messages.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  '连接后发送消息，服务器会把内容原样回显。',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            )
                          : ListView.builder(
                              reverse: true,
                              padding: const EdgeInsets.all(12),
                              itemCount: _messages.length,
                              itemBuilder: (BuildContext context, int index) {
                                return _MessageBubble(
                                  message: _messages[index],
                                );
                              },
                            ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              enabled: _channel != null,
                              decoration: const InputDecoration(
                                hintText: '输入消息…',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onSubmitted: (String value) => _send(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: _channel == null ? null : _send,
                            icon: const Icon(Icons.send),
                            tooltip: '发送',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '11.5 要点：WebSocket 先通过 HTTP 握手升级协议，之后复用 TCP 长连接，'
                  '服务器可以主动推送消息。channel.stream 用于接收，channel.sink 用于发送。',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.fromMe,
    required this.time,
  });

  final String text;
  final bool fromMe;
  final DateTime time;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String two(int number) => number.toString().padLeft(2, '0');
    return Align(
      alignment: message.fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Card(
        color: message.fromMe ? theme.colorScheme.primaryContainer : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                message.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: message.fromMe
                      ? theme.colorScheme.onPrimaryContainer
                      : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${two(message.time.hour)}:${two(message.time.minute)}:'
                '${two(message.time.second)}',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
