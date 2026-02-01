package rsdk.audio;

import haxe.io.Bytes;
import lime.media.AudioBuffer;
import lime.media.AudioSource;
import lime.utils.UInt8Array;
import rsdk.core.Reader;
import rsdk.core.Reader.FileInfo;
import rsdk.core.RetroString;
import rsdk.core.Debug;
import rsdk.audio.Vorbis;

enum abstract MusicStatuses(Int) to Int {
    var MUSIC_STOPPED = 0;
    var MUSIC_PLAYING = 1;
    var MUSIC_PAUSED = 2;
    var MUSIC_LOADING = 3;
    var MUSIC_READY = 4;
}

class TrackInfo {
    public var fileName:Array<Int> = [for (i in 0...0x40) 0];
    public var trackLoop:Bool = false;

    public function new() {}
}

class SFXInfo {
    public var name:Array<Int> = [for (i in 0...0x40) 0];
    public var buffer:AudioBuffer = null;
    public var length:Int = 0;
    public var loaded:Bool = false;

    public function new() {}
}

class ChannelInfo {
    public var sampleLength:Int = 0;
    public var sfxID:Int = -1;
    public var loopSFX:Int = 0;
    public var pan:Float = 0;
    public var source:AudioSource = null;

    public function new() {}
}

class Audio {
    public static inline var TRACK_COUNT:Int = 0x10;
    public static inline var SFX_COUNT:Int = 0x100;
    public static inline var CHANNEL_COUNT:Int = 0x4;
    public static inline var MAX_VOLUME:Int = 100;

    public static var noGlobalSFX:Int = 0;
    public static var noStageSFX:Int = 0;
    public static var musicVolume:Int = MAX_VOLUME;
    public static var currentMusicTrack:Int = -1;
    public static var sfxVolume:Int = MAX_VOLUME;
    public static var bgmVolume:Int = MAX_VOLUME;
    public static var audioEnabled:Bool = true;
    public static var nextChannelPos:Int = 0;
    public static var musicEnabled:Bool = true;
    public static var musicStatus:Int = MUSIC_STOPPED;

    public static var musicTracks:Array<TrackInfo> = [for (i in 0...TRACK_COUNT) new TrackInfo()];
    public static var sfxList:Array<SFXInfo> = [for (i in 0...SFX_COUNT) new SFXInfo()];
    public static var sfxChannels:Array<ChannelInfo> = [for (i in 0...CHANNEL_COUNT) new ChannelInfo()];

    public static var musicBuffer:AudioBuffer = null;
    public static var musicSource:AudioSource = null;
    public static var trackLoop:Bool = false;

    public static function initSoundDevice():Int {
        stopAllSfx();
        loadGlobalSfx();
        audioEnabled = true;
        return 1;
    }

    public static function loadGlobalSfx():Void {
        var info = new FileInfo();
        var infoStore = new FileInfo();
        var strBuffer:Array<Int> = [for (i in 0...0x100) 0];
        var fileBuffer:Int = 0;

        if (Reader.loadFile("Data/Game/GameConfig.bin", info)) {
            fileBuffer = Reader.fileReadByte();
            for (i in 0...fileBuffer) Reader.fileReadByte();
            fileBuffer = Reader.fileReadByte();
            for (i in 0...fileBuffer) Reader.fileReadByte();
            fileBuffer = Reader.fileReadByte();
            for (i in 0...fileBuffer) Reader.fileReadByte();

            var scriptCount = Reader.fileReadByte();
            for (s in 0...scriptCount) {
                fileBuffer = Reader.fileReadByte();
                for (i in 0...fileBuffer) Reader.fileReadByte();
            }

            var varCnt = Reader.fileReadByte();
            for (v in 0...varCnt) {
                fileBuffer = Reader.fileReadByte();
                for (i in 0...fileBuffer) Reader.fileReadByte();
                Reader.fileReadByte();
                Reader.fileReadByte();
                Reader.fileReadByte();
                Reader.fileReadByte();
            }

            fileBuffer = Reader.fileReadByte();
            noGlobalSFX = fileBuffer;
            for (s in 0...noGlobalSFX) {
                fileBuffer = Reader.fileReadByte();
                for (i in 0...fileBuffer) strBuffer[i] = Reader.fileReadByte();
                strBuffer[fileBuffer] = 0;
                Reader.getFileInfo(infoStore);
                loadSfx(RetroString.arrayToString(strBuffer), s);
                Reader.setFileInfo(infoStore);
            }

            Reader.closeFile();
        }

        nextChannelPos = 0;
        for (i in 0...CHANNEL_COUNT) sfxChannels[i].sfxID = -1;
    }

