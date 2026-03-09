String normalizeQueryStatus(String? rawStatus) {
  switch ((rawStatus ?? '').toLowerCase()) {
    case 'open':
      return 'unanswered';
    case 'replied':
      return 'answered';
    case 'closed':
      return 'answered';
    case 'in_progress':
      return 'in_progress';
    case 'answered':
      return 'answered';
    case 'unanswered':
    default:
      return 'unanswered';
  }
}

String queryStatusLabel(String? rawStatus) {
  final status = normalizeQueryStatus(rawStatus);
  switch (status) {
    case 'answered':
      return 'answered';
    case 'in_progress':
      return 'in_progress';
    case 'unanswered':
    default:
      return 'unanswered';
  }
}
