import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/message.dart';
import '../services/gemini_service.dart';
import 'chat_state.dart';

/// Cubit que maneja la logica del chat.
/// QUE ES UN CUBIT?
/// - Es una clase que gestiona estados
/// - Recibe "acciones" (llamadas a metodos)
/// - Emite nuevos "estados" cuando algo cambia
/// - La UI escucha estos estados y se actualiza
///
/// FLUJO:
/// 1. UI llama a sendMessage("hola")
/// 2. Cubit agrega el mensaje del usuario a la lista
/// 3. Cubit emite ChatLoading (UI muestra "escribiendo...")
/// 4. Cubit llama a GeminiService
/// 5. Cuando llega la respuesta, agrega mensaje de IA
/// 6. Cubit emite ChatLoaded (UI muestra todos los mensajes)
class ChatCubit extends Cubit<ChatState> {
  /// Servicio para comunicarse con Gemini
  final GeminiService _geminiService;

  /// Lista de mensajes de la conversacion (en memoria)
  final List<Message> _messages = [];

  /// Constructor: inicializa con el estado inicial y el servicio
  ChatCubit(this._geminiService) : super(ChatInitial());

  /// Envia un mensaje y obtiene la respuesta de la IA.
  ///
  /// Este metodo es async porque necesita esperar la respuesta de la API.
  Future<void> sendMessage(String text) async {
    // Ignoramos mensajes vacios
    if (text.trim().isEmpty) return;

    // 1. Agregamos el mensaje del usuario a nuestra lista
    _messages.add(Message(text: text, isUser: true, timestamp: DateTime.now()));

    // 2. Emitimos estado de carga con los mensajes actuales
    //    Esto permite a la UI mostrar los mensajes + indicador de carga
    emit(ChatLoading(List.from(_messages)));

    try {
      // 3. Llamamos al servicio pasando la lista completa para contexto
      final response = await _geminiService.sendMessage(_messages);

      // 4. Agregamos la respuesta de la IA a la lista
      _messages.add(
        Message(text: response, isUser: false, timestamp: DateTime.now()),
      );

      // 5. Emitimos el nuevo estado con todos los mensajes
      //    List.from() crea una copia para asegurar que Equatable
      //    detecte el cambio (nueva referencia)
      emit(ChatLoaded(List.from(_messages)));
    } catch (e) {
      // Si hay error, emitimos estado de error con el mensaje
      emit(ChatError(e.toString(), List.from(_messages)));
    }
  }

  /// Limpia el chat y vuelve al estado inicial.
  void clearChat() {
    _messages.clear();
    emit(ChatInitial());
  }
}
