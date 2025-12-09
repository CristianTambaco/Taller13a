import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../cubits/chat_cubit.dart';
import '../cubits/chat_state.dart';
import '../models/message.dart';
import '../services/tts_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  /// Controlador para el campo de texto
  /// Nos permite leer el texto y limpiarlo después de enviar
  final TextEditingController _controller = TextEditingController();

  /// Controlador para el scroll de la lista
  /// Lo usamos para hacer scroll automático al último mensaje
  final ScrollController _scrollController = ScrollController();

  /// Servicio de texto a voz
  final TtsService _ttsService = TtsService();

  @override
  void dispose() {
    _ttsService.stop();
    // Limpiamos los controladores cuando se destruye el widget
    // Esto es importante para evitar memory leaks
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Hace scroll hasta el final de la lista
  void _scrollToBottom() {
    // Esperamos un frame para que la lista se actualice
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

  /// Envía el mensaje al Cubit
  void _sendMessage() {
    final text = _controller.text;
    if (text.isNotEmpty) {
      // Llamamos al método del Cubit
      context.read<ChatCubit>().sendMessage(text);
      // Limpiamos el campo de texto
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ===== APP BAR =====
      appBar: AppBar(
        title: const Text('Chat con Gemini AI'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          // Botón para limpiar el chat
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => context.read<ChatCubit>().clearChat(),
            tooltip: 'Limpiar chat',
          ),
        ],
      ),

      body: Column(
        children: [
          // ===== LISTA DE MENSAJES =====
          Expanded(
            // BlocBuilder reconstruye este widget cuando el estado cambia
            child: BlocBuilder<ChatCubit, ChatState>(
              builder: (context, state) {
                // Extraemos los mensajes según el tipo de estado
                final messages = switch (state) {
                  ChatInitial() => <Message>[],
                  ChatLoading(messages: var m) => m,
                  ChatLoaded(messages: var m) => m,
                  ChatError(messages: var m) => m,
                };

                // Si no hay mensajes, mostramos mensaje de bienvenida
                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          '¡Hola! Soy tu asistente de IA.',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Escribe un mensaje para comenzar.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                // Hacemos scroll al final cuando hay nuevos mensajes
                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length + (state is ChatLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Si estamos cargando y es el último item, mostramos indicador
                    if (state is ChatLoading && index == messages.length) {
                      return const _TypingIndicator();
                    }
                    // Si no, mostramos la burbuja del mensaje
                    return _MessageBubble(
                      message: messages[index],
                      onSpeak: messages[index].isUser
                          ? null
                          : () => _ttsService.speak(messages[index].text),
                    );
                  },
                );
              },
            ),
          ),

          // ===== INDICADOR DE ERROR =====
          BlocBuilder<ChatCubit, ChatState>(
            builder: (context, state) {
              if (state is ChatError) {
                return Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.red.shade100,
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Error: ${state.errorMessage}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // ===== CAMPO DE ENTRADA =====
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Campo de texto expandido
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      // Enviar con Enter
                      onSubmitted: (_) => _sendMessage(),
                      // Permitir múltiples líneas
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Botón de enviar
                  BlocBuilder<ChatCubit, ChatState>(
                    builder: (context, state) {
                      // Deshabilitamos el botón mientras carga
                      final isLoading = state is ChatLoading;
                      return FloatingActionButton(
                        onPressed: isLoading ? null : _sendMessage,
                        mini: true,
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para mostrar una burbuja de mensaje.
/// El estilo cambia según si es del usuario o de la IA.
class _MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onSpeak;

  const _MessageBubble({required this.message, this.onSpeak});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final timeText = _formatTime(message.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        // Usuario a la derecha, IA a la izquierda
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar de la IA (solo si no es usuario)
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: Colors.deepPurple.shade100,
              radius: 16,
              child: const Icon(
                Icons.smart_toy,
                size: 18,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Burbuja del mensaje
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isUser
                      ? Text(
                          message.text,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                          ),
                        )
                      : MarkdownBody(
                          data: message.text,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(color: Colors.black87),
                            h1: const TextStyle(
                              color: Colors.black87,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            h2: const TextStyle(
                              color: Colors.black87,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            h3: const TextStyle(
                              color: Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            code: TextStyle(
                              backgroundColor: Colors.grey.shade300,
                              fontFamily: 'monospace',
                            ),
                            strong: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                  if (!isUser && onSpeak != null) ...[
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: onSpeak,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.volume_up,
                            size: 18,
                            color: Colors.black54,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Escuchar',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Avatar del usuario (solo si es usuario)
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              radius: 16,
              child: const Icon(Icons.person, size: 18, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime ts) {
    final local = ts.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

/// Widget que muestra el indicador de "escribiendo...".
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.deepPurple.shade100,
            radius: 16,
            child: const Icon(
              Icons.smart_toy,
              size: 18,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Escribiendo', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
