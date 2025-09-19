class Quiz {
  final int id;
  final String title;
  final String? description;
  final String category; // reading, writing, math, science
  final String difficulty; // easy, medium, hard
  final int timeLimit; // in minutes
  final int createdBy;
  final int? classId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? questionCount;

  Quiz({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    required this.difficulty,
    required this.timeLimit,
    required this.createdBy,
    this.classId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.questionCount,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      difficulty: json['difficulty'],
      timeLimit: json['time_limit'] ?? 0,
      createdBy: json['created_by'],
      classId: json['class_id'],
      isActive: json['is_active'] is int 
          ? json['is_active'] == 1 
          : (json['is_active'] as bool? ?? true),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      questionCount: json['question_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'difficulty': difficulty,
      'time_limit': timeLimit,
      'created_by': createdBy,
      'class_id': classId,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'question_count': questionCount,
    };
  }

  Quiz copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    String? difficulty,
    int? timeLimit,
    int? createdBy,
    int? classId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? questionCount,
  }) {
    return Quiz(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      timeLimit: timeLimit ?? this.timeLimit,
      createdBy: createdBy ?? this.createdBy,
      classId: classId ?? this.classId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      questionCount: questionCount ?? this.questionCount,
    );
  }
}

class QuizQuestion {
  final int id;
  final int quizId;
  final String question;
  final String type; // multiple_choice, true_false, fill_blank
  final List<String>? options;
  final String correctAnswer;
  final int points;
  final String difficulty;
  final String? explanation;
  final int orderNumber;
  final int? createdBy;
  final DateTime createdAt;

  QuizQuestion({
    required this.id,
    required this.quizId,
    required this.question,
    required this.type,
    this.options,
    required this.correctAnswer,
    required this.points,
    required this.difficulty,
    this.explanation,
    required this.orderNumber,
    this.createdBy,
    required this.createdAt,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    List<String>? optionsList;
    if (json['options'] != null) {
      if (json['options'] is List) {
        optionsList = List<String>.from(json['options']);
      } else if (json['options'] is String) {
        // Handle JSON string
        try {
          final decoded = json['options'];
          if (decoded is List) {
            optionsList = List<String>.from(decoded);
          }
        } catch (e) {
          optionsList = null;
        }
      }
    }

    return QuizQuestion(
      id: json['id'],
      quizId: json['quiz_id'],
      question: json['question'],
      type: json['type'],
      options: optionsList,
      correctAnswer: json['correct_answer'],
      points: json['points'] ?? 1,
      difficulty: json['difficulty'] ?? 'medium',
      explanation: json['explanation'],
      orderNumber: json['order_number'] ?? 1,
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quiz_id': quizId,
      'question': question,
      'type': type,
      'options': options,
      'correct_answer': correctAnswer,
      'points': points,
      'difficulty': difficulty,
      'explanation': explanation,
      'order_number': orderNumber,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class QuizAttempt {
  final int id;
  final int quizId;
  final int studentId;
  final int totalScore;
  final int maxScore;
  final double percentage;
  final int timeSpent; // in seconds
  final DateTime? completedAt;
  final DateTime createdAt;

  QuizAttempt({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.totalScore,
    required this.maxScore,
    required this.percentage,
    required this.timeSpent,
    this.completedAt,
    required this.createdAt,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['id'],
      quizId: json['quiz_id'],
      studentId: json['student_id'],
      totalScore: json['total_score'] ?? 0,
      maxScore: json['max_score'],
      percentage: (json['percentage'] ?? 0.0).toDouble(),
      timeSpent: json['time_spent'] ?? 0,
      completedAt: json['completed_at'] != null 
          ? DateTime.parse(json['completed_at']) 
          : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quiz_id': quizId,
      'student_id': studentId,
      'total_score': totalScore,
      'max_score': maxScore,
      'percentage': percentage,
      'time_spent': timeSpent,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class QuizAnswer {
  final int id;
  final int attemptId;
  final int questionId;
  final String? answer;
  final bool isCorrect;
  final int points;
  final DateTime createdAt;

  QuizAnswer({
    required this.id,
    required this.attemptId,
    required this.questionId,
    this.answer,
    required this.isCorrect,
    required this.points,
    required this.createdAt,
  });

  factory QuizAnswer.fromJson(Map<String, dynamic> json) {
    return QuizAnswer(
      id: json['id'],
      attemptId: json['attempt_id'],
      questionId: json['question_id'],
      answer: json['answer'],
      isCorrect: json['is_correct'] is int 
          ? json['is_correct'] == 1 
          : (json['is_correct'] as bool? ?? false),
      points: json['points'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'attempt_id': attemptId,
      'question_id': questionId,
      'answer': answer,
      'is_correct': isCorrect,
      'points': points,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class QuizResult {
  final int totalScore;
  final int maxScore;
  final double percentage;
  final int timeSpent;
  final List<Badge> badgesEarned;

  QuizResult({
    required this.totalScore,
    required this.maxScore,
    required this.percentage,
    required this.timeSpent,
    required this.badgesEarned,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      totalScore: json['total_score'],
      maxScore: json['max_score'],
      percentage: (json['percentage'] ?? 0.0).toDouble(),
      timeSpent: json['time_spent'],
      badgesEarned: json['badges_earned'] != null
          ? (json['badges_earned'] as List)
              .map((badge) => Badge.fromJson(badge))
              .toList()
          : [],
    );
  }
}

class Badge {
  final int id;
  final String name;
  final String description;

  Badge({
    required this.id,
    required this.name,
    required this.description,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }
}

// Enum untuk kategori quiz
enum QuizCategory {
  reading,
  writing,
  math,
  science;

  String get displayName {
    switch (this) {
      case QuizCategory.reading:
        return 'Membaca';
      case QuizCategory.writing:
        return 'Menulis';
      case QuizCategory.math:
        return 'Matematika';
      case QuizCategory.science:
        return 'Sains';
    }
  }
}

// Enum untuk tingkat kesulitan
enum QuizDifficulty {
  easy,
  medium,
  hard;

  String get displayName {
    switch (this) {
      case QuizDifficulty.easy:
        return 'Mudah';
      case QuizDifficulty.medium:
        return 'Sedang';
      case QuizDifficulty.hard:
        return 'Sulit';
    }
  }
}

// Enum untuk tipe pertanyaan
enum QuestionType {
  multipleChoice,
  trueFalse,
  fillBlank;

  String get apiValue {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'multiple_choice';
      case QuestionType.trueFalse:
        return 'true_false';
      case QuestionType.fillBlank:
        return 'fill_blank';
    }
  }

  String get displayName {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'Pilihan Ganda';
      case QuestionType.trueFalse:
        return 'Benar/Salah';
      case QuestionType.fillBlank:
        return 'Isi Kosong';
    }
  }
}