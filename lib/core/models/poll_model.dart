import 'package:cloud_firestore/cloud_firestore.dart';

/// Poll model representing a poll in the application.
class PollModel {
  final String id;
  final String title;
  final String description;
  final String creatorId;
  final String creatorName;
  final String? creatorImageUrl;
  final String pollType; // public, anonymous, institutional
  final String? institutionId; // Only for institutional polls
  final List<PollOption> options;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool isActive;
  final int responseCount;
  final List<String>? tags;
  final Map<String, dynamic>? additionalData;

  PollModel({
    required this.id,
    required this.title,
    required this.description,
    required this.creatorId,
    required this.creatorName,
    required this.pollType,
    required this.options,
    required this.createdAt,
    required this.expiresAt,
    this.creatorImageUrl,
    this.institutionId,
    this.isActive = true,
    this.responseCount = 0,
    this.tags,
    this.additionalData,
  });

  /// Create a poll model from JSON data.
  factory PollModel.fromJson(Map<String, dynamic> json) {
    return PollModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      creatorId: json['creatorId'] as String,
      creatorName: json['creatorName'] as String,
      creatorImageUrl: json['creatorImageUrl'] as String?,
      pollType: json['pollType'] as String,
      institutionId: json['institutionId'] as String?,
      options:
          (json['options'] as List)
              .map(
                (option) => PollOption.fromJson(option as Map<String, dynamic>),
              )
              .toList(),
      createdAt:
          json['createdAt'] != null
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      expiresAt:
          json['expiresAt'] != null
              ? (json['expiresAt'] as Timestamp).toDate()
              : DateTime.now().add(const Duration(days: 7)),
      isActive: json['isActive'] as bool? ?? true,
      responseCount: json['responseCount'] as int? ?? 0,
      tags:
          json['tags'] != null ? List<String>.from(json['tags'] as List) : null,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  /// Convert poll model to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'creatorImageUrl': creatorImageUrl,
      'pollType': pollType,
      'institutionId': institutionId,
      'options': options.map((option) => option.toJson()).toList(),
      'createdAt': createdAt,
      'expiresAt': expiresAt,
      'isActive': isActive,
      'responseCount': responseCount,
      'tags': tags,
      'additionalData': additionalData,
    };
  }

  /// Create a copy of the poll model with updated fields.
  PollModel copyWith({
    String? title,
    String? description,
    String? pollType,
    String? institutionId,
    List<PollOption>? options,
    DateTime? expiresAt,
    bool? isActive,
    int? responseCount,
    List<String>? tags,
    Map<String, dynamic>? additionalData,
  }) {
    return PollModel(
      id: this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      creatorId: this.creatorId,
      creatorName: this.creatorName,
      creatorImageUrl: this.creatorImageUrl,
      pollType: pollType ?? this.pollType,
      institutionId: institutionId ?? this.institutionId,
      options: options ?? this.options,
      createdAt: this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
      responseCount: responseCount ?? this.responseCount,
      tags: tags ?? this.tags,
      additionalData: additionalData ?? this.additionalData,
    );
  }

  /// Check if poll is public.
  bool get isPublic => pollType == 'public';

  /// Check if poll is anonymous.
  bool get isAnonymous => pollType == 'anonymous';

  /// Check if poll is institutional.
  bool get isInstitutional => pollType == 'institutional';

  /// Check if poll has expired.
  bool get hasExpired => DateTime.now().isAfter(expiresAt);
}

/// Poll option representing an option in a poll.
class PollOption {
  final String id;
  final String text;
  final int count;

  PollOption({required this.id, required this.text, this.count = 0});

  /// Create a poll option from JSON data.
  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'] as String,
      text: json['text'] as String,
      count: json['count'] as int? ?? 0,
    );
  }

  /// Convert poll option to JSON.
  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text, 'count': count};
  }

  /// Create a copy of the poll option with updated fields.
  PollOption copyWith({String? text, int? count}) {
    return PollOption(
      id: this.id,
      text: text ?? this.text,
      count: count ?? this.count,
    );
  }
}

/// Poll response representing a user's response to a poll.
class PollResponse {
  final String id;
  final String pollId;
  final String userId;
  final String optionId;
  final DateTime createdAt;
  final Map<String, dynamic>? additionalData;

  PollResponse({
    required this.id,
    required this.pollId,
    required this.userId,
    required this.optionId,
    required this.createdAt,
    this.additionalData,
  });

