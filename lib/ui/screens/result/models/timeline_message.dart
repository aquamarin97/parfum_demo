import 'package:flutter/material.dart';

enum TimelineMessageStatus {
  pending,
  active,
  completed,
  error,
}

@immutable
class TimelineMessage {
  final String text;
  final TimelineMessageStatus status;
  final DateTime timestamp;

  TimelineMessage({
    required this.text,
    this.status = TimelineMessageStatus.pending,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  TimelineMessage copyWith({
    String? text,
    TimelineMessageStatus? status,
  }) {
    return TimelineMessage(
      text: text ?? this.text,
      status: status ?? this.status,
      timestamp: timestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelineMessage &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          status == other.status;

  @override
  int get hashCode => text.hashCode ^ status.hashCode;
}