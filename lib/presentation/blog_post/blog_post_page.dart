//lib/presentation/blog_post/blog_post_header.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/network/api_constants.dart';
import '../../core/services/blog_post_service.dart';
import '../../core/utils/app_error_helper.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../data/models/blog_post_model.dart';
import '../auth/loginsystem_select_page.dart';
import '../widgets/image_viewer.dart';

class BlogPostPage extends StatefulWidget {
  const BlogPostPage({super.key});

  @override
  State<BlogPostPage> createState() => _BlogPostPageState();
}

class _BlogPostPageState extends State<BlogPostPage> {
  final BlogPostService _blogPostService = BlogPostService();

  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  List<BlogPostModel> _posts = const [];
  final Map<int, bool> _likedPosts = {};
  final Map<int, int> _likeCounts = {};
  final Map<int, bool> _likeInFlight = {};
  final Map<int, int> _commentCounts = {};
  final Map<int, List<BlogCommentModel>> _localComments = {};
  String _defaultAuthorName = '';
  String _defaultAuthorEmail = '';
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([_loadPosts(), _loadDefaultCommentIdentity()]);
  }

  Future<void> _loadDefaultCommentIdentity() async {
    final userName = await SharedPrefsHelper.getUserName();
    final userEmail = await SharedPrefsHelper.getUserEmail();

    if (!mounted) return;

    setState(() {
      _defaultAuthorName = userName ?? '';
      _defaultAuthorEmail = userEmail ?? '';
    });
  }

  Future<void> _loadPosts({bool isRefresh = false}) async {
    if (isRefresh) {
      setState(() {
        _isRefreshing = true;
      });
    } else {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await _blogPostService.fetchBlogPosts();

      if (!mounted) return;

      setState(() {
        _posts = response.posts;
        _syncPostInteractionState(response.posts);
        _errorMessage = null;
      });

      await _markLatestAsSeen();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AppErrorHelper.toUserMessage(
          e,
          fallback: 'Blog posts could not be loaded right now.',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isRefreshing = false;
        });
      }
    }
  }

  // void _syncPostInteractionState(List<BlogPostModel> posts) {
  //   for (final post in posts) {
  //     _likedPosts.putIfAbsent(post.id, () => false);
  //     _likeCounts.putIfAbsent(post.id, () => 0);
  //     _commentCounts.putIfAbsent(post.id, () => post.commentsCount);
  //     _localComments.putIfAbsent(post.id, () => <BlogCommentModel>[]);
  //   }
  // }

