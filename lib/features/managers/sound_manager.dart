import 'dart:io';
import 'dart:math' as math;
import 'dart:ffi';

import 'package:sdl2/sdl2.dart';

class SoundManager {
  SoundManager();

  final _sounds = <int, Pointer<Mix_Chunk>?>{};
  final _musics = <int, Pointer<Mix_Music>?>{};
  final _volumes = <int, int>{};
  bool _initialized = false;
  bool _muted = false;

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

  void reset() {
    if (!_initialized) {
      return;
    }
    for (int channel = 0; channel < 4; channel++) {
      Mix_HaltChannel(channel);
    }
    Mix_HaltMusic();
  }

  bool get muted => _muted;

  set muted(bool value) {
    if (!_initialized) {
      return;
    }
    _muted = value;
    for (int channel = 0; channel < 4; channel++) {
      Mix_Volume(channel, value ? 0 : (_volumes[channel] ?? MIX_MAX_VOLUME));
    }
    Mix_VolumeMusic(value ? 0 : MIX_MAX_VOLUME);
  }

  Pointer<Mix_Chunk>? _getSound(int index) {
    return _sounds.putIfAbsent(index, () {
      final file = 'assets/data/file${index.toString().padLeft(3, '0')}';
      String filePath = '${file}b.dat';
      if (!File(filePath).existsSync()) {
        filePath = '$file.dat';
      }
      final value = Mix_LoadWAV(filePath);
      if ((value?.address ?? 0) == 0) {
        print('Cannot load sound ($index): ${Mix_GetError()}');
        return null;
      }
      return value;
    });
  }

  void playSound(int index, int freq, int volume, int channel) {
    if (!_initialized || _muted) {
      return;
    }
    if (volume == 0) {
      Mix_HaltChannel(channel);
      return;
    }
    final sound = _getSound(index);
    if (sound != null) {
      if (Mix_PlayChannel(channel, sound, 0) >= 0) {
        final mixVolume = (MIX_MAX_VOLUME * 0.5 * (math.min(volume, 0x3F) / 0x40)).toInt();
        _volumes[channel] = mixVolume;
        if (!_muted) {
          Mix_Volume(channel, mixVolume);
        }
      } else {
        print('Cannot play sound ($index): ${Mix_GetError()}');
      }
    }
  }

  void playMusic(int index, int delay, int position) {
    if (!_initialized || _muted) {
      return;
    }
    if (index != 0) {
      return;
    }
    final music = _musics.putIfAbsent(index, () {
      final value = Mix_LoadMUS('assets/data/intro.ogg');
      if ((value?.address ?? 0) == 0) {
        print('Cannot load music ($index): ${Mix_GetError()}');
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
      print('Cannot play music ($index): ${Mix_GetError()}');
    }
  }
}
