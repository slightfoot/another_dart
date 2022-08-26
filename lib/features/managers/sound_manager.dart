import 'dart:ffi';

import 'package:sdl2/sdl2.dart';

class SoundManager {
  SoundManager();

  final _chunks = <int, Pointer<Mix_Chunk>?>{};
  bool _initialized = false;

  void start() {
    if (_initialized) {
      return;
    }
    if (Mix_Init(0) < 0) {
      print('Failed to init mixer: ${Mix_GetError()}');
      return;
    }
    if (Mix_OpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 2048) < 0) {
      print('Failed to open mixer: ${Mix_GetError()}');
      Mix_Quit();
      return;
    }
    Mix_AllocateChannels(4);
    _initialized = true;
  }

  void stop() {
    if (_initialized) {
      Mix_CloseAudio();
      for (final chunk in _chunks.values) {
        Mix_FreeChunk(chunk);
      }
      Mix_Quit();
      _initialized = false;
    }
  }

  void playSound(int index, int freq, int volume, int channel) {
    if (!_initialized) {
      return;
    }
    final chunk = _chunks.putIfAbsent(index, () {
      final name = 'file${index.toString().padLeft(3, '0')}.dat';
      return Mix_LoadWAV('assets/data/$name');
    });
    if (chunk != null) {
      if (Mix_PlayChannel(channel, chunk, 0) < 0) {
        print('Cannot play: ${Mix_GetError()}');
      }
    }
  }

  void playMusic(int index, int delay, int position) {
    //
  }
}