void _syncPostInteractionState(List<BlogPostModel> posts) {
  for (final post in posts) {
    _likedPosts[post.id] = post.isLiked;
    _likeCounts[post.id] = post.likesCount;
    _commentCounts[post.id] = post.commentsCount;
    _localComments.putIfAbsent(post.id, () => <BlogCommentModel>[]);
  }
}


  Future<void> _markLatestAsSeen() async {
    if (_posts.isEmpty) return;
    await SharedPrefsHelper.saveSeenBlogPostId(_posts.first.id);
  }

  Future<void> _toggleLike(BlogPostModel post) async {
    final isLoggedIn = await SharedPrefsHelper.isLoggedIn();
    if (!isLoggedIn) {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginSystemSelectPage()),
      );
      return;
    }

    if (_likeInFlight[post.id] == true) {
      return;
    }

    final isLiked = _likedPosts[post.id] ?? false;
    final currentCount = _likeCounts[post.id] ?? 0;

    setState(() {
      _likeInFlight[post.id] = true;
      _likedPosts[post.id] = !isLiked;
      _likeCounts[post.id] = currentCount + (isLiked ? -1 : 1);
    });

    try {
      if (isLiked) {
        await _blogPostService.unlikePost(post.slug);
      } else {
        await _blogPostService.likePost(post.slug);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _likedPosts[post.id] = isLiked;
        _likeCounts[post.id] = currentCount;
      });
      AppErrorHelper.showSnackBar(
        context,
        e,
        fallback: 'Could not update like right now.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _likeInFlight[post.id] = false;
        });
      }
    }
  }

  Future<void> _sharePost(BlogPostModel post) async {
    final shareText =
        '${post.title}\n${ApiConstants.baseUrlWithoutApi}blog/${post.slug}';
    await Share.share(shareText, subject: post.title);
  }

  Future<BlogCommentModel> _submitComment(
    BlogPostModel post, {
    required String authorName,
    required String authorEmail,
    required String content,
  }) async {
    final comment = await _blogPostService.postComment(
      slug: post.slug,
      authorName: authorName,
      authorEmail: authorEmail,
      content: content,
    );

    if (!mounted) return comment;

    setState(() {
      _localComments[post.id] = [
        comment,
        ...(_localComments[post.id] ?? const []),
      ];
      _commentCounts[post.id] =
          (_commentCounts[post.id] ?? post.commentsCount) + 1;
      _defaultAuthorName = authorName;
      _defaultAuthorEmail = authorEmail;
    });

    return comment;
  }

  Future<void> _openCommentsSheet(BlogPostModel post) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CommentsSheet(
          post: post,
          initialName: _defaultAuthorName,
          initialEmail: _defaultAuthorEmail,
          comments: List<BlogCommentModel>.from(
            _localComments[post.id] ?? const [],
          ),
          totalComments: _commentCounts[post.id] ?? post.commentsCount,
          onSubmit: (authorName, authorEmail, content) {
            return _submitComment(
              post,
              authorName: authorName,
              authorEmail: authorEmail,
              content: content,
            );
          },
        );
      },
    );
  }

  Future<void> _openPostDetails(BlogPostModel post) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BlogPostDetailsPage(slug: post.slug)),
    );
  }

  List<String> get _categoryOptions {
    final categories = _posts.map((post) => post.category.name).toSet().toList()
      ..sort();
    return ['All', ...categories];
  }

  List<BlogPostModel> get _filteredPosts {
    if (_selectedCategory == 'All') {
      return _posts;
    }
    return _posts
        .where((post) => post.category.name == _selectedCategory)
        .toList();
  }

  int get _newPostsCount {
    final now = DateTime.now();
    return _posts.where((post) {
      try {
        final published = DateTime.parse(post.publishedAt);
        return now.difference(published).inDays <= 7;
      } catch (_) {
        return false;
      }
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(true);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F2F5),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildTopBar(),
              _buildFilterBar(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(true),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF111827),
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Store Feed',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_newPostsCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE4D8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$_newPostsCount New',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFFF6B35),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${_filteredPosts.length} posts, comments and shares',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isRefreshing ? null : () => _loadPosts(isRefresh: true),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3ED),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: _isRefreshing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFF6B35),
                          ),
                        )
                      : const Icon(
                          Icons.refresh_rounded,
                          color: Color(0xFFFF6B35),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final categories = _categoryOptions;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: SizedBox(
        height: 38,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final category = categories[index];
            final isSelected = category == _selectedCategory;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
              },
              borderRadius: BorderRadius.circular(999),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFFF6B35)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF4B5563),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.article_outlined,
                size: 56,
                color: Color(0xFFFF6B35),
              ),
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF5F6470),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadPosts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_posts.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadPosts(isRefresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 140),
            Icon(
              Icons.library_books_outlined,
              size: 56,
              color: Color(0xFFFF6B35),
            ),
            SizedBox(height: 14),
            Center(
              child: Text(
                'No blog posts available right now.',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2430),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadPosts(isRefresh: true),
      color: const Color(0xFFFF6B35),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
        itemCount: _filteredPosts.length,
        itemBuilder: (context, index) {
          final post = _filteredPosts[index];
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _SocialPostCard(
              post: post,
              isLiked: _likedPosts[post.id] ?? false,
              likeCount: _likeCounts[post.id] ?? 0,
              commentCount: _commentCounts[post.id] ?? post.commentsCount,
              latestComment: (_localComments[post.id] ?? const []).isNotEmpty
                  ? (_localComments[post.id] ?? const []).first
                  : null,
              isLikeLoading: _likeInFlight[post.id] ?? false,
              onLikeTap: () => _toggleLike(post),
              onCommentTap: () => _openCommentsSheet(post),
              onShareTap: () => _sharePost(post),
              onCardTap: () => _openPostDetails(post),
            ),
          );
        },
      ),
    );
  }
}

class _SocialPostCard extends StatelessWidget {
  final BlogPostModel post;
  final bool isLiked;
  final int likeCount;
  final int commentCount;
  final BlogCommentModel? latestComment;
  final bool isLikeLoading;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;
  final VoidCallback onCardTap;

