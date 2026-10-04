import 'package:flutter/material.dart';

class Subject {
  final String id;
  final String name;
  final String code;
  final String category; // 'Sciences', 'Arts', 'Commercial', 'General'
  final IconData icon;
  final Color color;
  final String description;
  final int topicCount;
  final int questionCount;

  const Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.category,
    required this.icon,
    required this.color,
    required this.description,
    required this.topicCount,
    required this.questionCount,
  });
}

class Topic {
  final String id;
  final String subjectId;
  final String title;
  final String description;
  final int lessonCount;
  final int questionCount;
  final bool isCompleted;

  const Topic({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.description,
    required this.lessonCount,
    required this.questionCount,
    this.isCompleted = false,
  });
}

class Lesson {
  final String id;
  final String topicId;
  final String subjectId;
  final String title;
  final String summary;
  final String content;
  final int readTimeMinutes;

  const Lesson({
    required this.id,
    required this.topicId,
    required this.subjectId,
    required this.title,
    required this.summary,
    required this.content,
    required this.readTimeMinutes,
  });
}

class Question {
  final String id;
  final String subjectId;
  final String? topicId;
  final String examType; // 'WAEC', 'JAMB', 'NECO', 'General'
  final int year;
  final String difficulty; // 'Easy', 'Medium', 'Hard'
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;

  const Question({
    required this.id,
    required this.subjectId,
    this.topicId,
    required this.examType,
    required this.year,
    required this.difficulty,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
  });
}

class PracticeAttempt {
  final String id;
  final String subjectId;
  final String subjectName;
  final int totalQuestions;
  final int correctCount;
  final double scorePercentage;
  final DateTime timestamp;

  const PracticeAttempt({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.totalQuestions,
    required this.correctCount,
    required this.scorePercentage,
    required this.timestamp,
  });
}

class DailyChallenge {
  final String id;
  final String subjectId;
  final String subjectName;
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
  final DateTime date;

  const DailyChallenge({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    required this.date,
  });
}

class ExamProduct {
  final String id;
  final String examType; // 'WAEC', 'NECO', 'JAMB', 'NABTEB'
  final String title;
  final String description;
  final double price;
  final String instructions;
  final String resultPortalUrl;
  final Color brandColor;

  const ExamProduct({
    required this.id,
    required this.examType,
    required this.title,
    required this.description,
    required this.price,
    required this.instructions,
    required this.resultPortalUrl,
    required this.brandColor,
  });
}

class ExamPinItem {
  final String id;
  final String examType;
  final String title;
  final String pinCode;
  final String serialNumber;
  final double amount;
  final DateTime purchaseDate;
  final String reference;
  final String status; // 'Delivered', 'Refunded'

  const ExamPinItem({
    required this.id,
    required this.examType,
    required this.title,
    required this.pinCode,
    required this.serialNumber,
    required this.amount,
    required this.purchaseDate,
    required this.reference,
    this.status = 'Delivered',
  });
}

class StudentProfileData {
  final String fullName;
  final String classLevel; // 'SS2', 'SS3', 'JAMB Candidate', 'JSS3'
  final String department; // 'Science', 'Arts', 'Commercial'
  final String school;
  final String state;
  final List<String> targetExams;
  final List<String> enrolledSubjects;
  final bool isStudentMode;

  const StudentProfileData({
    required this.fullName,
    required this.classLevel,
    required this.department,
    required this.school,
    required this.state,
    required this.targetExams,
    required this.enrolledSubjects,
    this.isStudentMode = true,
  });

  StudentProfileData copyWith({
    String? fullName,
    String? classLevel,
    String? department,
    String? school,
    String? state,
    List<String>? targetExams,
    List<String>? enrolledSubjects,
    bool? isStudentMode,
  }) {
    return StudentProfileData(
      fullName: fullName ?? this.fullName,
      classLevel: classLevel ?? this.classLevel,
      department: department ?? this.department,
      school: school ?? this.school,
      state: state ?? this.state,
      targetExams: targetExams ?? this.targetExams,
      enrolledSubjects: enrolledSubjects ?? this.enrolledSubjects,
      isStudentMode: isStudentMode ?? this.isStudentMode,
    );
  }
}