    public static function setMusicTrack(filePath:String, trackID:Int, loop:Bool):Void {
        if (trackID < TRACK_COUNT) {
            var dest = musicTracks[trackID].fileName;
            RetroString.strCopy(dest, "Data/Music/");
            RetroString.strAdd(dest, filePath);
            musicTracks[trackID].trackLoop = loop;
        }
    }

    static function decodeOggFromBytes(bytes:Bytes):AudioBuffer {
        var result = Vorbis.decodeFromBytes(bytes);
        if (!result.success) {
            Debug.printLog("OGG decode failed, error code: " + result.errorCode + ", data size: " + bytes.length);
            return null;
        }

        var pcmData = new UInt8Array(result.pcmSize);
        for (i in 0...result.pcmSize) {
            pcmData[i] = result.pcmData[i];
        }

        untyped __cpp__("free({0})", result.pcmData);

        var buffer = new AudioBuffer();
        buffer.channels = result.channels;
        buffer.sampleRate = result.sampleRate;
        buffer.bitsPerSample = 16;
        buffer.data = pcmData;

        Debug.printLog("Decoded OGG: " + result.channels + "ch, " + result.sampleRate + "Hz, " + result.pcmSize + " bytes");
        return buffer;
    }

    public static function playMusic(track:Int):Bool {
        if (!audioEnabled)
            return false;

        if (track < 0 || track >= TRACK_COUNT) {
            stopMusic();
            return false;
        }

        stopMusic();

        var trackInfo = musicTracks[track];
        if (trackInfo.fileName[0] == 0)
            return false;

        var path = RetroString.arrayToString(trackInfo.fileName);
        var bytes = Reader.loadFileAsBytesRaw(path);
        if (bytes == null) {
            Debug.printLog("Failed to load music file: " + path);
            return false;
        }

        musicBuffer = decodeOggFromBytes(bytes);
        if (musicBuffer == null) {
            Debug.printLog("Failed to decode OGG: " + path);
            return false;
        }

        musicSource = new AudioSource(musicBuffer);
        if (musicSource == null) {
            Debug.printLog("Failed to create AudioSource");
            return false;
        }

        if (musicVolume == 0) musicVolume = MAX_VOLUME;
        if (bgmVolume == 0) bgmVolume = MAX_VOLUME;
        musicSource.gain = (bgmVolume * musicVolume) / (MAX_VOLUME * MAX_VOLUME);
        trackLoop = trackInfo.trackLoop;

        musicSource.onComplete.add(onMusicComplete);

        musicSource.play();
        musicStatus = MUSIC_PLAYING;
        currentMusicTrack = track;
        return true;
    }

    static function onMusicComplete():Void {
        if (trackLoop && musicSource != null && musicStatus == MUSIC_PLAYING) {
            musicSource.currentTime = 0;
            musicSource.play();
        } else {
            musicStatus = MUSIC_STOPPED;
        }
    }

    public static function stopMusic():Void {
        if (musicSource != null) {
            musicSource.onComplete.remove(onMusicComplete);
            musicSource.stop();
            musicSource.dispose();
            musicSource = null;
        }
        musicBuffer = null;
        musicStatus = MUSIC_STOPPED;
        currentMusicTrack = -1;
    }

