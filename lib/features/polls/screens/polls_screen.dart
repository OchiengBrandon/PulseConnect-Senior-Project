import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pulse_connect_app/core/config/routes.dart';
import 'package:pulse_connect_app/core/models/poll_model.dart';
import 'package:pulse_connect_app/features/polls/providers/poll_provider.dart';
import 'package:pulse_connect_app/features/polls/widgets/poll_card.dart';
import 'package:pulse_connect_app/shared/widgets/app_button.dart';
import 'package:pulse_connect_app/shared/widgets/error_dialog.dart';
import 'package:pulse_connect_app/shared/widgets/loading_indicator.dart';

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

    // Initialize polls data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pollProvider = Provider.of<PollProvider>(context, listen: false);

      // Load public polls
      pollProvider.initPublicPolls();

      // If user is logged in, load their polls
      final currentUserId = ''; // TODO: Get from AuthProvider
      if (currentUserId.isNotEmpty) {
        pollProvider.initUserPolls(currentUserId);
      }

      // If user belongs to an institution, load institution polls
      final institutionId = ''; // TODO: Get from AuthProvider or UserProvider
      if (institutionId.isNotEmpty) {
        pollProvider.initInstitutionPolls(institutionId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await Provider.of<PollProvider>(
        context,
        listen: false,
      ).searchPolls(query);

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      if (context.mounted) {
        ErrorDialog(
          message: 'Error searching polls: $e',
          onClose: () => Navigator.pop(context),
        );
      }
    }
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
                  autofocus: true,
                  onSubmitted: _performSearch,
                )
                : const Text('Polls'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _isSearching = false;
                  _searchResults = [];
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
        bottom:
            _isSearching
                ? null
                : TabBar(
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
          Navigator.pushNamed(context, AppRoutes.createPoll);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching && _searchResults.isEmpty) {
      return const Center(child: LoadingIndicator());
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Text('No polls found. Try a different search term.'),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final poll = _searchResults[index];
        return PollCard(poll: poll, onTap: () => _navigateToPollDetails(poll));
      },
    );
  }

  Widget _buildPublicPollsList() {
    return Consumer<PollProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: LoadingIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${provider.error}'),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Retry',
                  onPressed: () {
                    provider.initPublicPolls();
                  },
                ),
              ],
            ),
          );
        }

        if (provider.publicPolls.isEmpty) {
          return const Center(child: Text('No public polls available.'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            provider.initPublicPolls();
          },
          child: ListView.builder(
            itemCount: provider.publicPolls.length,
            itemBuilder: (context, index) {
              final poll = provider.publicPolls[index];
              return PollCard(
                poll: poll,
                onTap: () => _navigateToPollDetails(poll),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildInstitutionPollsList() {
    return Consumer<PollProvider>(
      builder: (context, provider, child) {
        // TODO: Get institutionId from AuthProvider or UserProvider
        final String institutionId = '';
        final bool isUserInInstitution = institutionId.isNotEmpty;

        if (!isUserInInstitution) {
          return const Center(
            child: Text('You are not part of any institution.'),
          );
        }

        if (provider.isLoading) {
          return const Center(child: LoadingIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${provider.error}'),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Retry',
                  onPressed: () {
                    provider.initInstitutionPolls(institutionId);
                  },
                ),
              ],
            ),
          );
        }

        if (provider.institutionPolls.isEmpty) {
          return const Center(child: Text('No institution polls available.'));
        }

        return RefreshIndicator(
          onRefresh: () async {
            provider.initInstitutionPolls(institutionId);
          },
          child: ListView.builder(
            itemCount: provider.institutionPolls.length,
            itemBuilder: (context, index) {
              final poll = provider.institutionPolls[index];
              return PollCard(
                poll: poll,
                onTap: () => _navigateToPollDetails(poll),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildUserPollsList() {
    return Consumer<PollProvider>(
      builder: (context, provider, child) {
        // TODO: Get userId from AuthProvider
        final String userId = '';
        final bool isUserLoggedIn = userId.isNotEmpty;

        if (!isUserLoggedIn) {
          return const Center(child: Text('Please log in to view your polls.'));
        }

        if (provider.isLoading) {
          return const Center(child: LoadingIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${provider.error}'),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Retry',
                  onPressed: () {
                    provider.initUserPolls(userId);
                  },
                ),
              ],
            ),
          );
        }

        if (provider.userPolls.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('You haven\'t created any polls yet.'),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Create Poll',
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.createPoll);
                  },
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            provider.initUserPolls(userId);
          },
          child: ListView.builder(
            itemCount: provider.userPolls.length,
            itemBuilder: (context, index) {
              final poll = provider.userPolls[index];
              return PollCard(
                poll: poll,
                onTap: () => _navigateToPollDetails(poll),
              );
            },
          ),
        );
      },
    );
  }

  void _navigateToPollDetails(PollModel poll) {
    Provider.of<PollProvider>(context, listen: false).setCurrentPoll(poll);
    Navigator.pushNamed(context, AppRoutes.pollDetails);
  }
}
