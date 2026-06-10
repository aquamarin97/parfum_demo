import 'package:flutter/material.dart';
import 'package:parfume_app/core/strings/app_strings.dart';

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
    this.text,
    this.key,
    this.arg,
    this.status = TimelineMessageStatus.pending,
    required this.timestamp,
  }) : assert(text != null || key != null, 'text or key must be provided');

  /// Free-form text (used when no i18n key exists, e.g. error messages).
  factory TimelineMessage.now({
    String? text,
    String? key,
    String? arg,
    TimelineMessageStatus status = TimelineMessageStatus.pending,
  }) => TimelineMessage(
        text: text,
        key: key,
        arg: arg,
        status: status,
        timestamp: DateTime.now(),
      );

  /// Translatable i18n key. When present, [resolve] uses this instead of [text].
  final String? key;

  /// Optional suffix appended after the translated string (e.g. a tester number).
  final String? arg;

  /// Fallback plain text used when [key] is null (e.g. free-form error messages).
  final String? text;

  final TimelineMessageStatus status;
  final DateTime timestamp;

  /// Returns the display string for the current locale.
  String resolve(AppStrings strings) {
    if (key == null) return text!;
    final base = strings.t(key!);
    return arg != null ? '$base$arg' : base;
  }

  TimelineMessage copyWith({String? text, String? key, String? arg, TimelineMessageStatus? status}) {
    return TimelineMessage(
      text: text ?? this.text,
      key: key ?? this.key,
      arg: arg ?? this.arg,
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