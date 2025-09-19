import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/post.dart';
import '../../providers/post_provider.dart';
import 'post_detail_screen.dart';

class PostDetailWrapper extends StatefulWidget {
  final int postId;
  
  const PostDetailWrapper({
    super.key,
    required this.postId,
  });

  @override
  State<PostDetailWrapper> createState() => _PostDetailWrapperState();
}

class _PostDetailWrapperState extends State<PostDetailWrapper> {
  Post? post;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _fetchPost();
  }

  Future<void> _fetchPost() async {
    try {
      final postProvider = context.read<PostProvider>();
      await postProvider.fetchPostById(widget.postId);
      
      if (mounted) {
        setState(() {
          post = postProvider.selectedPost;
          error = postProvider.error;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = 'Gagal memuat detail postingan: $e';
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    error = null;
                  });
                  _fetchPost();
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (post == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Postingan Tidak Ditemukan'),
        ),
        body: const Center(
          child: Text('Postingan tidak ditemukan'),
        ),
      );
    }

    return PostDetailScreen(post: post!);
  }
}