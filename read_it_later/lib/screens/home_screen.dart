import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../models/article.dart';
import 'package:read_it_later/services/api_service.dart';
import 'package:read_it_later/services/auth_service.dart';
import 'package:read_it_later/screens/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _apiService = ApiService();
  List<Article> _articles = [];
  bool _isLoading = false;
  StreamSubscription? _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _checkGasUrl();
    _setupSharingIntent();
  }

  @override
  void dispose() {
    _intentDataStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _checkGasUrl() async {
    final url = await _apiService.getGasUrl();
    if (url == null || url.isEmpty) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        ).then((_) => _refreshArticles());
      }
    } else {
      _refreshArticles();
    }
  }

  void _setupSharingIntent() {
    // receive_sharing_intent is not supported on Web
    if (kIsWeb) return;

    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedContent(value.first.path);
      }
    }, onError: (err) {
      print("getIntentDataStream error: $err");
    });

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedContent(value.first.path);
      }
    });
  }

  void _handleSharedContent(String text) {
    // Simple check if it looks like a URL
    if (text.startsWith('http')) {
      _addArticle(text);
    }
  }

  Future<void> _signIn() async {
    final user = await AuthService().signIn();
    if (user != null) {
      _refreshArticles();
    }
    setState(() {});
  }

  Future<void> _signOut() async {
    await AuthService().signOut();
    setState(() {
      _articles = [];
    });
  }

  Future<void> _refreshArticles() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final articles = await _apiService.fetchArticles();
      setState(() {
        _articles = articles.where((a) => !a.isRead).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addArticle(String url) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _apiService.addArticle(url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Article added')),
        );
      }
      _refreshArticles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding article: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(Article article) async {
    try {
      await _apiService.markAsRead(article.id);
      setState(() {
        _articles.remove(article);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked as read')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _openArticle(Article article) async {
    final uri = Uri.parse(article.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch URL')),
        );
      }
    }
  }

  void _showAddDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Article'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'URL'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (controller.text.isNotEmpty) {
                _addArticle(controller.text);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Read It Later'),
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _signOut,
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              _refreshArticles();
            },
          ),
        ],
      ),
      body: user == null
          ? Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
                onPressed: _signIn,
              ),
            )
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _articles.isEmpty
                  ? const Center(child: Text('No articles found'))
                  : RefreshIndicator(
                      onRefresh: _refreshArticles,
                      child: ListView.builder(
                        itemCount: _articles.length,
                        itemBuilder: (context, index) {
                          final article = _articles[index];
                          return Dismissible(
                            key: Key(article.id),
                            background: Container(
                              color: Colors.green,
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20),
                              child: const Icon(Icons.check, color: Colors.white),
                            ),
                            direction: DismissDirection.startToEnd,
                            onDismissed: (direction) {
                              _markAsRead(article);
                            },
                            child: ListTile(
                              title: Text(
                                article.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                DateFormat('yyyy-MM-dd HH:mm').format(article.addedDate),
                              ),
                              onTap: () => _openArticle(article),
                              trailing: IconButton(
                                icon: const Icon(Icons.open_in_new),
                                onPressed: () => _openArticle(article),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
