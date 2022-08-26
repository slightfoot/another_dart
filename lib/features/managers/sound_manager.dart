import 'dart:math' as math;
import 'dart:ffi';

import 'package:sdl2/sdl2.dart';

class SoundManager {
  SoundManager();

  final _sounds = <int, Pointer<Mix_Chunk>?>{};
  final _musics = <int, Pointer<Mix_Music>?>{};
  bool _initialized = false;

  void start() {
    if (_initialized) {
      return;
    }
    if (Mix_Init(MIX_INIT_OGG) < 0) {
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
      for (final chunk in _sounds.values) {
        Mix_FreeChunk(chunk);
      }
      for (final music in _musics.values) {
        Mix_FreeMusic(music);
      }
      Mix_Quit();
      _initialized = false;
    }
  }

  Pointer<Mix_Chunk>? _getSound(int index) {
    return _sounds.putIfAbsent(index, () {
      final name = 'file${index.toString().padLeft(3, '0')}.dat';
      final value = Mix_LoadWAV('assets/data/$name');
      if ((value?.address ?? 0) == 0) {
        print('Cannot load sound: ${Mix_GetError()}');
        return null;
      }
      return value;
    });
  }

  void playSound(int index, int freq, int volume, int channel) {
    if (!_initialized) {
      return;
    }
    if (volume == 0) {
      Mix_HaltChannel(channel);
      return;
    }
    final sound = _getSound(index);
    if (sound != null) {
      if (Mix_PlayChannel(channel, sound, 0) >= 0) {
        Mix_Volume(channel, (MIX_MAX_VOLUME * 0.5 * (math.min(volume, 0x3F) / 0x40)).toInt());
      } else {
        print('Cannot play sound: ${Mix_GetError()}');
      }
    }
  }

  void playMusic(int index, int delay, int position) {
    if (!_initialized) {
      return;
    }
    if (index != 0) {
      return;
    }
    final music = _musics.putIfAbsent(index, () {
      final value = Mix_LoadMUS('assets/data/intro.ogg');
      if ((value?.address ?? 0) == 0) {
        print('Cannot load music: ${Mix_GetError()}');
        return null;
      }
      return value;
    });
    if (music == null || music.address == 0) {
      return;
    }
    if (Mix_PlayMusic(music, 0) >= 0) {
      Mix_VolumeMusic(MIX_MAX_VOLUME);
    } else {
      print('Cannot play music: ${Mix_GetError()}');
    }
  }
}
