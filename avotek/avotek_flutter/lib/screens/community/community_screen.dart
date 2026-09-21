import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/avotek_logo.dart';

class CommunityPost {
  final String id;
  final String authorName;
  final String authorTag;
  final String kycTier;
  final String title;
  final String content;
  final String category;
  final DateTime createdAt;
  int upvotes;
  bool isUpvoted;
  final List<CommunityComment> comments;

  CommunityPost({
    required this.id,
    required this.authorName,
    required this.authorTag,
    required this.kycTier,
    required this.title,
    required this.content,
    required this.category,
    required this.createdAt,
    this.upvotes = 0,
    this.isUpvoted = false,
    required this.comments,
  });
}

class CommunityComment {
  final String id;
  final String authorName;
  final String content;
  final DateTime createdAt;

  CommunityComment({
    required this.id,
    required this.authorName,
    required this.content,
    required this.createdAt,
  });
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    '📢 Announcements',
    '💡 Data Deals',
    '🏢 CAC & Business',
    '🎓 Campus Utilities',
    '🛠️ Tech Help',
  ];

  late List<CommunityPost> _posts;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _posts = [
      CommunityPost(
        id: 'post-1',
        authorName: 'AVOTEK Admin',
        authorTag: '@avotek_official',
        kycTier: 'Verified Admin',
        title: '⚡ MTN SME 2.5GB Flash Tariff Active for Academic Resellers',
        content:
            'Dear Avotek Scholars and Agents, the MTN SME route has been upgraded with zero latency. Cost price set at ₦240/GB for bulk campus agents. Enjoy seamless top-ups with instant auto-reversal protection!',
        category: '📢 Announcements',
        createdAt: now.subtract(const Duration(minutes: 45)),
        upvotes: 42,
        isUpvoted: true,
        comments: [
          CommunityComment(
            id: 'c-1',
            authorName: 'Chukwuemeka Obi',
            content: 'Speed is super fast on UNILAG campus! Thank you AVOTEK.',
            createdAt: now.subtract(const Duration(minutes: 30)),
          ),
          CommunityComment(
            id: 'c-2',
            authorName: 'Amina Bello',
            content: 'Can confirm, token delivery was under 3 seconds.',
            createdAt: now.subtract(const Duration(minutes: 10)),
          ),
        ],
      ),
      CommunityPost(
        id: 'post-2',
        authorName: 'Tunde Bakare',
        authorTag: '@tundebakare',
        kycTier: 'Tier 3 Agent',
        title: '💡 Quick tip on CAC Business Name Registration for Students',
        content:
            'If you run a campus graphic design or laundry brand, register your business name via the new AVOTEK CAC portal. Took 4 working days to get my certificate & Status Report directly in PDF. Great for opening corporate bank accounts!',
        category: '🏢 CAC & Business',
        createdAt: now.subtract(const Duration(hours: 3)),
        upvotes: 28,
        isUpvoted: false,
        comments: [
          CommunityComment(
            id: 'c-3',
            authorName: 'Emeka Smart',
            content: 'Did you submit NIN slip or National ID card?',
            createdAt: now.subtract(const Duration(hours: 2)),
          ),
          CommunityComment(
            id: 'c-4',
            authorName: 'Tunde Bakare',
            content: 'NIN slip with clear QR code works 100% fine!',
            createdAt: now.subtract(const Duration(hours: 1)),
          ),
        ],
      ),
      CommunityPost(
        id: 'post-3',
        authorName: 'Ngozi Eze',
        authorTag: '@ngozieze',
        kycTier: 'Tier 2 Scholar',
        title: '🎓 Best electricity token purchase time before month end',
        content:
            'Heads up for IBEDC and EKEDC users in off-campus hostels: try recharging during off-peak morning hours (7am-9am) to avoid disco aggregator congestion. The receipt PDF from AVOTEK has the 20-digit token clearly bolded.',
        category: '🎓 Campus Utilities',
        createdAt: now.subtract(const Duration(hours: 6)),
        upvotes: 19,
        isUpvoted: false,
        comments: [],
      ),
      CommunityPost(
        id: 'post-4',
        authorName: 'Kelechi Nwosu',
        authorTag: '@kelechinvtu',
        kycTier: 'Tier 3 Reseller',
        title: '💡 GLO Corporate Gifting vs SME Data breakdown',
        content:
            'For night downloaders, Glo 5.75GB Corporate bundle has 30 days validity and does not throttle. Tested on ABU Zaria network masts.',
        category: '💡 Data Deals',
        createdAt: now.subtract(const Duration(days: 1)),
        upvotes: 35,
        isUpvoted: true,
        comments: [
          CommunityComment(
            id: 'c-5',
            authorName: 'Fatima Umar',
            content: 'Does it work for router SIMs too?',
            createdAt: now.subtract(const Duration(hours: 18)),
          ),
        ],
      ),
    ];
  }

  void _toggleUpvote(CommunityPost post) {
    setState(() {
      if (post.isUpvoted) {
        post.upvotes--;
        post.isUpvoted = false;
      } else {
        post.upvotes++;
        post.isUpvoted = true;
      }
    });
  }

  void _openCreatePostModal() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String selectedTag = _categories[1]; // default to Announcements/Deals

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Create Community Post',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'CATEGORY CHANNEL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _categories.skip(1).map((cat) {
                          final isSelected = cat == selectedTag;
                          return ChoiceChip(
                            label: Text(
                              cat,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? AppColors.metallicLight : AppColors.slateGrey),
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: isDark ? AppColors.primaryCyan : AppColors.primaryBlue,
                            backgroundColor: isDark ? AppColors.darkCardVariant : AppColors.lightCardVariant,
                            onSelected: (_) => setModalState(() => selectedTag = cat),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: titleController,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                          labelText: 'Post Title',
                          hintText: 'e.g., Best MTN data strategy for exam prep...',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: contentController,
                        maxLines: 4,
                        style: const TextStyle(fontSize: 12),
                        decoration: const InputDecoration(
                          labelText: 'Discussion Details',
                          hintText: 'Share tips, ask questions, or verify campus rates...',
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () {
                            final title = titleController.text.trim();
                            final content = contentController.text.trim();
                            if (title.isEmpty || content.isEmpty) return;

                            final user = context.read<AuthProvider>().user;
                            final newPost = CommunityPost(
                              id: 'post-${DateTime.now().millisecondsSinceEpoch}',
                              authorName: user?.name ?? 'Avotek Scholar',
                              authorTag: '@${user?.phone ?? "user"}',
                              kycTier: user?.kycStatus.toUpperCase() ?? 'TIER 1',
                              title: title,
                              content: content,
                              category: selectedTag,
                              createdAt: DateTime.now(),
                              comments: [],
                            );

                            setState(() {
                              _posts.insert(0, newPost);
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Publish to Community', style: TextStyle(fontSize: 13)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openCommentsModal(CommunityPost post) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Discussion (${post.comments.length})',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    Text(
                      post.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                      ),
                    ),
                    const Divider(height: 20),
                    Expanded(
                      child: post.comments.isEmpty
                          ? Center(
                              child: Text(
                                'No replies yet. Be the first to share your thoughts!',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                                ),
                              ),
                            )
                          : ListView.separated(
                              itemCount: post.comments.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (ctx, idx) {
                                final c = post.comments[idx];
                                return Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkCardVariant : AppColors.lightCardVariant,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            c.authorName,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          Text(
                                            DateFormat('hh:mm a').format(c.createdAt),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        c.content,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          height: 1.3,
                                          color: isDark ? AppColors.metallicLight : const Color(0xFF334155),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: commentController,
                            style: const TextStyle(fontSize: 12),
                            decoration: const InputDecoration(
                              hintText: 'Add a helpful reply...',
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          icon: const Icon(Icons.send_rounded, size: 16),
                          onPressed: () {
                            final text = commentController.text.trim();
                            if (text.isEmpty) return;
                            final user = context.read<AuthProvider>().user;
                            final newComment = CommunityComment(
                              id: 'c-${DateTime.now().millisecondsSinceEpoch}',
                              authorName: user?.name ?? 'Scholar',
                              content: text,
                              createdAt: DateTime.now(),
                            );
                            setModalState(() {
                              post.comments.add(newComment);
                            });
                            setState(() {});
                            commentController.clear();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredPosts = _selectedCategory == 'All'
        ? _posts
        : _posts.where((p) => p.category == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            AvotekBrandAsset(height: 28, isDark: isDark),
            const SizedBox(width: 10),
            const Text(
              'Community Hub',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Create Post',
            icon: const Icon(Icons.edit_note_rounded, size: 22),
            onPressed: _openCreatePostModal,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              // Category Filter Strip
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, idx) {
                    final cat = _categories[idx];
                    final isSelected = cat == _selectedCategory;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (isDark ? AppColors.primaryCyan : AppColors.primaryBlue)
                              : (isDark ? AppColors.darkCard : AppColors.lightCard),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? (isDark ? const Color(0xFF002B47) : Colors.white)
                                  : (isDark ? AppColors.metallicLight : AppColors.slateGrey),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),

              // Post List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: filteredPosts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final post = filteredPosts[idx];
                    return _buildPostCard(post, isDark);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreatePostModal,
        backgroundColor: isDark ? AppColors.primaryCyan : AppColors.primaryBlue,
        foregroundColor: isDark ? const Color(0xFF002B47) : Colors.white,
        icon: const Icon(Icons.add_comment_rounded, size: 18),
        label: const Text(
          'New Post',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildPostCard(CommunityPost post, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.primaryCyan.withValues(alpha: 0.15),
                child: Text(
                  post.authorName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryCyan,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          post.authorName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            post.kycTier,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryCyan,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${post.authorTag} • ${DateFormat('d MMM, h:mm a').format(post.createdAt)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCardVariant : AppColors.lightCardVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  post.category,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Post Title
          Text(
            post.title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),

          // Post Content
          Text(
            post.content,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? AppColors.metallicLight : const Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 12),

          // Action Row (Upvote & Comments)
          Row(
            children: [
              InkWell(
                onTap: () => _toggleUpvote(post),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: post.isUpvoted
                        ? AppColors.primaryCyan.withValues(alpha: 0.14)
                        : (isDark ? AppColors.darkCardVariant : AppColors.lightCardVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        post.isUpvoted ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                        size: 14,
                        color: post.isUpvoted ? AppColors.primaryCyan : (isDark ? AppColors.metallicLight : AppColors.slateGrey),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${post.upvotes}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: post.isUpvoted ? AppColors.primaryCyan : (isDark ? AppColors.metallicLight : AppColors.slateGrey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _openCommentsModal(post),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardVariant : AppColors.lightCardVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 14,
                        color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${post.comments.length} Replies',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.metallicLight : AppColors.slateGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
