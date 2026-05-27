import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/swipe_remote_datasource.dart';
import '../../data/repositories/swipe_repository_impl.dart';
import '../../domain/repositories/swipe_repository.dart';
import '../../domain/usecases/send_swipe_usecase.dart';

final swipeRemoteDataSourceProvider = Provider<SwipeRemoteDataSource>((ref) {
  return SwipeRemoteDataSource();
});

final swipeRepositoryProvider = Provider<SwipeRepository>((ref) {
  return SwipeRepositoryImpl(
    remoteDataSource: ref.watch(swipeRemoteDataSourceProvider),
  );
});

final sendSwipeUseCaseProvider = Provider<SendSwipeUseCase>((ref) {
  return SendSwipeUseCase(ref.watch(swipeRepositoryProvider));
});
