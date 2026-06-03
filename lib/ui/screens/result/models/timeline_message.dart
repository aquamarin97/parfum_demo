import 'package:flutter/material.dart';

/// Status of a single step in the result flow timeline.
enum TimelineMessageStatus {
  /// Step has not started yet.
  pending,

  /// Step is currently in progress.
  active,

  /// Step completed successfully.
  completed,

  /// Step failed.
  error,
}

/// An immutable snapshot of a single timeline step.
///
/// [timestamp] defaults to [DateTime.now] when not provided.
/// [copyWith] preserves the original [timestamp] so steps do not appear
/// to restart when their status changes.
@immutable
class TimelineMessage {
  const TimelineMessage({
    required this.text,
    this.status = TimelineMessageStatus.pending,
    required this.timestamp,
  });

  /// Factory that stamps the message with the current time.
  factory TimelineMessage.now({
    required String text,
    TimelineMessageStatus status = TimelineMessageStatus.pending,
  }) => TimelineMessage(text: text, status: status, timestamp: DateTime.now());

  final String text;
  final TimelineMessageStatus status;
  final DateTime timestamp;

  TimelineMessage copyWith({String? text, TimelineMessageStatus? status}) {
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