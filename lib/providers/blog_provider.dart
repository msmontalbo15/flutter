import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/blog.dart';
import '../services/blog_service.dart';

final blogServiceProvider = Provider((ref) {
  return BlogService();
});

final blogsProvider = FutureProvider<List<Blog>>((ref) async {
  final service = ref.read(blogServiceProvider);
  return service.fetchBlogs(0); // 👈 pass page 0
});
