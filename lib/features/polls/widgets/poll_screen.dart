import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulse_connect_app/features/auth/providers/auth_provider.dart';
import 'package:pulse_connect_app/features/polls/providers/poll_provider.dart';
import '../../../core/models/poll_model.dart';
import '../widgets/poll_card.dart';

class PollsScreen extends StatefulWidget {
  const PollsScreen({Key? key}) : super(key: key);

  @override
  State<PollsScreen> createState() => _PollsScreenState();
}

class _PollsScreenState extends State<PollsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<PollModel> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Initialize polls based on user type
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pollProvider = Provider.of<PollProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Load public polls for everyone
      pollProvider.initPublicPolls();

      // Load institution polls if user is a student or institution
      if (authProvider.isInstitution ||
          (authProvider.isStudent &&
              authProvider.currentUser?.institutionId != null)) {
        pollProvider.initInstitutionPolls(
          authProvider.isInstitution
              ? authProvider.currentUser!.id
              : authProvider.currentUser!.institutionId!,
        );
      }

      // Load user polls if authenticated
      if (authProvider.currentUser != null) {
        pollProvider.initUserPolls(authProvider.currentUser!.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    final pollProvider = Provider.of<PollProvider>(context, listen: false);
    pollProvider.searchPolls(query).then((results) {
      setState(() {
        _isSearching = true;
        _searchResults = results;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            _isSearching
                ? TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search polls...',
                    border: InputBorder.none,
                  ),
                  onChanged: _performSearch,
                )
                : const Text('Polls'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _searchResults = [];
                }
                _isSearching = !_isSearching;
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Public'),
            Tab(text: 'Institution'),
            Tab(text: 'My Polls'),
          ],
        ),
      ),
      body:
          _isSearching
              ? _buildSearchResults()
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildPublicPollsList(),
                  _buildInstitutionPollsList(),
                  _buildUserPollsList(),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/create-poll');
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const Center(child: Text('No results found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        return PollCard(
          poll: _searchResults[index],
          onTap: () => _navigateToPollDetails(_searchResults[index]),
        );
      },
    );
  }

  Widget _buildPublicPollsList() {
    return Consumer<PollProvider>(
      builder: (context, pollProvider, child) {
        if (pollProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (pollProvider.error != null) {
          return Center(child: Text('Error: ${pollProvider.error}'));
        }

        final polls = pollProvider.publicPolls;
        if (polls.isEmpty) {
          return const Center(child: Text('No public polls available'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            pollProvider.initPublicPolls();
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: polls.length,
            itemBuilder: (context, index) {
              return PollCard(
                poll: polls[index],
                onTap: () => _navigateToPollDetails(polls[index]),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInstitutionPollsList() {
    final authProvider = Provider.of<AuthProvider>(context);

    // Check if user can see institution polls
    if (!authProvider.isInstitution &&
        !(authProvider.isStudent &&
            authProvider.currentUser?.institutionId != null)) {
      return const Center(
        child: Text(
          'You need to be verified by an institution to see these polls',
        ),
      );
    }

    return Consumer<PollProvider>(
      builder: (context, pollProvider, child) {
        if (pollProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (pollProvider.error != null) {
          return Center(child: Text('Error: ${pollProvider.error}'));
        }

        final polls = pollProvider.institutionPolls;
        if (polls.isEmpty) {
          return const Center(child: Text('No institution polls available'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            final String institutionId =
                authProvider.isInstitution
                    ? authProvider.currentUser!.id
                    : authProvider.currentUser!.institutionId!;
            pollProvider.initInstitutionPolls(institutionId);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: polls.length,
            itemBuilder: (context, index) {
              return PollCard(
                poll: polls[index],
                onTap: () => _navigateToPollDetails(polls[index]),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildUserPollsList() {
    final authProvider = Provider.of<AuthProvider>(context);

    // Check if user is authenticated
    if (!authProvider.isAuthenticated) {
      return const Center(child: Text('Please login to see your polls'));
    }

    return Consumer<PollProvider>(
      builder: (context, pollProvider, child) {
        if (pollProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (pollProvider.error != null) {
          return Center(child: Text('Error: ${pollProvider.error}'));
        }

        final polls = pollProvider.userPolls;
        if (polls.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('You haven\'t created any polls yet'),
                SizedBox(height: 16),
                Text('Tap the + button to create your first poll'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            pollProvider.initUserPolls(authProvider.currentUser!.id);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: polls.length,
            itemBuilder: (context, index) {
              return PollCard(
                poll: polls[index],
                onTap: () => _navigateToPollDetails(polls[index]),
                showControls: true,
                onClosePoll: () => pollProvider.closePoll(polls[index].id),
                onReopenPoll: () => pollProvider.reopenPoll(polls[index].id),
                onDeletePoll: () => _confirmDeletePoll(polls[index].id),
              );
            },
          ),
        );
      },
    );
  }

  void _navigateToPollDetails(PollModel poll) {
    // Store the current poll in the provider
    Provider.of<PollProvider>(context, listen: false).setCurrentPoll(poll);
    Navigator.pushNamed(context, '/poll-details');
  }

  Future<void> _confirmDeletePoll(String pollId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Poll'),
            content: const Text(
              'Are you sure you want to delete this poll? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('DELETE'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      final pollProvider = Provider.of<PollProvider>(context, listen: false);
      await pollProvider.deletePoll(pollId);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Poll deleted')));
    }
  }
}