  const _SocialPostCard({
    required this.post,
    required this.isLiked,
    required this.likeCount,
    required this.commentCount,
    required this.latestComment,
    required this.isLikeLoading,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.onShareTap,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onCardTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFFFE4D8),
                    child: Text(
                      _initials(post.author),
                      style: const TextStyle(
                        color: Color(0xFFFF6B35),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.author,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _TinyMeta(text: post.timeAgo),
                            _TinyMeta(text: post.category.name),
                            // _TinyMeta(text: post.seller.name),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Options',
                    onSelected: (value) {
                      if (value == 'share') {
                        onShareTap();
                      }
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem<String>(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share_outlined, size: 18),
                            SizedBox(width: 10),
                            Text('Share'),
                          ],
                        ),
                      ),
                    ],
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                      height: 1.28,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ExpandableText(
                    text: post.summary.isEmpty
                        ? 'No summary available.'
                        : post.summary,
                    trimLines: 2,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
                      height: 1.65,
                    ),
                  ),
                ],
              ),
            ),
            if (post.coverImage.isNotEmpty)
              _BlogCoverImage(
                imageUrl: post.coverImage,
                height: 240,
                borderRadius: 0,
                bottomRadius: 0,
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                children: [
                  _StatPill(
                    icon: isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                    iconColor: isLiked
                        ? const Color(0xFF1877F2)
                        : const Color(0xFF6B7280),
                    text: '$likeCount Likes',
                  ),
                  const SizedBox(width: 8),
                  _StatPill(
                    icon: Icons.mode_comment_outlined,
                    iconColor: const Color(0xFF6B7280),
                    text: '$commentCount Comments',
                  ),
                ],
              ),
            ),
            if (latestComment != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F7FB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        latestComment!.authorName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        latestComment!.content,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF374151),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF0F2F5)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: isLikeLoading
                          ? Icons.hourglass_top_rounded
                          : isLiked
                          ? Icons.thumb_up
                          : Icons.thumb_up_outlined,
                      label: 'Like',
                      color: isLiked
                          ? const Color(0xFF1877F2)
                          : const Color(0xFF6B7280),
                      onTap: onLikeTap,
                    ),
                  ),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.mode_comment_outlined,
                      label: 'Comment',
                      color: const Color(0xFF6B7280),
                      onTap: onCommentTap,
                    ),
                  ),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.share_outlined,
                      label: 'Share',
                      color: const Color(0xFF6B7280),
                      onTap: onShareTap,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final BlogPostModel post;
  final String initialName;
  final String initialEmail;
  final List<BlogCommentModel> comments;
  final int totalComments;
  final Future<BlogCommentModel> Function(
    String authorName,
    String authorEmail,
    String content,
  )
  onSubmit;

  const _CommentsSheet({
    required this.post,
    required this.initialName,
    required this.initialEmail,
    required this.comments,
    required this.totalComments,
    required this.onSubmit,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class BlogPostDetailsPage extends StatefulWidget {
  final String slug;

  const BlogPostDetailsPage({super.key, required this.slug});

  @override
  State<BlogPostDetailsPage> createState() => _BlogPostDetailsPageState();
}

class _BlogPostDetailsPageState extends State<BlogPostDetailsPage> {
  final BlogPostService _blogPostService = BlogPostService();
  final GlobalKey<FormState> _commentFormKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final TextEditingController _contentController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmittingComment = false;
  String? _errorMessage;
  BlogPostDetailsModel? _details;
  List<BlogCommentModel> _comments = const [];
  int _commentsCount = 0;

  bool _isLiked = false;
  int _likesCount = 0;
  bool _isLikeLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _loadDetails();
    _loadDefaultCommentIdentity();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultCommentIdentity() async {
    final userName = await SharedPrefsHelper.getUserName();
    final userEmail = await SharedPrefsHelper.getUserEmail();

    if (!mounted) return;
    setState(() {
      _nameController.text = userName ?? '';
      _emailController.text = userEmail ?? '';
    });
  }

  Future<void> _loadDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final details = await _blogPostService.fetchBlogPostDetails(widget.slug);
      if (!mounted) return;

      setState(() {
        _details = details;
        _comments = List<BlogCommentModel>.from(details.comments);
        _commentsCount = details.commentsCount > _comments.length
            ? details.commentsCount
            : _comments.length;

        _isLiked = details.isLiked;
        _likesCount = details.likesCount;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AppErrorHelper.toUserMessage(
          e,
          fallback: 'Post details could not be loaded right now.',
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  Future<void> _toggleLike() async {
    final isLoggedIn = await SharedPrefsHelper.isLoggedIn();
    if (!isLoggedIn) {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginSystemSelectPage()),
      );
      return;
    }

    final details = _details;
    if (details == null || _isLikeLoading) return;

    final wasLiked = _isLiked;
    final prevCount = _likesCount;

    setState(() {
      _isLikeLoading = true;
      _isLiked = !wasLiked;
      _likesCount = prevCount + (wasLiked ? -1 : 1);
    });

    try {
      if (wasLiked) {
        await _blogPostService.unlikePost(details.slug);
      } else {
        await _blogPostService.likePost(details.slug);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLiked = wasLiked;
        _likesCount = prevCount;
      });
      AppErrorHelper.showSnackBar(
        context,
        e,
        fallback: 'Could not update like right now.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLikeLoading = false;
        });
      }
    }
  }

  Future<void> _submitComment() async {
    if (!_commentFormKey.currentState!.validate()) return;

    final details = _details;
    if (details == null) return;

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      final comment = await _blogPostService.postComment(
        slug: details.slug,
        authorName: _nameController.text.trim(),
        authorEmail: _emailController.text.trim(),
        content: _contentController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _comments = [comment, ..._comments];
        _commentsCount += 1;
        _contentController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment posted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      AppErrorHelper.showSnackBar(context, e);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingComment = false;
        });
      }
    }
  }

  InputDecoration _commentInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF6B35)),
      ),
    );
  }

  Future<void> _shareCurrentPost() async {
    final details = _details;
    if (details == null) return;

    final shareText =
        '${details.title}\n${ApiConstants.baseUrlWithoutApi}blog/${details.slug}';
    await Share.share(shareText, subject: details.title);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: Color(0xFF111827),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Post Details',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Options',
            onSelected: (value) {
              if (value == 'share') {
                _shareCurrentPost();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem<String>(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Share'),
                  ],
                ),
              ),
            ],
            icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF111827)),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 52,
                color: Color(0xFFFF6B35),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF5F6470)),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _loadDetails,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final details = _details;
    if (details == null) {
      return const SizedBox.shrink();
    }

    return RefreshIndicator(
      onRefresh: _loadDetails,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),

        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailsHeroImage(
                  imageUrl: details.coverImage,
                  heroTag: 'blog-details-image-${details.id}',
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        details.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          _TinyMeta(text: details.timeAgo),
                          _TinyMeta(text: details.category.name),
                          _TinyMeta(text: details.seller.name),
                          _TinyMeta(text: '$_commentsCount comments'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _ExpandableText(
                        text: details.content.isEmpty
                            ? details.summary
                            : details.content,
                        trimLines: 2,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF374151),
                          height: 1.7,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  child: Row(
                    children: [
                      _StatPill(
                        icon: _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                        iconColor: _isLiked
                            ? const Color(0xFF1877F2)
                            : const Color(0xFF6B7280),
                        text: '$_likesCount Likes',
                      ),
                      const SizedBox(width: 8),
                      _StatPill(
                        icon: Icons.mode_comment_outlined,
                        iconColor: const Color(0xFF6B7280),
                        text: '$_commentsCount Comments',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF0F2F5)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: _isLikeLoading
                              ? Icons.hourglass_top_rounded
                              : _isLiked
                              ? Icons.thumb_up
                              : Icons.thumb_up_outlined,
                          label: 'Like',
                          color: _isLiked
                              ? const Color(0xFF1877F2)
                              : const Color(0xFF6B7280),
                          onTap: _toggleLike,
                        ),
                      ),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.share_outlined,
                          label: 'Share',
                          color: const Color(0xFF6B7280),
                          onTap: _shareCurrentPost,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 10),
                Form(
                  key: _commentFormKey,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F7FB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: _commentInputDecoration('Your name'),
                          validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'Name is required'
                              : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _commentInputDecoration('Your email'),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!value.contains('@')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _contentController,
                          minLines: 3,
                          maxLines: 5,
                          decoration: _commentInputDecoration('Write a comment'),
                          validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'Comment is required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isSubmittingComment ? null : _submitComment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFF6B35),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: _isSubmittingComment
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Icon(Icons.send_rounded),
                            label: Text(
                              _isSubmittingComment ? 'Posting...' : 'Post Comment',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (_comments.isEmpty)
                  const Text(
                    'No comments yet on this post.',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                  )
                else
                  ..._comments.map(
                        (comment) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CommentTile(comment: comment),
                    ),
                  ),
              ],
            ),
          ),
        ],

      ),
    );
  }
}

