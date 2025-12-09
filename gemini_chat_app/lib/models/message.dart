/* Modelo de datos para un mensaje en el chat
/// Propiedades:
/// - text: contenido del mensaje
/// - isUser: true si el mensaje es del usuario, false si es del bot
/// - timestamp: momento en que se genero el mensaje
*/

class Message {
  /// El texto del mensaje
  final String text;

  /// Indica si el mensaje es del usuario (true) o del bot (false)
  final bool isUser;

  /// Fecha y hora de creación del mensaje
  final DateTime timestamp;

  /// Constructor para crear una instancia de Message
  Message({required this.text, required this.isUser, required this.timestamp});
}
