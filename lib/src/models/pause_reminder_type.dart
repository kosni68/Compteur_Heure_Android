enum PauseReminderType {
  notification,
  alarm,
}

PauseReminderType pauseReminderTypeFromString(String? raw) {
  switch (raw) {
    case 'alarm':
      return PauseReminderType.alarm;
    case 'notification':
    default:
      return PauseReminderType.notification;
  }
}

String pauseReminderTypeToString(PauseReminderType type) {
  switch (type) {
    case PauseReminderType.alarm:
      return 'alarm';
    case PauseReminderType.notification:
    default:
      return 'notification';
  }
}
