import 'package:sdl2/sdl2.dart';

Future<int> main() async {
  if (mixInit(0) < 0) {
    print('Failed to init SDL: ${sdlGetError()}');
    return 1;
  }
  try {
    if (mixOpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 2048) < 0) {
      throw 'SDL_mixer could not initialize! SDL_mixer Error: ${mixGetError()}';
    }
    final wav = mixLoadWav('assets/data/file010.dat');
    if (wav.address == 0) {
      throw 'Cannot load file: ${mixGetError()}';
    }
    if (mixPlayChannel(-1, wav, 0) < 0) {
      throw 'Cannot play: ${mixGetError()}';
    }
    await Future.delayed(const Duration(seconds: 3));
    mixFreeChunk(wav);
    return 0;
  } catch (e) {
    print(e);
    return 1;
  } finally {
    mixCloseAudio();
    mixQuit();
  }
}
