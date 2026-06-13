import 'package:equatable/equatable.dart';
import 'package:verilens_app/models/scan_result.dart';

abstract class HistoryState extends Equatable{

  const HistoryState();
  @override
  List<Object?> get props => [];
}

class HistoryInitial extends HistoryState{}

class HistoryLoading extends HistoryState{}

class HistoryLoaded extends HistoryState{
  final List<ScanResult> results;
  const HistoryLoaded({required this.results});

  @override
  List<Object?> get props => [results];
}

class HistoryEmpty extends HistoryState{}

class HistoryError extends HistoryState{
  final String message;
  const HistoryError({required this.message});

  @override
  List<Object?> get props => [message];
}