import 'package:get_it/get_it.dart';
import 'package:music_sheet_pro/data/repositories/music_repository_impl.dart';
import 'package:music_sheet_pro/data/repositories/setlist_repository_impl.dart';
import 'package:music_sheet_pro/domain/repositories/music_repository.dart';
import 'package:music_sheet_pro/domain/repositories/setlist_repository.dart';
import 'package:music_sheet_pro/data/repositories/annotation_repository_impl.dart';
import 'package:music_sheet_pro/domain/repositories/annotation_repository.dart';
import 'package:music_sheet_pro/core/services/file_service.dart';

final GetIt serviceLocator = GetIt.instance;

void setupServiceLocator() {
  // Repositórios
  serviceLocator.registerLazySingleton<MusicRepository>(
    () => MusicRepositoryImpl(),
  );

  serviceLocator.registerLazySingleton<SetlistRepository>(
    () => SetlistRepositoryImpl(),
  );

  serviceLocator.registerLazySingleton<AnnotationRepository>(
    () => AnnotationRepositoryImpl(),
  );

  serviceLocator.registerLazySingleton<FileService>(
    () => FileService(),
  );
}
