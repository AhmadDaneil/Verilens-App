// lib/cubits/history/history_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'history_state.dart';
import 'package:verilens_app/services/database_service.dart';

class HistoryCubit extends Cubit<HistoryState> {
  final DatabaseService _databaseService;

  HistoryCubit({required DatabaseService databaseService})
      : _databaseService = databaseService,
        super(HistoryInitial());

  Future<void> loadHistory() async {
    emit(HistoryLoading());
    try {
      final results = await _databaseService.getAllScans();
      if (results.isEmpty) {
        emit(HistoryEmpty());
      } else {
        emit(HistoryLoaded(results: results));
      }
    } catch (e) {
      emit(const HistoryError(message: 'Failed to load history.'));
    }
  }

  Future<void> clearHistory() async {
    await _databaseService.clearAllScans();
    emit(HistoryEmpty());
  }

  // id is a String UUID — no casting needed
  Future<void> deleteScan(String id) async {
    await _databaseService.deleteScan(id);
    await loadHistory();
  }
}