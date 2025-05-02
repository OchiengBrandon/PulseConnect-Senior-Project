import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pulse_connect_app/core/models/poll_model.dart';
import 'package:uuid/uuid.dart';

/// Service to manage polls in the application
class PollService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  /// Collection reference for polls
  CollectionReference get _pollsCollection => _firestore.collection('polls');

  /// Collection reference for poll responses
  CollectionReference get _responsesCollection =>
      _firestore.collection('poll_responses');

  /// Stream of all active public polls
  Stream<List<PollModel>> getPublicPolls() {
    return _pollsCollection
        .where('pollType', isEqualTo: 'public')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => PollModel.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList();
        });
  }

  /// Stream of active polls for a specific institution
  Stream<List<PollModel>> getInstitutionPolls(String institutionId) {
    return _pollsCollection
        .where('pollType', isEqualTo: 'institutional')
        .where('institutionId', isEqualTo: institutionId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => PollModel.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList();
        });
  }

  /// Stream of polls created by a specific user
  Stream<List<PollModel>> getUserPolls(String userId) {
    return _pollsCollection
        .where('creatorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => PollModel.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList();
        });
  }

  /// Get a specific poll by ID
  Future<PollModel?> getPoll(String pollId) async {
    final doc = await _pollsCollection.doc(pollId).get();
    if (doc.exists) {
      return PollModel.fromJson(doc.data() as Map<String, dynamic>);
    }
    return null;
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
    String? questionType = 'single_choice', // Default to single choice
    Map<String, dynamic>? additionalData,
  }) async {
    // Generate a new ID for the poll
    final pollId = _uuid.v4();

    // Ensure poll has valid additional data
    final pollAdditionalData = {
      'questionType': questionType,
      ...?additionalData,
    };

    // Create the poll model
    final poll = PollModel(
      id: pollId,
      title: title,
      description: description,
      creatorId: creatorId,
      creatorName: creatorName,
      creatorImageUrl: creatorImageUrl,
      pollType: pollType,
      institutionId: institutionId,
      options: options,
      createdAt: DateTime.now(),
      expiresAt: expiresAt,
      isActive: true,
      responseCount: 0,
      tags: tags,
      additionalData: pollAdditionalData,
    );

    // Convert DateTime to Timestamp for Firestore
    final pollData = poll.toJson();
    pollData['createdAt'] = Timestamp.fromDate(poll.createdAt);
    pollData['expiresAt'] = Timestamp.fromDate(poll.expiresAt);

    // Save to Firestore
    await _pollsCollection.doc(pollId).set(pollData);

    return poll;
  }

  /// Update an existing poll
  Future<PollModel> updatePoll(PollModel poll) async {
    final pollData = poll.toJson();
    pollData['createdAt'] = Timestamp.fromDate(poll.createdAt);
    pollData['expiresAt'] = Timestamp.fromDate(poll.expiresAt);

    await _pollsCollection.doc(poll.id).update(pollData);
    return poll;
  }

  /// Delete a poll
  Future<void> deletePoll(String pollId) async {
    // Delete all responses for this poll first
    final responsesSnapshot =
        await _responsesCollection.where('pollId', isEqualTo: pollId).get();

    final batch = _firestore.batch();

    for (var doc in responsesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete the poll document
    batch.delete(_pollsCollection.doc(pollId));

    await batch.commit();
  }

  /// Submit a response to a poll
  Future<PollResponse> submitPollResponse({
    required String pollId,
    required String userId,
    required String optionId,
    Map<String, dynamic>? additionalData,
  }) async {
    // Start a transaction
    return _firestore.runTransaction<PollResponse>((transaction) async {
      // Get the poll document
      final pollDoc = await transaction.get(_pollsCollection.doc(pollId));

      if (!pollDoc.exists) {
        throw Exception('Poll not found');
      }

      final pollData = pollDoc.data() as Map<String, dynamic>;
      final poll = PollModel.fromJson(pollData);

      // Check if poll is active
      if (!poll.isActive || poll.hasExpired) {
        throw Exception('Poll is no longer active');
      }

      // Check if user has already responded (for non-anonymous polls)
      if (poll.pollType != 'anonymous') {
        final existingResponse =
            await _responsesCollection
                .where('pollId', isEqualTo: pollId)
                .where('userId', isEqualTo: userId)
                .get();

        if (existingResponse.docs.isNotEmpty) {
          throw Exception('User has already responded to this poll');
        }
      }

      // Generate a new ID for the response
      final responseId = _uuid.v4();

      // Create the response model
      final response = PollResponse(
        id: responseId,
        pollId: pollId,
        userId: userId,
        optionId: optionId,
        createdAt: DateTime.now(),
        additionalData: additionalData,
      );

      // Convert DateTime to Timestamp for Firestore
      final responseData = response.toJson();
      responseData['createdAt'] = Timestamp.fromDate(response.createdAt);

      // Find the option in the poll and increase its count
      final updatedOptions = List<PollOption>.from(poll.options);
      final optionIndex = updatedOptions.indexWhere((o) => o.id == optionId);

      if (optionIndex < 0) {
        throw Exception('Invalid option ID');
      }

      updatedOptions[optionIndex] = updatedOptions[optionIndex].copyWith(
        count: updatedOptions[optionIndex].count + 1,
      );

      // Update poll with new option counts and response count
      transaction.update(_pollsCollection.doc(pollId), {
        'options': updatedOptions.map((o) => o.toJson()).toList(),
        'responseCount': FieldValue.increment(1),
      });

      // Save the response
      transaction.set(_responsesCollection.doc(responseId), responseData);

      return response;
    });
  }

  /// Check if a user has responded to a poll
  Future<bool> hasUserResponded(String pollId, String userId) async {
    final response =
        await _responsesCollection
            .where('pollId', isEqualTo: pollId)
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();

    return response.docs.isNotEmpty;
  }

  /// Get all responses for a poll
  Future<List<PollResponse>> getPollResponses(String pollId) async {
    final responseSnapshot =
        await _responsesCollection.where('pollId', isEqualTo: pollId).get();

    return responseSnapshot.docs
        .map((doc) => PollResponse.fromJson(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Get a specific user's response to a poll
  Future<PollResponse?> getUserResponse(String pollId, String userId) async {
    final responseSnapshot =
        await _responsesCollection
            .where('pollId', isEqualTo: pollId)
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();

    if (responseSnapshot.docs.isEmpty) {
      return null;
    }

    return PollResponse.fromJson(
      responseSnapshot.docs.first.data() as Map<String, dynamic>,
    );
  }

  /// Close a poll (mark as inactive)
  Future<void> closePoll(String pollId) async {
    await _pollsCollection.doc(pollId).update({'isActive': false});
  }

  /// Reopen a poll (mark as active)
  Future<void> reopenPoll(String pollId) async {
    await _pollsCollection.doc(pollId).update({'isActive': true});
  }

  /// Create a poll with multiple question types (single choice, multiple choice, etc.)
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
    required String
    questionType, // 'single_choice', 'multiple_choice', 'likert_scale', 'ranking', 'open_ended'
    Map<String, dynamic>?
    questionConfig, // Configuration specific to question type
    List<String>? tags,
  }) async {
    // Validate question type
    final validTypes = [
      'single_choice',
      'multiple_choice',
      'likert_scale',
      'ranking',
      'open_ended',
    ];

    if (!validTypes.contains(questionType)) {
      throw Exception('Invalid question type: $questionType');
    }

    // Prepare additional data with question type and config
    final additionalData = {
      'questionType': questionType,
      'questionConfig': questionConfig ?? {},
    };

    // Create poll with the question type and config
    return createPoll(
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
  }

  /// Get polls by tags
  Stream<List<PollModel>> getPollsByTags(List<String> tags) {
    return _pollsCollection
        .where('tags', arrayContainsAny: tags)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => PollModel.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList();
        });
  }

  /// Search polls by title or description
  Future<List<PollModel>> searchPolls(String query) async {
    // Simple search implementation - in a real app, consider using Algolia or another search service
    final queryLower = query.toLowerCase();

    final snapshot =
        await _pollsCollection.where('isActive', isEqualTo: true).get();

    return snapshot.docs
        .map((doc) => PollModel.fromJson(doc.data() as Map<String, dynamic>))
        .where((poll) {
          return poll.title.toLowerCase().contains(queryLower) ||
              poll.description.toLowerCase().contains(queryLower);
        })
        .toList();
  }
}
