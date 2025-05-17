import 'package:get_it/get_it.dart';
import 'package:music_sheet_pro/data/repositories/music_repository_impl.dart';
import 'package:music_sheet_pro/domain/repositories/music_repository.dart';

final GetIt serviceLocator = GetIt.instance;

void setupServiceLocator() {
  // Repositórios
  serviceLocator.registerLazySingleton<MusicRepository>(
    () => MusicRepositoryImpl(),
  );
  
  // Adicione mais serviços aqui conforme necessário
}