class _CommentsSheetState extends State<_CommentsSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  final TextEditingController _contentController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late List<BlogCommentModel> _comments;
  late int _totalComments;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _comments = List<BlogCommentModel>.from(widget.comments);
    _totalComments = widget.totalComments;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final comment = await widget.onSubmit(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _contentController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _comments = [comment, ..._comments];
        _totalComments += 1;
        _contentController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment posted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      AppErrorHelper.showSnackBar(context, e);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Comments',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.post.title}  •  $_totalComments total',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                  children: [
                    Form(
                      key: _formKey,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F7FB),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: _inputDecoration('Your name'),
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                  ? 'Name is required'
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _inputDecoration('Your email'),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email is required';
                                }
                                if (!value.contains('@')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _contentController,
                              minLines: 3,
                              maxLines: 5,
                              decoration: _inputDecoration('Write a comment'),
                              validator: (value) =>
                                  (value == null || value.trim().isEmpty)
                                  ? 'Comment is required'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isSubmitting ? null : _handleSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF6B35),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: _isSubmitting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.send_rounded),
                                label: Text(
                                  _isSubmitting ? 'Posting...' : 'Post Comment',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_comments.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'No local comments yet. Add the first one from the form above.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                            height: 1.5,
                          ),
                        ),
                      )
                    else
                      ..._comments.map(
                        (comment) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CommentTile(comment: comment),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF6B35)),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final BlogCommentModel comment;

  const _CommentTile({required this.comment});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFFFE4D8),
                child: Text(
                  _initials(comment.authorName),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF6B35),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.authorName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    Text(
                      comment.timeAgo.isEmpty
                          ? comment.publishedAt
                          : comment.timeAgo,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comment.content,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsHeroImage extends StatelessWidget {
  final String imageUrl;
  final String? heroTag;

  const _DetailsHeroImage({required this.imageUrl, this.heroTag});

  @override
  Widget build(BuildContext context) {
    final imageWidget = imageUrl.isEmpty
        ? Container(
            color: const Color(0xFFF3F4F6),
            child: const Icon(
              Icons.image_not_supported_outlined,
              size: 44,
              color: Color(0xFF9AA1AE),
            ),
          )
        : CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => Container(
              color: const Color(0xFFF0F2F7),
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: const Color(0xFFF0F2F7),
              child: const Icon(
                Icons.broken_image_outlined,
                size: 36,
                color: Color(0xFF9AA1AE),
              ),
            ),
          );

    final content = ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(18),
        topRight: Radius.circular(18),
      ),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          color: const Color(0xFFF6F7FB),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (heroTag != null && imageUrl.isNotEmpty)
                Hero(tag: heroTag!, child: imageWidget)
              else
                imageWidget,
              if (imageUrl.isNotEmpty)
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.zoom_out_map, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Tap to zoom',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (imageUrl.isEmpty) return content;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    ImageViewer(imageUrl: imageUrl, heroTag: heroTag),
              ),
            );
          },
          child: content,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _StatPill({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: iconColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyMeta extends StatelessWidget {
  final String text;

  const _TinyMeta({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFF6B7280),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ExpandableText extends StatefulWidget {
  final String text;
  final int trimLines;
  final TextStyle style;

  const _ExpandableText({
    required this.text,
    required this.trimLines,
    required this.style,
  });

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final displayText = widget.text.trim().isEmpty
        ? 'No details available.'
        : widget.text.trim();

    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: displayText, style: widget.style),
          maxLines: widget.trimLines,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);

        final hasOverflow = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayText,
              maxLines: _isExpanded ? null : widget.trimLines,
              overflow: _isExpanded
                  ? TextOverflow.visible
                  : TextOverflow.ellipsis,
              style: widget.style,
            ),
            if (hasOverflow)
              InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _isExpanded ? 'See less' : 'See more',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _BlogCoverImage extends StatelessWidget {
  final String imageUrl;
  final double height;
  final double borderRadius;
  final double? bottomRadius;

  const _BlogCoverImage({
    required this.imageUrl,
    required this.height,
    required this.borderRadius,
    this.bottomRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.only(
      topLeft: Radius.circular(borderRadius),
      topRight: Radius.circular(borderRadius),
      bottomLeft: Radius.circular(bottomRadius ?? borderRadius),
      bottomRight: Radius.circular(bottomRadius ?? borderRadius),
    );

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: double.infinity,
        height: height,
        color: const Color(0xFFF0F2F7),
        child: imageUrl.isEmpty
            ? const Icon(
                Icons.image_not_supported_outlined,
                size: 30,
                color: Color(0xFF9AA1AE),
              )
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => Container(
                  color: const Color(0xFFF0F2F7),
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: const Color(0xFFF0F2F7),
                  child: const Icon(
                    Icons.broken_image_outlined,
                    size: 28,
                    color: Color(0xFF9AA1AE),
                  ),
                ),
              ),
      ),
    );
  }
}

String _initials(String text) {
  final parts = text
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty);
  if (parts.isEmpty) return 'BP';

  final first = parts.first.characters.first;
  final second = parts.length > 1 ? parts.last.characters.first : '';
  return (first + second).toUpperCase();
}
