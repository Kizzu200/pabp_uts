import '../models/schedule_model.dart';

class SchedulesState {
  const SchedulesState({
    required this.items,
    required this.isLoading,
    this.errorMessage,
  });

  const SchedulesState.initial()
      : items = const [],
        isLoading = false,
        errorMessage = null;

  final List<ScheduleModel> items;
  final bool isLoading;
  final String? errorMessage;

  SchedulesState copyWith({
    List<ScheduleModel>? items,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SchedulesState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
