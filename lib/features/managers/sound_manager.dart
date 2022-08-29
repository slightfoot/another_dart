import 'dart:io';
import 'dart:math' as math;
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:sdl2/sdl2.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;

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
    try {
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
    } catch (error, stackTrace) {
      print('$error\n$stackTrace');
    }
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

  Future<Pointer<Mix_Chunk>?> _getSound(int index) async {
    var sound = _sounds[index];
    if (sound != null) {
      return sound;
    }
    final file = 'assets/data/file${index.toString().padLeft(3, '0')}';
    late ByteData data;
    try {
      data = await rootBundle.load('${file}b.dat');
    } catch (e) {
      data = await rootBundle.load('$file.dat');
    }
    final ptr = malloc<Uint8>(data.buffer.lengthInBytes);
    ptr.asTypedList(data.buffer.lengthInBytes).setAll(0, data.buffer.asUint8List());
    sound = Mix_LoadWAV_RW(SDL_RWFromConstMem(ptr.cast(), data.buffer.lengthInBytes), 1);
    if ((sound?.address ?? 0) == 0) {
      malloc.free(ptr);
      print('Cannot load sound ($index): ${Mix_GetError()}');
      return null;
    }
    _sounds[index] = sound;
    return sound;
  }

  Future<void> playSound(int index, int freq, int volume, int channel) async {
    if (!_initialized || _muted) {
      return;
    }
    if (volume == 0) {
      Mix_HaltChannel(channel);
      return;
    }
    final sound = await _getSound(index);
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

  Future<Pointer<Mix_Chunk>?> _getMusic(int index) async {
    var sound = _sounds[index];
    if (sound != null) {
      return sound;
    }
    final file = 'assets/data/file${index.toString().padLeft(3, '0')}';
    late ByteData data;
    try {
      data = await rootBundle.load('${file}b.dat');
    } catch (e) {
      data = await rootBundle.load('$file.dat');
    }
    final ptr = malloc<Uint8>(data.buffer.lengthInBytes);
    ptr.asTypedList(data.buffer.lengthInBytes).setAll(0, data.buffer.asUint8List());
    sound = Mix_LoadWAV_RW(SDL_RWFromConstMem(ptr.cast(), data.buffer.lengthInBytes), 1);
    if ((sound?.address ?? 0) == 0) {
      malloc.free(ptr);
      print('Cannot load sound ($index): ${Mix_GetError()}');
      return null;
    }
    _sounds[index] = sound;
    return sound;
  }

  Future<void> playMusic(int index, int delay, int position) async {
    if (!_initialized || _muted) {
      return;
    }
    if (index != 0) {
      return;
    }
    var music = _musics[index];
    if (music == null) {
      final data = await rootBundle.load('assets/data/intro.ogg');
      final ptr = malloc<Uint8>(data.buffer.lengthInBytes);
      ptr.asTypedList(data.buffer.lengthInBytes).setAll(0, data.buffer.asUint8List());
      music = Mix_LoadMUS_RW(SDL_RWFromConstMem(ptr.cast(), data.buffer.lengthInBytes), 1);
      if ((music?.address ?? 0) == 0) {
        malloc.free(ptr);
        print('Cannot load music ($index): ${Mix_GetError()}');
        music = null;
      } else {
        _musics[index] = music;
      }
    }
    if (Mix_PlayMusic(music, 0) >= 0) {
      Mix_VolumeMusic(MIX_MAX_VOLUME);
    } else {
      print('Cannot play music ($index): ${Mix_GetError()}');
    }
  }
}
