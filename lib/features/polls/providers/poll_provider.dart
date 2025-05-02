import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pulse_connect_app/core/models/poll_model.dart';
import 'package:pulse_connect_app/core/services/poll_service.dart';
import 'package:uuid/uuid.dart';

/// Provider class to manage polls state and interact with PollService
class PollProvider extends ChangeNotifier {
  final PollService _pollService;
  final _uuid = const Uuid();

  // State variables
  List<PollModel> _publicPolls = [];
  List<PollModel> _institutionPolls = [];
  List<PollModel> _userPolls = [];
  PollModel? _currentPoll;
  bool _isLoading = false;
  String? _error;

  // Stream subscriptions
  StreamSubscription? _publicPollsSubscription;
  StreamSubscription? _institutionPollsSubscription;
  StreamSubscription? _userPollsSubscription;

  // Getters
  List<PollModel> get publicPolls => _publicPolls;
  List<PollModel> get institutionPolls => _institutionPolls;
  List<PollModel> get userPolls => _userPolls;
  PollModel? get currentPoll => _currentPoll;
  bool get isLoading => _isLoading;
  String? get error => _error;

  PollProvider(this._pollService);

  /// Initialize streams for public polls
  void initPublicPolls() {
    _setLoading(true);
    _publicPollsSubscription?.cancel();
    _publicPollsSubscription = _pollService.getPublicPolls().listen(
      (polls) {
        _publicPolls = polls;
        _setLoading(false);
        notifyListeners();
      },
      onError: (error) {
        _setError('Failed to load public polls: $error');
      },
    );
  }

  /// Initialize streams for institution polls
  void initInstitutionPolls(String institutionId) {
    _setLoading(true);
    _institutionPollsSubscription?.cancel();
    _institutionPollsSubscription = _pollService
        .getInstitutionPolls(institutionId)
        .listen(
          (polls) {
            _institutionPolls = polls;
            _setLoading(false);
            notifyListeners();
          },
          onError: (error) {
            _setError('Failed to load institution polls: $error');
          },
        );
  }

  /// Initialize streams for user polls
  void initUserPolls(String userId) {
    _setLoading(true);
    _userPollsSubscription?.cancel();
    _userPollsSubscription = _pollService
        .getUserPolls(userId)
        .listen(
          (polls) {
            _userPolls = polls;
            _setLoading(false);
            notifyListeners();
          },
          onError: (error) {
            _setError('Failed to load user polls: $error');
          },
        );
  }

  /// Fetch a specific poll by ID
  Future<void> fetchPoll(String pollId) async {
    _setLoading(true);
    _clearError();

    try {
      final poll = await _pollService.getPoll(pollId);
      _currentPoll = poll;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to fetch poll: $e');
    }
  }

  /// Create a new poll
  Future<PollModel> createPoll({
    required String title,
    required String description,
    required String creatorId,
    required String creatorName,
    String? creatorImageUrl,
    required String pollType,
    String? institutionId,
    required List<PollOption> options,
    required DateTime expiresAt,
    List<String>? tags,
    String? questionType = 'single_choice',
    Map<String, dynamic>? additionalData,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final poll = await _pollService.createPoll(
        title: title,
        description: description,
        creatorId: creatorId,
        creatorName: creatorName,
        creatorImageUrl: creatorImageUrl,
        pollType: pollType,
        institutionId: institutionId,
        options: options,
        expiresAt: expiresAt,
        tags: tags,
        questionType: questionType,
        additionalData: additionalData,
      );

      _currentPoll = poll;
      _setLoading(false);
      notifyListeners();
      return poll;
    } catch (e) {
      _setError('Failed to create poll: $e');
      rethrow;
    }
  }

  /// Create a multi-type question poll
  Future<PollModel> createMultiTypeQuestion({
    required String title,
    required String description,
    required String creatorId,
    required String creatorName,
    String? creatorImageUrl,
    required String pollType,
    String? institutionId,
    required List<PollOption> options,
    required DateTime expiresAt,
    required String questionType,
    Map<String, dynamic>? questionConfig,
    List<String>? tags,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final poll = await _pollService.createMultiTypeQuestion(
        title: title,
        description: description,
        creatorId: creatorId,
        creatorName: creatorName,
        creatorImageUrl: creatorImageUrl,
        pollType: pollType,
        institutionId: institutionId,
        options: options,
        expiresAt: expiresAt,
        questionType: questionType,
        questionConfig: questionConfig,
        tags: tags,
      );

      _currentPoll = poll;
      _setLoading(false);
      notifyListeners();
      return poll;
    } catch (e) {
      _setError('Failed to create poll: $e');
      rethrow;
    }
  }

  /// Update an existing poll
  Future<PollModel> updatePoll(PollModel poll) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedPoll = await _pollService.updatePoll(poll);

      if (_currentPoll?.id == updatedPoll.id) {
        _currentPoll = updatedPoll;
      }

