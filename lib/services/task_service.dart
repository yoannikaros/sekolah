import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/task_models.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Task CRUD Operations
  Future<String?> createTask(Task task) async {
    try {
      final taskData = {
        'teacherId': task.teacherId,
        'subjectId': task.subjectId,
        'chapterId': task.chapterId,
        'title': task.title,
        'description': task.description,
        'createdAt': task.createdAt.toIso8601String(),
        'openDate': task.openDate.toIso8601String(),
        'dueDate': task.dueDate.toIso8601String(),
        'taskLink': task.taskLink,
        'isActive': task.isActive,
        'updatedAt': task.updatedAt?.toIso8601String(),
      };
      
      final docRef = await _firestore.collection('tasks').add(taskData);
      if (kDebugMode) {
        print('Task created successfully with ID: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating task: $e');
      }
      return null;
    }
  }

  Future<bool> updateTask(String id, Task task) async {
    try {
      final taskData = {
        'teacherId': task.teacherId,
        'subjectId': task.subjectId,
        'chapterId': task.chapterId,
        'title': task.title,
        'description': task.description,
        'openDate': task.openDate.toIso8601String(),
        'dueDate': task.dueDate.toIso8601String(),
        'taskLink': task.taskLink,
        'isActive': task.isActive,
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      await _firestore.collection('tasks').doc(id).update(taskData);
      if (kDebugMode) {
        print('Task updated successfully with ID: $id');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating task: $e');
      }
      return false;
    }
  }

  Future<bool> deleteTask(String id) async {
    try {
      await _firestore.collection('tasks').doc(id).update({'isActive': false});
      if (kDebugMode) {
        print('Task soft deleted successfully with ID: $id');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting task: $e');
      }
      return false;
    }
  }

  Future<List<Task>> getAllTasks() async {
    try {
      if (kDebugMode) {
        print('Fetching all tasks from Firebase...');
      }
      
      final querySnapshot = await _firestore
          .collection('tasks')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      if (kDebugMode) {
        print('Total active tasks: ${querySnapshot.docs.length}');
      }

      final tasks = <Task>[];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          final task = Task.fromJson(data);
          tasks.add(task);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing task ${doc.id}: $e');
          }
        }
      }

      return tasks;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching tasks: $e');
      }
      return [];
    }
  }

  Future<Task?> getTaskById(String id) async {
    try {
      final doc = await _firestore.collection('tasks').doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return Task.fromJson(data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching task by ID: $e');
      }
      return null;
    }
  }

  Future<List<Task>> getTasksByTeacher(String teacherId) async {
    try {
      final querySnapshot = await _firestore
          .collection('tasks')
          .where('teacherId', isEqualTo: teacherId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final tasks = <Task>[];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          final task = Task.fromJson(data);
          tasks.add(task);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing task ${doc.id}: $e');
          }
        }
      }

      return tasks;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching tasks by teacher: $e');
      }
      return [];
    }
  }

  Future<List<Task>> getTasksBySubject(String subjectId) async {
    try {
      final querySnapshot = await _firestore
          .collection('tasks')
          .where('subjectId', isEqualTo: subjectId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final tasks = <Task>[];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          final task = Task.fromJson(data);
          tasks.add(task);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing task ${doc.id}: $e');
          }
        }
      }

      return tasks;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching tasks by subject: $e');
      }
      return [];
    }
  }

  Future<List<Task>> getTasksByChapter(String chapterId) async {
    try {
      final querySnapshot = await _firestore
          .collection('tasks')
          .where('chapterId', isEqualTo: chapterId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final tasks = <Task>[];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          final task = Task.fromJson(data);
          tasks.add(task);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing task ${doc.id}: $e');
          }
        }
      }

      return tasks;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching tasks by chapter: $e');
      }
      return [];
    }
  }

  // TaskClass CRUD Operations
  Future<String?> createTaskClass(TaskClass taskClass) async {
    try {
      final taskClassData = {
        'taskId': taskClass.taskId,
        'classId': taskClass.classId,
        'createdAt': taskClass.createdAt.toIso8601String(),
        'isActive': taskClass.isActive,
      };
      
      final docRef = await _firestore.collection('task_classes').add(taskClassData);
      if (kDebugMode) {
        print('TaskClass created successfully with ID: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating task class: $e');
      }
      return null;
    }
  }

  Future<bool> deleteTaskClass(String id) async {
    try {
      await _firestore.collection('task_classes').doc(id).update({'isActive': false});
      if (kDebugMode) {
        print('TaskClass soft deleted successfully with ID: $id');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting task class: $e');
      }
      return false;
    }
  }

  Future<List<TaskClass>> getTaskClassesByTask(String taskId) async {
    try {
      final querySnapshot = await _firestore
          .collection('task_classes')
          .where('taskId', isEqualTo: taskId)
          .where('isActive', isEqualTo: true)
          .get();

      final taskClasses = <TaskClass>[];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          final taskClass = TaskClass.fromJson(data);
          taskClasses.add(taskClass);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing task class ${doc.id}: $e');
          }
        }
      }

      return taskClasses;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching task classes by task: $e');
      }
      return [];
    }
  }

  Future<List<TaskClass>> getTaskClassesByClass(String classId) async {
    try {
      final querySnapshot = await _firestore
          .collection('task_classes')
          .where('classId', isEqualTo: classId)
          .where('isActive', isEqualTo: true)
          .get();

      final taskClasses = <TaskClass>[];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          final taskClass = TaskClass.fromJson(data);
          taskClasses.add(taskClass);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing task class ${doc.id}: $e');
          }
        }
      }

      return taskClasses;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching task classes by class: $e');
      }
      return [];
    }
  }

  Future<bool> assignTaskToClasses(String taskId, List<String> classIds) async {
    try {
      final batch = _firestore.batch();
      
      // First, remove existing assignments for this task
      final existingAssignments = await getTaskClassesByTask(taskId);
      for (var assignment in existingAssignments) {
        batch.update(
          _firestore.collection('task_classes').doc(assignment.id),
          {'isActive': false}
        );
      }
      
      // Then add new assignments
      for (var classId in classIds) {
        final taskClassData = {
          'taskId': taskId,
          'classId': classId,
          'createdAt': DateTime.now().toIso8601String(),
          'isActive': true,
        };
        
        final docRef = _firestore.collection('task_classes').doc();
        batch.set(docRef, taskClassData);
      }
      
      await batch.commit();
      if (kDebugMode) {
        print('Task assigned to classes successfully');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error assigning task to classes: $e');
      }
      return false;
    }
  }

  // TaskSubmission CRUD Operations
  Future<String?> createTaskSubmission(TaskSubmission submission) async {
    try {
      final submissionData = {
        'taskId': submission.taskId,
        'studentId': submission.studentId,
        'submissionLink': submission.submissionLink,
        'submissionDate': submission.submissionDate.toIso8601String(),
        'notes': submission.notes,
        'isLate': submission.isLate,
        'gradedAt': submission.gradedAt?.toIso8601String(),
        'score': submission.score,
        'feedback': submission.feedback,
        'isActive': submission.isActive,
      };
      
      final docRef = await _firestore.collection('task_submissions').add(submissionData);
      if (kDebugMode) {
        print('TaskSubmission created successfully with ID: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating task submission: $e');
      }
      return null;
    }
  }

  Future<bool> updateTaskSubmission(String id, TaskSubmission submission) async {
    try {
      final submissionData = {
        'submissionLink': submission.submissionLink,
        'notes': submission.notes,
        'gradedAt': submission.gradedAt?.toIso8601String(),
        'score': submission.score,
        'feedback': submission.feedback,
        'isActive': submission.isActive,
      };
      
      await _firestore.collection('task_submissions').doc(id).update(submissionData);
      if (kDebugMode) {
        print('TaskSubmission updated successfully with ID: $id');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating task submission: $e');
      }
      return false;
    }
  }

  Future<bool> gradeSubmission(String id, double score, String? feedback) async {
    try {
      final submissionData = {
        'score': score,
        'feedback': feedback,
        'gradedAt': DateTime.now().toIso8601String(),
      };
      
      await _firestore.collection('task_submissions').doc(id).update(submissionData);
      if (kDebugMode) {
        print('TaskSubmission graded successfully with ID: $id');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error grading task submission: $e');
      }
      return false;
    }
  }

  Future<List<TaskSubmission>> getSubmissionsByTask(String taskId) async {
    try {
      final querySnapshot = await _firestore
          .collection('task_submissions')
          .where('taskId', isEqualTo: taskId)
          .where('isActive', isEqualTo: true)
          .orderBy('submissionDate', descending: true)
          .get();

      final submissions = <TaskSubmission>[];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          final submission = TaskSubmission.fromJson(data);
          submissions.add(submission);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing task submission ${doc.id}: $e');
          }
        }
      }

      return submissions;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching submissions by task: $e');
      }
      return [];
    }
  }

  Future<List<TaskSubmission>> getSubmissionsByStudent(String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('task_submissions')
          .where('studentId', isEqualTo: studentId)
          .where('isActive', isEqualTo: true)
          .orderBy('submissionDate', descending: true)
          .get();

      final submissions = <TaskSubmission>[];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          final submission = TaskSubmission.fromJson(data);
          submissions.add(submission);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing task submission ${doc.id}: $e');
          }
        }
      }

      return submissions;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching submissions by student: $e');
      }
      return [];
    }
  }

  Future<TaskSubmission?> getSubmissionByTaskAndStudent(String taskId, String studentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('task_submissions')
          .where('taskId', isEqualTo: taskId)
          .where('studentId', isEqualTo: studentId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        data['id'] = doc.id;
        return TaskSubmission.fromJson(data);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching submission by task and student: $e');
      }
      return null;
    }
  }

  // Helper methods for getting task details with related information
  Future<List<TaskWithDetails>> getTasksWithDetails() async {
    try {
      if (kDebugMode) {
        print('Starting getTasksWithDetails...');
      }
      
      // Get all tasks first
      final tasks = await getAllTasks();
      
      if (kDebugMode) {
        print('Retrieved ${tasks.length} tasks from getAllTasks()');
        if (tasks.isEmpty) {
          print('No tasks found - checking Firestore directly...');
          
          // Direct Firestore query for debugging
          final directQuery = await _firestore.collection('tasks').get();
          print('Direct Firestore query found ${directQuery.docs.length} documents in tasks collection');
          
          for (var doc in directQuery.docs) {
            final data = doc.data();
            print('Task document ${doc.id}: isActive=${data['isActive']}, createdAt=${data['createdAt']}');
          }
        }
      }
      
      final tasksWithDetails = <TaskWithDetails>[];
      
      for (var task in tasks) {
        try {
          if (kDebugMode) {
            print('Processing task ${task.id}: ${task.title}');
          }
          
          // Get teacher name
          String teacherName = 'Unknown Teacher';
          try {
            final teacherDoc = await _firestore.collection('teachers').doc(task.teacherId).get();
            if (teacherDoc.exists) {
              teacherName = teacherDoc.data()?['name'] ?? 'Unknown Teacher';
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error fetching teacher ${task.teacherId}: $e');
            }
          }
          
          // Get subject name
          String subjectName = 'Unknown Subject';
          try {
            final subjectDoc = await _firestore.collection('subjects').doc(task.subjectId).get();
            if (subjectDoc.exists) {
              subjectName = subjectDoc.data()?['name'] ?? 'Unknown Subject';
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error fetching subject ${task.subjectId}: $e');
            }
          }
          
          // Get class names and total students
          List<String> classNames = [];
          int totalStudents = 0;
          try {
            final taskClasses = await getTaskClassesByTask(task.id);
            for (var taskClass in taskClasses) {
              final classDoc = await _firestore.collection('class_codes').doc(taskClass.classId).get();
              if (classDoc.exists) {
                final classData = classDoc.data()!;
                final className = classData['code'] ?? classData['name'] ?? 'Unknown Class';
                classNames.add(className);
                
                // Count students in this class
                final studentsQuery = await _firestore
                    .collection('students')
                    .where('classId', isEqualTo: taskClass.classId)
                    .where('isActive', isEqualTo: true)
                    .get();
                totalStudents += studentsQuery.docs.length;
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error fetching classes for task ${task.id}: $e');
            }
          }
          
          // Get submission count
           int submissionCount = 0;
           try {
             final submissions = await getSubmissionsByTask(task.id);
             submissionCount = submissions.length;
           } catch (e) {
             if (kDebugMode) {
               print('Error fetching submissions for task ${task.id}: $e');
             }
           }
          
          final taskWithDetails = TaskWithDetails(
            task: task,
            teacherName: teacherName,
            subjectName: subjectName,
            classNames: classNames,
            submissionCount: submissionCount,
            totalStudents: totalStudents,
          );
          
          tasksWithDetails.add(taskWithDetails);
          
          if (kDebugMode) {
            print('Added task with details: ${task.title} by $teacherName');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error processing task ${task.id}: $e');
          }
        }
      }
      
      if (kDebugMode) {
        print('Returning ${tasksWithDetails.length} tasks with details');
      }
      
      return tasksWithDetails;
    } catch (e) {
      if (kDebugMode) {
        print('Error in getTasksWithDetails: $e');
      }
      return [];
    }
  }

  /// Get task submissions with details (including student names)
  Future<List<TaskSubmissionWithDetails>> getSubmissionsWithDetailsByTask(String taskId) async {
    try {
      final submissions = await getSubmissionsByTask(taskId);
      final submissionsWithDetails = <TaskSubmissionWithDetails>[];

      // Get task title
      String taskTitle = 'Unknown Task';
      try {
        final taskDoc = await _firestore.collection('tasks').doc(taskId).get();
        if (taskDoc.exists) {
          taskTitle = taskDoc.data()?['title'] ?? 'Unknown Task';
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error getting task title for task $taskId: $e');
        }
      }

      for (final submission in submissions) {
        // Get student name
        String studentName = 'Unknown Student';
        try {
          final studentDoc = await _firestore.collection('students').doc(submission.studentId).get();
          if (studentDoc.exists) {
            final studentData = studentDoc.data()!;
            studentName = studentData['name'] ?? 'Unknown Student';
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error getting student name for submission ${submission.id}: $e');
          }
        }

        submissionsWithDetails.add(TaskSubmissionWithDetails(
          submission: submission,
          studentName: studentName,
          taskTitle: taskTitle,
        ));
      }

      return submissionsWithDetails;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting submissions with details: $e');
      }
      return [];
    }
  }

  // Get tasks with details filtered by chapter
  Future<List<TaskWithDetails>> getTasksWithDetailsByChapter(String chapterId) async {
    try {
      if (kDebugMode) {
        print('Starting getTasksWithDetailsByChapter for chapter: $chapterId');
      }
      
      // Get tasks filtered by chapter
      final tasks = await getTasksByChapter(chapterId);
      
      if (kDebugMode) {
        print('Retrieved ${tasks.length} tasks for chapter $chapterId');
      }

      final tasksWithDetails = <TaskWithDetails>[];
      
      for (var task in tasks) {
        try {
          if (kDebugMode) {
            print('Processing task ${task.id}: ${task.title}');
          }
          
          // Get teacher name
          String teacherName = 'Unknown Teacher';
          try {
            final teacherDoc = await _firestore.collection('teachers').doc(task.teacherId).get();
            if (teacherDoc.exists) {
              teacherName = teacherDoc.data()?['name'] ?? 'Unknown Teacher';
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error fetching teacher ${task.teacherId}: $e');
            }
          }
          
          // Get subject name
          String subjectName = 'Unknown Subject';
          try {
            final subjectDoc = await _firestore.collection('subjects').doc(task.subjectId).get();
            if (subjectDoc.exists) {
              subjectName = subjectDoc.data()?['name'] ?? 'Unknown Subject';
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error fetching subject ${task.subjectId}: $e');
            }
          }
          
          // Get class names
          List<String> classNames = [];
          try {
            final taskClasses = await getTaskClassesByTask(task.id);
            for (var taskClass in taskClasses) {
              final classDoc = await _firestore.collection('class_codes').doc(taskClass.classId).get();
              if (classDoc.exists) {
                final className = classDoc.data()?['name'] ?? 'Unknown Class';
                classNames.add(className);
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error fetching classes for task ${task.id}: $e');
            }
          }
          
          // Get submission count
           int submissionCount = 0;
           try {
             final submissions = await getSubmissionsByTask(task.id);
             submissionCount = submissions.length;
           } catch (e) {
             if (kDebugMode) {
               print('Error fetching submissions for task ${task.id}: $e');
             }
           }
          
          // Get total students (simplified - just return submission count for now)
          int totalStudents = submissionCount;
          
          final taskWithDetails = TaskWithDetails(
            task: task,
            teacherName: teacherName,
            subjectName: subjectName,
            classNames: classNames,
            submissionCount: submissionCount,
            totalStudents: totalStudents,
          );
          
          tasksWithDetails.add(taskWithDetails);
          
          if (kDebugMode) {
            print('Added task with details: ${task.title} by $teacherName');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error processing task ${task.id}: $e');
          }
        }
      }

      if (kDebugMode) {
        print('Completed getTasksWithDetailsByChapter: ${tasksWithDetails.length} tasks with details');
      }

      return tasksWithDetails;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting tasks with details by chapter: $e');
      }
      return [];
    }
  }

  // Additional methods for student task submission functionality
  Future<List<TaskWithDetails>> getTasksBySubjectAndClassCode(String subjectId, String classCodeId) async {
    try {
      if (kDebugMode) {
        print('TaskService: Getting tasks for subject $subjectId and class code $classCodeId');
      }

      // First get tasks by subject
      final tasks = await getTasksBySubject(subjectId);
      
      if (kDebugMode) {
        print('TaskService: Found ${tasks.length} tasks for subject');
      }

      final tasksWithDetails = <TaskWithDetails>[];

      for (final task in tasks) {
        try {
          // Check if this task is assigned to the specified class code
          final taskClasses = await getTaskClassesByTask(task.id);
          final isAssignedToClass = taskClasses.any((tc) => tc.classId == classCodeId);
          
          if (!isAssignedToClass) {
            if (kDebugMode) {
              print('TaskService: Task ${task.title} not assigned to class $classCodeId, skipping');
            }
            continue;
          }

          if (kDebugMode) {
            print('TaskService: Processing task: ${task.title}');
          }

          // Get teacher name
          String teacherName = 'Unknown Teacher';
          try {
            final teacherDoc = await _firestore.collection('teachers').doc(task.teacherId).get();
            if (teacherDoc.exists) {
              teacherName = teacherDoc.data()?['name'] ?? 'Unknown Teacher';
            }
          } catch (e) {
            if (kDebugMode) {
              print('TaskService: Error fetching teacher ${task.teacherId}: $e');
            }
          }

          // Get subject name
          String subjectName = 'Unknown Subject';
          try {
            final subjectDoc = await _firestore.collection('subjects').doc(task.subjectId).get();
            if (subjectDoc.exists) {
              subjectName = subjectDoc.data()?['name'] ?? 'Unknown Subject';
            }
          } catch (e) {
            if (kDebugMode) {
              print('TaskService: Error fetching subject ${task.subjectId}: $e');
            }
          }

          // Get class names
          List<String> classNames = [];
          try {
            final classDoc = await _firestore.collection('class_codes').doc(classCodeId).get();
            if (classDoc.exists) {
              final className = classDoc.data()?['name'] ?? 'Unknown Class';
              classNames.add(className);
            }
          } catch (e) {
            if (kDebugMode) {
              print('TaskService: Error fetching class $classCodeId: $e');
            }
          }

          // Get submission count for this class
          int submissionCount = 0;
          int totalStudents = 0;
          try {
            // Get students in this class
            final studentsQuery = await _firestore
                .collection('students')
                .where('classCodeId', isEqualTo: classCodeId)
                .where('isActive', isEqualTo: true)
                .get();
            totalStudents = studentsQuery.docs.length;

            // Get submissions for this task
            final submissions = await getSubmissionsByTask(task.id);
            
            // Count submissions from students in this class
            final studentIds = studentsQuery.docs.map((doc) => doc.id).toSet();
            submissionCount = submissions.where((s) => studentIds.contains(s.studentId)).length;
            
          } catch (e) {
            if (kDebugMode) {
              print('TaskService: Error calculating submission stats for task ${task.id}: $e');
            }
          }

          final taskWithDetails = TaskWithDetails(
            task: task,
            teacherName: teacherName,
            subjectName: subjectName,
            classNames: classNames,
            submissionCount: submissionCount,
            totalStudents: totalStudents,
          );

          tasksWithDetails.add(taskWithDetails);

          if (kDebugMode) {
            print('TaskService: Added task with details: ${task.title} by $teacherName');
          }
        } catch (e) {
          if (kDebugMode) {
            print('TaskService: Error processing task ${task.id}: $e');
          }
        }
      }

      if (kDebugMode) {
        print('TaskService: Returning ${tasksWithDetails.length} tasks with details for class');
      }

      return tasksWithDetails;
    } catch (e) {
      if (kDebugMode) {
        print('TaskService: Error getting tasks by subject and class code: $e');
      }
      return [];
    }
  }

  Future<String?> createSubmission(TaskSubmission submission) async {
    try {
      if (kDebugMode) {
        print('TaskService: Creating submission for task ${submission.taskId} by student ${submission.studentId}');
      }

      final submissionData = {
        'taskId': submission.taskId,
        'studentId': submission.studentId,
        'submissionLink': submission.submissionLink,
        'submissionDate': submission.submissionDate.toIso8601String(),
        'notes': submission.notes,
        'score': submission.score,
        'feedback': submission.feedback,
        'gradedAt': submission.gradedAt?.toIso8601String(),
        'isLate': submission.isLate,
        'isActive': submission.isActive,
      };

      final docRef = await _firestore.collection('task_submissions').add(submissionData);
      
      if (kDebugMode) {
        print('TaskService: Submission created successfully with ID: ${docRef.id}');
      }
      
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('TaskService: Error creating submission: $e');
      }
      return null;
    }
  }

  Future<bool> updateSubmission(TaskSubmission submission) async {
    try {
      if (kDebugMode) {
        print('TaskService: Updating submission ${submission.id}');
      }

      final submissionData = {
        'submissionLink': submission.submissionLink,
        'submissionDate': submission.submissionDate.toIso8601String(),
        'notes': submission.notes,
        'score': submission.score,
        'feedback': submission.feedback,
        'gradedAt': submission.gradedAt?.toIso8601String(),
        'isLate': submission.isLate,
        'isActive': submission.isActive,
      };

      await _firestore.collection('task_submissions').doc(submission.id).update(submissionData);
      
      if (kDebugMode) {
        print('TaskService: Submission updated successfully');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('TaskService: Error updating submission: $e');
      }
      return false;
    }
  }
}