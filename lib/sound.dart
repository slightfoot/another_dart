import 'package:sdl2/sdl2.dart';

Future<int> main() async {
  if (Mix_Init(0) < 0) {
    print('Failed to init SDL: ${SDL_GetError()}');
    return 1;
  }
  try {
    if (Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 2048) < 0) {
      throw 'SDL_mixer could not initialize! SDL_mixer Error: ${Mix_GetError()}';
    }
    final wav = Mix_LoadWAV('assets/data/file010.dat');
    if (wav == null) {
      throw 'Cannot load file: ${Mix_GetError()}';
    }
    if (Mix_PlayChannel(-1, wav, 0) < 0) {
      throw 'Cannot play: ${Mix_GetError()}';
    }
    await Future.delayed(const Duration(seconds: 3));
    Mix_FreeChunk(wav);
    return 0;
  } catch (e) {
    print(e);
    return 1;
  } finally {
    Mix_CloseAudio();
    Mix_Quit();
  }
}
