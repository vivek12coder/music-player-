enum TimeOfDaySegment {
  morning,
  afternoon,
  evening,
  night,
}

TimeOfDaySegment resolveTimeSegment(DateTime now) {
  final hour = now.hour;
  if (hour >= 5 && hour < 12) {
    return TimeOfDaySegment.morning;
  }
  if (hour >= 12 && hour < 17) {
    return TimeOfDaySegment.afternoon;
  }
  if (hour >= 17 && hour < 22) {
    return TimeOfDaySegment.evening;
  }
  return TimeOfDaySegment.night;
}