  /// Create a poll response from JSON data.
  factory PollResponse.fromJson(Map<String, dynamic> json) {
    return PollResponse(
      id: json['id'] as String,
      pollId: json['pollId'] as String,
      userId: json['userId'] as String,
      optionId: json['optionId'] as String,
      createdAt:
          json['createdAt'] != null
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  /// Convert poll response to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pollId': pollId,
      'userId': userId,
      'optionId': optionId,
      'createdAt': createdAt,
      'additionalData': additionalData,
    };
  }
}

/// Base class for question configurations
abstract class QuestionConfig {
  Map<String, dynamic> toJson();
}

/// Single choice question configuration
class SingleChoiceConfig implements QuestionConfig {
  final bool allowOther;
  final bool randomizeOptions;

  SingleChoiceConfig({this.allowOther = false, this.randomizeOptions = false});

  factory SingleChoiceConfig.fromJson(Map<String, dynamic> json) {
    return SingleChoiceConfig(
      allowOther: json['allowOther'] as bool? ?? false,
      randomizeOptions: json['randomizeOptions'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {'allowOther': allowOther, 'randomizeOptions': randomizeOptions};
  }
}

/// Multiple choice question configuration
class MultipleChoiceConfig implements QuestionConfig {
  final bool allowOther;
  final bool randomizeOptions;
  final int? minSelections;
  final int? maxSelections;

  MultipleChoiceConfig({
    this.allowOther = false,
    this.randomizeOptions = false,
    this.minSelections,
    this.maxSelections,
  });

  factory MultipleChoiceConfig.fromJson(Map<String, dynamic> json) {
    return MultipleChoiceConfig(
      allowOther: json['allowOther'] as bool? ?? false,
      randomizeOptions: json['randomizeOptions'] as bool? ?? false,
      minSelections: json['minSelections'] as int?,
      maxSelections: json['maxSelections'] as int?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'allowOther': allowOther,
      'randomizeOptions': randomizeOptions,
      'minSelections': minSelections,
      'maxSelections': maxSelections,
    };
  }
}

/// Likert scale question configuration
class LikertScaleConfig implements QuestionConfig {
  final int minValue;
  final int maxValue;
  final String? minLabel;
  final String? maxLabel;
  final List<String>? labels; // Optional labels for each point on the scale

  LikertScaleConfig({
    this.minValue = 1,
    this.maxValue = 5,
    this.minLabel,
    this.maxLabel,
    this.labels,
  });

  factory LikertScaleConfig.fromJson(Map<String, dynamic> json) {
    return LikertScaleConfig(
      minValue: json['minValue'] as int? ?? 1,
      maxValue: json['maxValue'] as int? ?? 5,
      minLabel: json['minLabel'] as String?,
      maxLabel: json['maxLabel'] as String?,
      labels:
          json['labels'] != null
              ? List<String>.from(json['labels'] as List)
              : null,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'minValue': minValue,
      'maxValue': maxValue,
      'minLabel': minLabel,
      'maxLabel': maxLabel,
      'labels': labels,
    };
  }
}

/// Ranking question configuration
class RankingConfig implements QuestionConfig {
  final bool allowPartialRanking;
  final bool randomizeOptions;

  RankingConfig({
    this.allowPartialRanking = false,
    this.randomizeOptions = false,
  });

  factory RankingConfig.fromJson(Map<String, dynamic> json) {
    return RankingConfig(
      allowPartialRanking: json['allowPartialRanking'] as bool? ?? false,
      randomizeOptions: json['randomizeOptions'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'allowPartialRanking': allowPartialRanking,
      'randomizeOptions': randomizeOptions,
    };
  }
}

/// Open-ended question configuration
class OpenEndedConfig implements QuestionConfig {
  final int? maxLength;
  final bool multiline;
  final String? placeholder;

  OpenEndedConfig({this.maxLength, this.multiline = true, this.placeholder});

  factory OpenEndedConfig.fromJson(Map<String, dynamic> json) {
    return OpenEndedConfig(
      maxLength: json['maxLength'] as int?,
      multiline: json['multiline'] as bool? ?? true,
      placeholder: json['placeholder'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'maxLength': maxLength,
      'multiline': multiline,
      'placeholder': placeholder,
    };
  }
}

/// Factory to create appropriate question config based on type
class QuestionConfigFactory {
  static QuestionConfig fromJson(String type, Map<String, dynamic> json) {
    switch (type) {
      case 'single_choice':
        return SingleChoiceConfig.fromJson(json);
      case 'multiple_choice':
        return MultipleChoiceConfig.fromJson(json);
      case 'likert_scale':
        return LikertScaleConfig.fromJson(json);
      case 'ranking':
        return RankingConfig.fromJson(json);
      case 'open_ended':
        return OpenEndedConfig.fromJson(json);
      default:
        throw Exception('Unknown question type: $type');
    }
  }
}

/// Extended poll response for multiple choice questions
class MultipleChoicePollResponse extends PollResponse {
  final List<String> optionIds;

  MultipleChoicePollResponse({
    required String id,
    required String pollId,
    required String userId,
    required this.optionIds,
    required DateTime createdAt,
    Map<String, dynamic>? additionalData,
  }) : super(
         id: id,
         pollId: pollId,
         userId: userId,
         optionId: '', // Not used in multiple choice
         createdAt: createdAt,
         additionalData: additionalData,
       );

  factory MultipleChoicePollResponse.fromJson(Map<String, dynamic> json) {
    return MultipleChoicePollResponse(
      id: json['id'] as String,
      pollId: json['pollId'] as String,
      userId: json['userId'] as String,
      optionIds: List<String>.from(json['optionIds'] as List),
      createdAt:
          json['createdAt'] != null
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    baseJson.remove('optionId'); // Remove unused field
    baseJson['optionIds'] = optionIds;
    return baseJson;
  }
}

/// Extended poll response for likert scale questions
class LikertScalePollResponse extends PollResponse {
  final int value;

  LikertScalePollResponse({
    required String id,
    required String pollId,
    required String userId,
    required this.value,
    required DateTime createdAt,
    Map<String, dynamic>? additionalData,
  }) : super(
         id: id,
         pollId: pollId,
         userId: userId,
         optionId:
             value.toString(), // Store value as optionId for compatibility
         createdAt: createdAt,
         additionalData: additionalData,
       );

  factory LikertScalePollResponse.fromJson(Map<String, dynamic> json) {
    return LikertScalePollResponse(
      id: json['id'] as String,
      pollId: json['pollId'] as String,
      userId: json['userId'] as String,
      value: json['value'] as int,
      createdAt:
          json['createdAt'] != null
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    baseJson['value'] = value;
    return baseJson;
  }
}

/// Extended poll response for ranking questions
class RankingPollResponse extends PollResponse {
  final List<String> rankedOptionIds;

  RankingPollResponse({
    required String id,
    required String pollId,
    required String userId,
    required this.rankedOptionIds,
    required DateTime createdAt,
    Map<String, dynamic>? additionalData,
  }) : super(
         id: id,
         pollId: pollId,
         userId: userId,
         optionId: '', // Not used in ranking
         createdAt: createdAt,
         additionalData: additionalData,
       );

  factory RankingPollResponse.fromJson(Map<String, dynamic> json) {
    return RankingPollResponse(
      id: json['id'] as String,
      pollId: json['pollId'] as String,
      userId: json['userId'] as String,
      rankedOptionIds: List<String>.from(json['rankedOptionIds'] as List),
      createdAt:
          json['createdAt'] != null
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    baseJson.remove('optionId'); // Remove unused field
    baseJson['rankedOptionIds'] = rankedOptionIds;
    return baseJson;
  }
}

/// Extended poll response for open-ended questions
class OpenEndedPollResponse extends PollResponse {
  final String response;

  OpenEndedPollResponse({
    required String id,
    required String pollId,
    required String userId,
    required this.response,
    required DateTime createdAt,
    Map<String, dynamic>? additionalData,
  }) : super(
         id: id,
         pollId: pollId,
         userId: userId,
         optionId: '', // Not used in open-ended
         createdAt: createdAt,
         additionalData: additionalData,
       );

  factory OpenEndedPollResponse.fromJson(Map<String, dynamic> json) {
    return OpenEndedPollResponse(
      id: json['id'] as String,
      pollId: json['pollId'] as String,
      userId: json['userId'] as String,
      response: json['response'] as String,
      createdAt:
          json['createdAt'] != null
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    baseJson.remove('optionId'); // Remove unused field
    baseJson['response'] = response;
    return baseJson;
  }
}

/// Factory to create appropriate poll response based on question type
class PollResponseFactory {
  static PollResponse fromJson(String type, Map<String, dynamic> json) {
    switch (type) {
      case 'single_choice':
        return PollResponse.fromJson(json);
      case 'multiple_choice':
        return MultipleChoicePollResponse.fromJson(json);
      case 'likert_scale':
        return LikertScalePollResponse.fromJson(json);
      case 'ranking':
        return RankingPollResponse.fromJson(json);
      case 'open_ended':
        return OpenEndedPollResponse.fromJson(json);
      default:
        return PollResponse.fromJson(json);
    }
  }
}
