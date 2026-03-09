import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

String formatQueryTimestamp(dynamic value, {String fallback = '-'}) {
  if (value == null) return fallback;

  DateTime? dateTime;
  if (value is Timestamp) {
    dateTime = value.toDate();
  } else if (value is DateTime) {
    dateTime = value;
  } else if (value is String) {
    dateTime = DateTime.tryParse(value);
  }

  if (dateTime == null) return fallback;
  return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime.toLocal());
}

String formatSubmittedAt(Map<String, dynamic> data, {String fallback = '-'}) {
  return formatQueryTimestamp(data['submittedAt'] ?? data['createdAt'], fallback: fallback);
}

String formatAnsweredAt(Map<String, dynamic> data, {String fallback = '-'}) {
  return formatQueryTimestamp(data['answeredAt'] ?? data['resolvedAt'], fallback: fallback);
}
