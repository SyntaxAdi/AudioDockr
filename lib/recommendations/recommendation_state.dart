class RecommendationState {
  const RecommendationState({
    this.active = false,
    this.isFetching = false,
    this.errorMessage,
  });

  final bool active;
  final bool isFetching;
  final String? errorMessage;

  RecommendationState copyWith({
    bool? active,
    bool? isFetching,
    Object? errorMessage = _recommendationStateNoChange,
  }) {
    return RecommendationState(
      active: active ?? this.active,
      isFetching: isFetching ?? this.isFetching,
      errorMessage: identical(errorMessage, _recommendationStateNoChange)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _recommendationStateNoChange = Object();
