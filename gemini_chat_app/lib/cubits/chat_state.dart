import 'package:equatable/equatable.dart';
import '../models/message.dart';

sealed class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {
  final List<Message> messages;

  const ChatLoading(this.messages);

  @override
  List<Object?> get props => [messages];
}

class ChatLoaded extends ChatState {
  final List<Message> messages;

  const ChatLoaded(this.messages);

  @override
  List<Object?> get props => [messages];
}

class ChatError extends ChatState {
  final String errorMessage;
  final List<Message> messages;

  const ChatError(this.errorMessage, this.messages);

  @override
  List<Object?> get props => [errorMessage, messages];
}