    public static function loadSfx(filePath:String, sfxID:Int):Void {
        if (!audioEnabled || sfxID >= SFX_COUNT)
            return;

        var fullPath:Array<Int> = [for (i in 0...0x80) 0];
        RetroString.strCopy(fullPath, "Data/SoundFX/");
        RetroString.strAdd(fullPath, filePath);

        var bytes = Reader.loadFileAsBytesRaw(RetroString.arrayToString(fullPath));
        if (bytes == null) {
            Debug.printLog("Failed to load SFX: " + RetroString.arrayToString(fullPath));
            return;
        }

        var buffer = decodeWavFromBytes(bytes);
        if (buffer != null) {
            sfxList[sfxID].buffer = buffer;
            sfxList[sfxID].length = buffer.data.length;
            sfxList[sfxID].loaded = true;
            for (i in 0...filePath.length) sfxList[sfxID].name[i] = filePath.charCodeAt(i);
            sfxList[sfxID].name[filePath.length] = 0;
        } else {
            Debug.printLog("Failed to decode SFX: " + filePath);
        }
    }

    static function decodeWavFromBytes(bytes:Bytes):AudioBuffer {
        if (bytes.length < 44) return null;

        if (bytes.get(0) != 'R'.code || bytes.get(1) != 'I'.code || 
            bytes.get(2) != 'F'.code || bytes.get(3) != 'F'.code) {
            return null;
        }

        var channels = bytes.get(22) | (bytes.get(23) << 8);
        var sampleRate = bytes.get(24) | (bytes.get(25) << 8) | (bytes.get(26) << 16) | (bytes.get(27) << 24);
        var bitsPerSample = bytes.get(34) | (bytes.get(35) << 8);

        var dataOffset = 44;
        for (i in 36...bytes.length - 4) {
            if (bytes.get(i) == 'd'.code && bytes.get(i+1) == 'a'.code && 
                bytes.get(i+2) == 't'.code && bytes.get(i+3) == 'a'.code) {
                dataOffset = i + 8;
                break;
            }
        }

        var dataSize = bytes.length - dataOffset;
        var pcmData = new UInt8Array(dataSize);
        for (i in 0...dataSize) {
            pcmData[i] = bytes.get(dataOffset + i);
        }

        var buffer = new AudioBuffer();
        buffer.channels = channels;
        buffer.sampleRate = sampleRate;
        buffer.bitsPerSample = bitsPerSample;
        buffer.data = pcmData;

        return buffer;
    }

    public static function playSfx(sfx:Int, loop:Bool):Void {
        if (!audioEnabled || sfx < 0 || sfx >= SFX_COUNT)
            return;

        if (!sfxList[sfx].loaded || sfxList[sfx].buffer == null)
            return;

        var sfxChannelID = nextChannelPos;
        for (c in 0...CHANNEL_COUNT) {
            if (sfxChannels[c].sfxID == sfx) {
                sfxChannelID = c;
                break;
            }
        }

        if (sfxChannels[sfxChannelID].source != null) {
            sfxChannels[sfxChannelID].source.onComplete.removeAll();
            sfxChannels[sfxChannelID].source.stop();
            sfxChannels[sfxChannelID].source.dispose();
        }

        var source = new AudioSource(sfxList[sfx].buffer);
        source.gain = sfxVolume / MAX_VOLUME;
        if (loop) {
            source.loops = -1;
        }
        
        var channelID = sfxChannelID;
        source.onComplete.add(function() {
            onSfxComplete(channelID);
        });
        
        source.play();

        sfxChannels[sfxChannelID].sfxID = sfx;
        sfxChannels[sfxChannelID].source = source;
        sfxChannels[sfxChannelID].loopSFX = loop ? 1 : 0;
        sfxChannels[sfxChannelID].sampleLength = sfxList[sfx].length;

        nextChannelPos++;
        if (nextChannelPos >= CHANNEL_COUNT)
            nextChannelPos = 0;
    }
    
    static function onSfxComplete(channelID:Int):Void {
        if (channelID >= 0 && channelID < CHANNEL_COUNT) {
            sfxChannels[channelID].sfxID = -1;
            if (sfxChannels[channelID].source != null) {
                sfxChannels[channelID].source.dispose();
                sfxChannels[channelID].source = null;
            }
        }
    }