      _setLoading(false);
      notifyListeners();
      return updatedPoll;
    } catch (e) {
      _setError('Failed to update poll: $e');
      rethrow;
    }
  }

  /// Delete a poll
  Future<void> deletePoll(String pollId) async {
    _setLoading(true);
    _clearError();

    try {
      await _pollService.deletePoll(pollId);

      if (_currentPoll?.id == pollId) {
        _currentPoll = null;
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete poll: $e');
      rethrow;
    }
  }

  /// Submit a response to a poll
  Future<PollResponse> submitPollResponse({
    required String pollId,
    required String userId,
    required String optionId,
    Map<String, dynamic>? additionalData,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _pollService.submitPollResponse(
        pollId: pollId,
        userId: userId,
        optionId: optionId,
        additionalData: additionalData,
      );

      // If we have the current poll loaded, update its response count
      if (_currentPoll?.id == pollId) {
        await fetchPoll(pollId);
      }

      _setLoading(false);
      notifyListeners();
      return response;
    } catch (e) {
      _setError('Failed to submit response: $e');
      rethrow;
    }
  }

  /// Submit a multiple-choice response
  Future<PollResponse> submitMultipleChoiceResponse({
    required String pollId,
    required String userId,
    required List<String> optionIds,
    Map<String, dynamic>? additionalData,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Create a special response ID
      final responseId = _uuid.v4();

      // Use a transaction to update multiple options
      final batch = FirebaseFirestore.instance.batch();

      // Create the response object
      final response = MultipleChoicePollResponse(
        id: responseId,
        pollId: pollId,
        userId: userId,
        optionIds: optionIds,
        createdAt: DateTime.now(),
        additionalData: additionalData,
      );

      // Convert DateTime to Timestamp for Firestore
      final responseData = response.toJson();
      responseData['createdAt'] = Timestamp.fromDate(response.createdAt);

      // Set the response document
      batch.set(
        FirebaseFirestore.instance.collection('poll_responses').doc(responseId),
        responseData,
      );

      // Get the current poll document
      final pollDoc =
          await FirebaseFirestore.instance
              .collection('polls')
              .doc(pollId)
              .get();
      final pollData = pollDoc.data() as Map<String, dynamic>;
      final poll = PollModel.fromJson(pollData);

      // Update each selected option's count
      final updatedOptions = List<PollOption>.from(poll.options);
      for (var optionId in optionIds) {
        final optionIndex = updatedOptions.indexWhere((o) => o.id == optionId);
        if (optionIndex >= 0) {
          updatedOptions[optionIndex] = updatedOptions[optionIndex].copyWith(
            count: updatedOptions[optionIndex].count + 1,
          );
        }
      }

      // Update the poll with new option counts and response count
      batch.update(FirebaseFirestore.instance.collection('polls').doc(pollId), {
        'options': updatedOptions.map((o) => o.toJson()).toList(),
        'responseCount': FieldValue.increment(1),
      });

      // Commit the transaction
      await batch.commit();

      // If we have the current poll loaded, update it
      if (_currentPoll?.id == pollId) {
        await fetchPoll(pollId);
      }

      _setLoading(false);
      notifyListeners();
      return response;
    } catch (e) {
      _setError('Failed to submit multiple choice response: $e');
      rethrow;
    }
  }

  /// Submit a likert scale response
  Future<PollResponse> submitLikertScaleResponse({
    required String pollId,
    required String userId,
    required int value,
    Map<String, dynamic>? additionalData,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Create a special response ID
      final responseId = _uuid.v4();

      // Create the response object
      final response = LikertScalePollResponse(
        id: responseId,
        pollId: pollId,
        userId: userId,
        value: value,
        createdAt: DateTime.now(),
        additionalData: additionalData,
      );

      // Convert DateTime to Timestamp for Firestore
      final responseData = response.toJson();
      responseData['createdAt'] = Timestamp.fromDate(response.createdAt);

      // Add the response to Firestore
      await FirebaseFirestore.instance
          .collection('poll_responses')
          .doc(responseId)
          .set(responseData);

      // Update the poll response count
      await FirebaseFirestore.instance.collection('polls').doc(pollId).update({
        'responseCount': FieldValue.increment(1),
      });

      // If we have the current poll loaded, update it
      if (_currentPoll?.id == pollId) {
        await fetchPoll(pollId);
      }

      _setLoading(false);
      notifyListeners();
      return response;
    } catch (e) {
      _setError('Failed to submit likert scale response: $e');
      rethrow;
    }
  }

  /// Submit a ranking response
  Future<PollResponse> submitRankingResponse({
    required String pollId,
    required String userId,
    required List<String> rankedOptionIds,
    Map<String, dynamic>? additionalData,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Create a special response ID
      final responseId = _uuid.v4();

      // Create the response object
      final response = RankingPollResponse(
        id: responseId,
        pollId: pollId,
        userId: userId,
        rankedOptionIds: rankedOptionIds,
        createdAt: DateTime.now(),
        additionalData: additionalData,
      );

      // Convert DateTime to Timestamp for Firestore
      final responseData = response.toJson();
      responseData['createdAt'] = Timestamp.fromDate(response.createdAt);

      // Add the response to Firestore
      await FirebaseFirestore.instance
          .collection('poll_responses')
          .doc(responseId)
          .set(responseData);

      // Update the poll response count
      await FirebaseFirestore.instance.collection('polls').doc(pollId).update({
        'responseCount': FieldValue.increment(1),
      });

      // If we have the current poll loaded, update it
      if (_currentPoll?.id == pollId) {
        await fetchPoll(pollId);
      }

      _setLoading(false);
      notifyListeners();
      return response;
    } catch (e) {
      _setError('Failed to submit ranking response: $e');
      rethrow;
    }
  }

  /// Submit an open-ended response
  Future<PollResponse> submitOpenEndedResponse({
    required String pollId,
    required String userId,
    required String response,
    Map<String, dynamic>? additionalData,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Create a special response ID
      final responseId = _uuid.v4();

      // Create the response object
      final openEndedResponse = OpenEndedPollResponse(
        id: responseId,
        pollId: pollId,
        userId: userId,
        response: response,
        createdAt: DateTime.now(),
        additionalData: additionalData,
      );

      // Convert DateTime to Timestamp for Firestore
      final responseData = openEndedResponse.toJson();
      responseData['createdAt'] = Timestamp.fromDate(
        openEndedResponse.createdAt,
      );

      // Add the response to Firestore
      await FirebaseFirestore.instance
          .collection('poll_responses')
          .doc(responseId)
          .set(responseData);

      // Update the poll response count
      await FirebaseFirestore.instance.collection('polls').doc(pollId).update({
        'responseCount': FieldValue.increment(1),
      });

      // If we have the current poll loaded, update it
      if (_currentPoll?.id == pollId) {
        await fetchPoll(pollId);
      }

      _setLoading(false);
      notifyListeners();
      return openEndedResponse;
    } catch (e) {
      _setError('Failed to submit open-ended response: $e');
      rethrow;
    }
  }

  /// Check if user has already responded to a poll
  Future<bool> hasUserResponded(String pollId, String userId) async {
    _clearError();

    try {
      return await _pollService.hasUserResponded(pollId, userId);
    } catch (e) {
      _setError('Failed to check user response: $e');
      rethrow;
    }
  }

  /// Get user's response to a poll
  Future<PollResponse?> getUserResponse(String pollId, String userId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _pollService.getUserResponse(pollId, userId);
      _setLoading(false);
      return response;
    } catch (e) {
      _setError('Failed to get user response: $e');
      rethrow;
    }
  }

  /// Get all responses for a poll
  Future<List<PollResponse>> getPollResponses(String pollId) async {
    _setLoading(true);
    _clearError();

    try {
      final responses = await _pollService.getPollResponses(pollId);
      _setLoading(false);
      return responses;
    } catch (e) {
      _setError('Failed to get poll responses: $e');
      rethrow;
    }
  }

  /// Close a poll
  Future<void> closePoll(String pollId) async {
    _setLoading(true);
    _clearError();

    try {
      await _pollService.closePoll(pollId);

      if (_currentPoll?.id == pollId) {
        _currentPoll = _currentPoll?.copyWith(isActive: false);
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to close poll: $e');
      rethrow;
    }
  }

  /// Reopen a poll
  Future<void> reopenPoll(String pollId) async {
    _setLoading(true);
    _clearError();

    try {
      await _pollService.reopenPoll(pollId);

      if (_currentPoll?.id == pollId) {
        _currentPoll = _currentPoll?.copyWith(isActive: true);
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Failed to reopen poll: $e');
      rethrow;
    }
  }

  /// Search polls by title or description
  Future<List<PollModel>> searchPolls(String query) async {
    _setLoading(true);
    _clearError();

    try {
      final results = await _pollService.searchPolls(query);
      _setLoading(false);
      return results;
    } catch (e) {
      _setError('Failed to search polls: $e');
      rethrow;
    }
  }

  /// Get polls by tags
  Future<void> initPollsByTags(List<String> tags) {
    _setLoading(true);

    // Cancel any existing subscription
    _publicPollsSubscription?.cancel();

    _publicPollsSubscription = _pollService
        .getPollsByTags(tags)
        .listen(
          (polls) {
            _publicPolls = polls;
            _setLoading(false);
            notifyListeners();
          },
          onError: (error) {
            _setError('Failed to load polls by tags: $error');
          },
        );

    return Future.value();
  }

  /// Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _clearError();
    }
    notifyListeners();
  }

  /// Helper method to set error state
  void _setError(String errorMessage) {
    _error = errorMessage;
    _isLoading = false;
    notifyListeners();
  }

  /// Helper method to clear error state
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// Set the current poll manually (without fetching)
  void setCurrentPoll(PollModel? poll) {
    _currentPoll = poll;
    notifyListeners();
  }

  @override
  void dispose() {
    // Cancel all stream subscriptions
    _publicPollsSubscription?.cancel();
    _institutionPollsSubscription?.cancel();
    _userPollsSubscription?.cancel();
    super.dispose();
  }
}
