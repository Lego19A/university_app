// ============================================================
// TIMETABLE MODELS - Data models for the drag & drop timetable.
// These models define the structure for subjects, sessions,
// time slots, and the overall timetable builder state.
//
// TimeSlot: Represents a specific day + time + duration.
// Session: A single lecture or lab block that can be placed.
// Subject: Groups a lecture and optional lab for one course.
// TimetableState: Entire state tree for the builder flow.
// ============================================================

import 'package:flutter/material.dart';

// -- SESSION TYPE: Distinguishes between lectures and labs --
enum SessionType { lecture, lab }

// ============================================================
// SUBJECT SESSION - Defines a valid drop target on the grid.
// Each subject stores multiple SubjectSessions that define
// exactly which day+time combinations the user is allowed to
// drop a lecture or lab block onto.
//
// dayOfWeek: 1 = Monday, 5 = Friday
// startHour: 8 = 8:00 AM, 14 = 2:00 PM (24-hour integer)
// durationHours: how many 1-hour slots this session occupies
// ============================================================
class SubjectSession {
  final String id;
  final SessionType type;
  final int dayOfWeek;
  final int startHour;
  final int durationHours;

  const SubjectSession({
    required this.id,
    required this.type,
    required this.dayOfWeek,
    required this.startHour,
    required this.durationHours,
  });

  // -- Convert to a TimeSlot for clash detection --
  TimeSlot toTimeSlot() => TimeSlot(
        dayOfWeek: dayOfWeek,
        startHour: startHour,
        durationHours: durationHours,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubjectSession &&
          id == other.id &&
          dayOfWeek == other.dayOfWeek &&
          startHour == other.startHour;

  @override
  int get hashCode => Object.hash(id, dayOfWeek, startHour);
}

// ============================================================
// TIME SLOT - Represents a placed position on the timetable.
// dayOfWeek: 1 = Monday, 5 = Friday
// startHour: 8 = 8:00 AM, 13 = 1:00 PM (24-hour integer)
// durationHours: number of 1-hour slots this session occupies
// ============================================================
class TimeSlot {
  final int dayOfWeek;
  final int startHour;
  final int durationHours;

  const TimeSlot({
    required this.dayOfWeek,
    required this.startHour,
    required this.durationHours,
  });

  // -- Serialize to a Firestore-compatible Map --
  Map<String, dynamic> toMap() => {
        'dayOfWeek': dayOfWeek,
        'startHour': startHour,
        'durationHours': durationHours,
      };

  // -- Deserialize from a Firestore Map --
  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      dayOfWeek: (map['dayOfWeek'] as num?)?.toInt() ?? 1,
      startHour: (map['startHour'] as num?)?.toInt() ?? 8,
      durationHours: (map['durationHours'] as num?)?.toInt() ?? 2,
    );
  }

  // -- Check if this slot overlaps with another --
  bool overlapsWith(TimeSlot other) {
    if (dayOfWeek != other.dayOfWeek) return false;
    final thisEnd = startHour + durationHours;
    final otherEnd = other.startHour + other.durationHours;
    return startHour < otherEnd && thisEnd > other.startHour;
  }

  // -- Human-readable time label --
  String get timeLabel {
    final endHour = startHour + durationHours;
    return '${_formatHour(startHour)} - ${_formatHour(endHour)}';
  }

  String _formatHour(int hour) {
    if (hour == 12) return '12:00 PM';
    if (hour > 12) return '${hour - 12}:00 PM';
    return '$hour:00 AM';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSlot &&
          dayOfWeek == other.dayOfWeek &&
          startHour == other.startHour &&
          durationHours == other.durationHours;

  @override
  int get hashCode => Object.hash(dayOfWeek, startHour, durationHours);
}

// ============================================================
// SESSION - A single draggable block (lecture or lab).
// timeSlot is null until the user places it on the grid.
// ============================================================
class Session {
  final String id;
  final String subjectId;
  final String subjectName;
  final String subjectCode;
  final SessionType type;
  final int durationHours;
  final TimeSlot? timeSlot;
  final Color color;
  final List<SubjectSession> availableSlots; // Valid drop targets for this session

  const Session({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.subjectCode,
    required this.type,
    required this.durationHours,
    this.timeSlot,
    required this.color,
    this.availableSlots = const [],
  });

  // -- Serialize to a Firestore-compatible Map --
  Map<String, dynamic> toMap() => {
        'id': id,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'subjectCode': subjectCode,
        'type': type == SessionType.lecture ? 'lecture' : 'lab',
        'durationHours': durationHours,
        'color': color.value,
        'timeSlot': timeSlot?.toMap(),
      };