    public static function stopSfx(sfx:Int):Void {
        for (i in 0...CHANNEL_COUNT) {
            if (sfxChannels[i].sfxID == sfx) {
                if (sfxChannels[i].source != null) {
                    sfxChannels[i].source.onComplete.removeAll();
                    sfxChannels[i].source.stop();
                    sfxChannels[i].source.dispose();
                    sfxChannels[i].source = null;
                }
                sfxChannels[i].sfxID = -1;
                sfxChannels[i].sampleLength = 0;
                sfxChannels[i].loopSFX = 0;
            }
        }
    }

    public static function setSfxAttributes(sfx:Int, loopCount:Int, pan:Int):Void {
        var sfxChannel = -1;
        for (i in 0...CHANNEL_COUNT) {
            if (sfxChannels[i].sfxID == sfx || sfxChannels[i].sfxID == -1) {
                sfxChannel = i;
                break;
            }
        }
        if (sfxChannel == -1)
            return;

        if (!sfxList[sfx].loaded || sfxList[sfx].buffer == null)
            return;

        if (sfxChannels[sfxChannel].source != null) {
            sfxChannels[sfxChannel].source.onComplete.removeAll();
            sfxChannels[sfxChannel].source.stop();
            sfxChannels[sfxChannel].source.dispose();
        }

        var source = new AudioSource(sfxList[sfx].buffer);
        source.gain = sfxVolume / MAX_VOLUME;
        source.position = new lime.math.Vector4(pan / 100.0, 0, 0);
        
        var shouldLoop = false;
        if (loopCount == -1) {
            shouldLoop = sfxChannels[sfxChannel].loopSFX > 0;
        } else if (loopCount > 0) {
            shouldLoop = true;
        }
        
        if (!shouldLoop) {
            var channelID = sfxChannel;
            source.onComplete.add(function() {
                onSfxComplete(channelID);
            });
        }
        
        if (shouldLoop) {
            source.loops = -1;
        }
        
        source.play();

        sfxChannels[sfxChannel].source = source;
        sfxChannels[sfxChannel].sfxID = sfx;
        sfxChannels[sfxChannel].pan = pan;
        if (loopCount != -1)
            sfxChannels[sfxChannel].loopSFX = loopCount > 0 ? 1 : 0;
    }

    public static function setMusicVolume(volume:Int):Void {
        if (volume < 0)
            volume = 0;
        if (volume > MAX_VOLUME)
            volume = MAX_VOLUME;
        musicVolume = volume;
        if (musicSource != null) {
            musicSource.gain = (bgmVolume * musicVolume) / (MAX_VOLUME * MAX_VOLUME);
        }
    }

    public static function pauseSound():Void {
        if (musicStatus == MUSIC_PLAYING) {
            musicStatus = MUSIC_PAUSED;
            if (musicSource != null)
                musicSource.pause();
        }
    }

    public static function resumeSound():Void {
        if (musicStatus == MUSIC_PAUSED) {
            musicStatus = MUSIC_PLAYING;
            if (musicSource != null)
                musicSource.play();
        }
    }

    public static function stopAllSfx():Void {
        for (i in 0...CHANNEL_COUNT) {
            if (sfxChannels[i].source != null) {
                sfxChannels[i].source.onComplete.removeAll();
                sfxChannels[i].source.stop();
                sfxChannels[i].source.dispose();
                sfxChannels[i].source = null;
            }
            sfxChannels[i].sfxID = -1;
            sfxChannels[i].loopSFX = 0;
            sfxChannels[i].sampleLength = 0;
        }
    }

    public static function releaseGlobalSfx():Void {
        stopAllSfx();
        for (i in 0...noGlobalSFX) {
            sfxList[i].buffer = null;
            sfxList[i].loaded = false;
            sfxList[i].length = 0;
        }
        noGlobalSFX = 0;
    }

    public static function releaseStageSfx():Void {
        for (i in noGlobalSFX...noStageSFX + noGlobalSFX) {
            if (sfxList[i].loaded) {
                sfxList[i].buffer = null;
                sfxList[i].loaded = false;
                sfxList[i].length = 0;
            }
        }
        noStageSFX = 0;
    }

    public static function releaseSoundDevice():Void {
        stopMusic();
        stopAllSfx();
        releaseStageSfx();
        releaseGlobalSfx();
    }
}
