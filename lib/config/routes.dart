import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/quiz/quiz_screen.dart';
import '../screens/quiz/quiz_detail_screen.dart';
import '../screens/quiz/quiz_take_screen.dart';
import '../screens/quiz/quiz_result_screen.dart';
import '../screens/event/event_list_screen.dart';
import '../screens/event/event_detail_screen.dart';
import '../screens/event/create_event_screen.dart';
import '../screens/event/my_bookings_screen.dart';
import '../screens/mading/mading_screen.dart';
import '../screens/mading/create_post_screen.dart';
import '../screens/mading/post_detail_wrapper.dart';
import '../screens/gallery/gallery_screen.dart';
import '../screens/gallery/album_detail_screen.dart';
import '../screens/gallery/photo_detail_screen.dart';
import '../screens/gallery/photo_detail_wrapper.dart';
import '../screens/gallery/create_album_screen.dart';
import '../screens/gallery/upload_photo_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/class_management_screen.dart';
import '../screens/student_management_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/notifications_screen.dart';
import '../models/album.dart';
import '../models/photo.dart';

class AppRoutes {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (BuildContext context, GoRouterState state) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isLoggedIn = authProvider.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';
      final isRegistering = state.matchedLocation == '/register';

      // If not logged in and not on auth pages, redirect to login
      if (!isLoggedIn && !isLoggingIn && !isRegistering) {
        return '/login';
      }

      // If logged in and on auth pages, redirect to home
      if (isLoggedIn && (isLoggingIn || isRegistering)) {
        return '/home';
      }

      // No redirect needed
      return null;
    },
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Main App Routes
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      
      // Feature Routes
      GoRoute(
        path: '/quiz',
        name: 'quiz',
        builder: (context, state) => const QuizScreen(),
        routes: [
          // Quiz Detail Route
          GoRoute(
            path: ':quizId',
            name: 'quiz-detail',
            builder: (context, state) {
              final quizId = state.pathParameters['quizId']!;
              return QuizDetailScreen(quizId: quizId);
            },
            routes: [
              // Quiz Take Route
              GoRoute(
                path: 'take/:attemptId',
                name: 'quiz-take',
                builder: (context, state) {
                  final quizId = state.pathParameters['quizId']!;
                  final attemptId = state.pathParameters['attemptId']!;
                  return QuizTakeScreen(
                    quizId: quizId,
                    attemptId: attemptId,
                  );
                },
              ),
              // Quiz Result Route
              GoRoute(
                path: 'result/:attemptId',
                name: 'quiz-result',
                builder: (context, state) {
                  final quizId = state.pathParameters['quizId']!;
                  final attemptId = state.pathParameters['attemptId']!;
                  return QuizResultScreen(
                    quizId: quizId,
                    attemptId: attemptId,
                  );
                },
              ),
            ],
          ),
        ],
      ),
      // Event Planner Routes
        GoRoute(
          path: '/events',
          name: 'events',
          builder: (context, state) => const EventListScreen(),
          routes: [
            // Create Event Route
            GoRoute(
              path: 'create',
              name: 'create-event',
              builder: (context, state) => const CreateEventScreen(),
            ),
            // My Bookings Route
            GoRoute(
              path: 'bookings',
              name: 'my-bookings',
              builder: (context, state) => const MyBookingsScreen(),
            ),
            // Event Detail Route
            GoRoute(
              path: ':eventId',
              name: 'event-detail',
              builder: (context, state) {
                final eventId = state.pathParameters['eventId']!;
                return EventDetailScreen(eventId: eventId);
              },
            ),
          ],
        ),
      GoRoute(
        path: '/mading',
        name: 'mading',
        builder: (context, state) => const MadingScreen(),
        routes: [
          // Create Post Route
          GoRoute(
            path: 'create',
            name: 'create-post',
            builder: (context, state) => const CreatePostScreen(),
          ),
          // Post Detail Route
          GoRoute(
            path: ':postId',
            name: 'post-detail',
            builder: (context, state) {
              final postIdString = state.pathParameters['postId']!;
              final postId = int.tryParse(postIdString);
              
              if (postId == null) {
                return const Scaffold(
                  body: Center(
                    child: Text('Invalid post ID'),
                  ),
                );
              }
              
              // We need to fetch the post first or pass it from previous screen
              // For now, we'll create a wrapper that fetches the post
              return PostDetailWrapper(postId: postId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/gallery',
        name: 'gallery',
        builder: (context, state) => const GalleryScreen(),
        routes: [
          // Create Album Route
          GoRoute(
            path: 'create-album',
            name: 'create-album',
            builder: (context, state) => const CreateAlbumScreen(),
          ),
          // Album Detail Route
          GoRoute(
            path: 'album/:albumId',
            name: 'album-detail',
            builder: (context, state) {
              final albumIdString = state.pathParameters['albumId']!;
              final albumId = int.tryParse(albumIdString);
              
              if (albumId == null) {
                return const Scaffold(
                  body: Center(
                    child: Text('Invalid album ID'),
                  ),
                );
              }
              
              // Create a temporary album object with the ID
              // The screen will fetch the full album data
              final tempAlbum = Album(
                id: albumId,
                title: '',
                description: '',
                coverPhoto: '',
                createdBy: 0,
                isPublic: true,
                allowDownload: true,
                tags: [],
                photoCount: 0,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              
              return AlbumDetailScreen(album: tempAlbum);
            },
            routes: [
              // Upload Photo Route
              GoRoute(
                path: 'upload',
                name: 'upload-photo',
                builder: (context, state) {
                  final albumIdString = state.pathParameters['albumId']!;
                  final albumId = int.tryParse(albumIdString);
                  
                  if (albumId == null) {
                    return const Scaffold(
                      body: Center(
                        child: Text('Invalid album ID'),
                      ),
                    );
                  }
                  
                  // Create a temporary album object with the ID
                  // The screen will fetch the full album data
                  final tempAlbum = Album(
                    id: albumId,
                    title: '',
                    description: '',
                    coverPhoto: '',
                    createdBy: 0,
                    isPublic: true,
                    allowDownload: true,
                    tags: [],
                    photoCount: 0,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  
                  return UploadPhotoScreen(album: tempAlbum);
                },
              ),
            ],
          ),
          // Photo Detail Route
          GoRoute(
            path: 'photo/:photoId',
            name: 'photo-detail',
            builder: (context, state) {
              final photoIdString = state.pathParameters['photoId']!;
              final photoId = int.tryParse(photoIdString);
              
              if (photoId == null) {
                return const Scaffold(
                  body: Center(
                    child: Text('Invalid photo ID'),
                  ),
                );
              }
              
              // Return a wrapper that fetches the actual photo data from API
              return PhotoDetailWrapper(photoId: photoId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),

      // Class Management Routes (for teachers and admins)
      GoRoute(
        path: '/classes',
        name: 'classes',
        builder: (context, state) => const ClassManagementScreen(),
      ),
      GoRoute(
        path: '/students',
        name: 'students',
        builder: (context, state) => const StudentManagementScreen(),
      ),

      // Settings Routes
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Halaman Tidak Ditemukan'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Halaman tidak ditemukan',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Path: ${state.matchedLocation}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Kembali ke Beranda'),
            ),
          ],
        ),
      ),
    ),
  );
}