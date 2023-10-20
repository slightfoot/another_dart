import 'dart:io';
import 'dart:math' as math;
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:sdl2/sdl2.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;

class SoundManager {
  SoundManager();

  final _sounds = <int, Pointer<MixChunk>>{};
  final _musics = <int, Pointer<MixMusic>>{};
  final _volumes = <int, int>{};
  bool _initialized = false;
  bool _muted = false;

  void start() {
    if (_initialized) {
      return;
    }
    try {
      if (mixInit(MIX_INIT_OGG) < 0) {
        print('Failed to init mixer: ${mixGetError()}');
        return;
      }
      if (mixOpenAudio(44100, MIX_DEFAULT_FORMAT, 2, 2048) < 0) {
        print('Failed to open mixer: ${mixGetError()}');
        mixQuit();
        return;
      }
      mixAllocateChannels(4);
      _initialized = true;
    } catch (error, stackTrace) {
      print('$error\n$stackTrace');
    }
  }

  void stop() {
    if (_initialized) {
      mixCloseAudio();
      for (final chunk in _sounds.values) {
        mixFreeChunk(chunk);
      }
      for (final music in _musics.values) {
        mixFreeMusic(music);
      }
      mixQuit();
      _initialized = false;
    }
  }

  void reset() {
    if (!_initialized) {
      return;
    }
    for (int channel = 0; channel < 4; channel++) {
      mixHaltChannel(channel);
    }
    mixHaltMusic();
  }

  bool get muted => _muted;

  set muted(bool value) {
    if (!_initialized) {
      return;
    }
    _muted = value;
    for (int channel = 0; channel < 4; channel++) {
      mixVolume(channel, value ? 0 : (_volumes[channel] ?? MIX_MAX_VOLUME));
    }
    mixVolumeMusic(value ? 0 : MIX_MAX_VOLUME);
  }

  Future<Pointer<MixChunk>?> _getSound(int index) async {
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
    sound = mixLoadWavRw(sdlRwFromConstMem(ptr.cast(), data.buffer.lengthInBytes), 1);
    if (sound.address == 0) {
      malloc.free(ptr);
      print('Cannot load sound ($index): ${mixGetError()}');
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
      mixHaltChannel(channel);
      return;
    }
    final sound = await _getSound(index);
    if (sound != null) {
      if (mixPlayChannelTimed(channel, sound, 0, -1) >= 0) {
        final volumeGained = (MIX_MAX_VOLUME * 0.5 * (math.min(volume, 0x3F) / 0x40)).toInt();
        _volumes[channel] = volumeGained;
        if (!_muted) {
          mixVolume(channel, volumeGained);
        }
      } else {
        print('Cannot play sound ($index): ${mixGetError()}');
      }
    }
  }

  Future<Pointer<MixChunk>?> _getMusic(int index) async {
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
    sound = mixLoadWavRw(sdlRwFromConstMem(ptr.cast(), data.buffer.lengthInBytes), 1);
    if (sound.address == 0) {
      malloc.free(ptr);
      print('Cannot load sound ($index): ${mixGetError()}');
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
      music = mixLoadMusRw(sdlRwFromConstMem(ptr.cast(), data.buffer.lengthInBytes), 1);
      if (music.address == 0) {
        malloc.free(ptr);
        print('Cannot load music ($index): ${mixGetError()}');
        music = null;
      } else {
        _musics[index] = music;
      }
    }
    if (music != null) {
      if (mixPlayMusic(music, 0) >= 0) {
        mixVolumeMusic(MIX_MAX_VOLUME);
      } else {
        print('Cannot play music ($index): ${mixGetError()}');
      }
    }
  }
}
