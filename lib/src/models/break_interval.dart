import 'package:flutter/material.dart';

class BreakInterval {
  BreakInterval({required this.start, required this.end});

  TimeOfDay start;
  TimeOfDay end;

  BreakInterval copy() => BreakInterval(start: start, end: end);
}