  // -- Deserialize from a Firestore Map --
  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id']?.toString() ?? '',
      subjectId: map['subjectId']?.toString() ?? '',
      subjectName: map['subjectName']?.toString() ?? '',
      subjectCode: map['subjectCode']?.toString() ?? '',
      type: map['type'] == 'lab' ? SessionType.lab : SessionType.lecture,
      durationHours: (map['durationHours'] as num?)?.toInt() ?? 2,
      color: Color((map['color'] as num?)?.toInt() ?? 0xFF3498DB),
      timeSlot: map['timeSlot'] != null
          ? TimeSlot.fromMap(Map<String, dynamic>.from(map['timeSlot'] as Map))
          : null,
    );
  }

  // -- Create a copy with a new timeSlot (used when placing) --
  Session copyWithTimeSlot(TimeSlot? slot) {
    return Session(
      id: id,
      subjectId: subjectId,
      subjectName: subjectName,
      subjectCode: subjectCode,
      type: type,
      durationHours: durationHours,
      timeSlot: slot,
      color: color,
      availableSlots: availableSlots,
    );
  }

  // -- Display label for the session type --
  String get typeLabel => type == SessionType.lecture ? 'LEC' : 'LAB';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Session && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// ============================================================
// SUBJECT - Groups all sessions (lecture + lab) for one course.
// requiresLab: If true, user must place both lecture and lab.
// ============================================================
class Subject {
  final String id;
  final String name;
  final String code;
  final bool requiresLab;
  final Color color;
  final List<Session> sessions;
  final List<SubjectSession> availableSessions; // All valid slots for this subject

  const Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.requiresLab,
    required this.color,
    required this.sessions,
    this.availableSessions = const [],
  });
}

// ============================================================
// TIMETABLE STATE - The full state of the builder flow.
// subjects: All subjects the user selected for scheduling.
// placedSessions: All sessions that have been placed on the grid.
// isComplete: true when all subjects are fully scheduled.
//
// This uses a "free-form" model where ALL subjects and sessions
// are visible at once. The user can drag any session from any
// subject in any order.
// ============================================================
class TimetableState {
  final List<Subject> subjects;
  final int currentSubjectIndex; // Kept for backward compat
  final List<Session> placedSessions;
  final bool isComplete;

  const TimetableState({
    required this.subjects,
    this.currentSubjectIndex = 0,
    this.placedSessions = const [],
    this.isComplete = false,
  });

  // -- Every session across all subjects --
  List<Session> get allSessions =>
      subjects.expand((s) => s.sessions).toList();

  // -- Total number of sessions to place --
  int get totalSessionCount => allSessions.length;

  // -- Number of sessions already placed --
  int get placedSessionCount => placedSessions.length;

  // -- All unplaced sessions across ALL subjects --
  List<Session> get allUnplacedSessions {
    final placedIds = placedSessions.map((s) => s.id).toSet();
    return allSessions
        .where((s) => !placedIds.contains(s.id))
        .toList();
  }

  // -- Check if ALL sessions across ALL subjects are placed --
  bool get isAllComplete {
    if (subjects.isEmpty) return false;
    final placedIds = placedSessions.map((s) => s.id).toSet();
    return allSessions.every((s) => placedIds.contains(s.id));
  }

  // -- Legacy: current subject (kept for backward compat) --
  Subject? get currentSubject =>
      currentSubjectIndex < subjects.length ? subjects[currentSubjectIndex] : null;

  // -- Legacy: unplaced for current subject only --
  List<Session> get currentUnplacedSessions {
    if (currentSubject == null) return [];
    final placedIds = placedSessions.map((s) => s.id).toSet();
    return currentSubject!.sessions
        .where((s) => !placedIds.contains(s.id))
        .toList();
  }

  // -- Legacy: current subject complete --
  bool get isCurrentSubjectComplete {
    if (currentSubject == null) return false;
    final placedIds = placedSessions.map((s) => s.id).toSet();
    return currentSubject!.sessions.every((s) => placedIds.contains(s.id));
  }

  // -- Progress fraction (0.0 to 1.0) based on total sessions --
  double get progress {
    if (totalSessionCount == 0) return 0;
    return placedSessionCount / totalSessionCount;
  }

  // -- Create a modified copy --
  TimetableState copyWith({
    List<Subject>? subjects,
    int? currentSubjectIndex,
    List<Session>? placedSessions,
    bool? isComplete,
  }) {
    return TimetableState(
      subjects: subjects ?? this.subjects,
      currentSubjectIndex: currentSubjectIndex ?? this.currentSubjectIndex,
      placedSessions: placedSessions ?? this.placedSessions,
      isComplete: isComplete ?? this.isComplete,
    );
  }
}
