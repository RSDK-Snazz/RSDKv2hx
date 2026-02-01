package rsdk.audio;

import cpp.RawPointer;
import cpp.NativeArray;
import haxe.io.Bytes;

class OggDecodeResult {
    public var success:Bool = false;
    public var channels:Int = 0;
    public var sampleRate:Int = 0;
    public var pcmData:RawPointer<cpp.UInt8> = null;
    public var pcmSize:Int = 0;
    public var errorCode:Int = 0;
    
    public function new() {}
}

@:buildXml('
<target id="haxe">
    <lib name="-lvorbisfile" if="linux"/>
    <lib name="-lvorbis" if="linux"/>
    <lib name="-logg" if="linux"/>
</target>
')
@:headerCode('
#include <vorbis/vorbisfile.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

typedef struct {
    const unsigned char* data;
    size_t size;
    size_t pos;
} RsdkOggMemFile;

static size_t rsdk_ogg_read(void* ptr, size_t size, size_t nmemb, void* datasource) {
    RsdkOggMemFile* mf = (RsdkOggMemFile*)datasource;
    size_t bytes = size * nmemb;
    size_t remaining = mf->size - mf->pos;
    if (bytes > remaining) bytes = remaining;
    if (bytes > 0) {
        memcpy(ptr, mf->data + mf->pos, bytes);
        mf->pos += bytes;
    }
    return bytes / size;
}

static int rsdk_ogg_seek(void* datasource, ogg_int64_t offset, int whence) {
    RsdkOggMemFile* mf = (RsdkOggMemFile*)datasource;
    ogg_int64_t newpos;
    switch (whence) {
        case SEEK_SET: newpos = offset; break;
        case SEEK_CUR: newpos = (ogg_int64_t)mf->pos + offset; break;
        case SEEK_END: newpos = (ogg_int64_t)mf->size + offset; break;
        default: return -1;
    }
    if (newpos < 0 || newpos > (ogg_int64_t)mf->size) return -1;
    mf->pos = (size_t)newpos;
    return 0;
}

static long rsdk_ogg_tell(void* datasource) {
    RsdkOggMemFile* mf = (RsdkOggMemFile*)datasource;
    return (long)mf->pos;
}

static int rsdk_ogg_close(void* datasource) {
    return 0;
}

static RsdkOggMemFile rsdk_global_memfile;

static void rsdk_decode_ogg(const void* data, int dataSize, 
                           bool* outSuccess, int* outChannels, int* outSampleRate,
                           unsigned char** outPcmData, int* outPcmSize, int* outError) {
    *outSuccess = false;
    *outChannels = 0;
    *outSampleRate = 0;
    *outPcmData = NULL;
    *outPcmSize = 0;
    *outError = 0;
    
    if (!data || dataSize <= 0) {
        *outError = -100;
        return;
    }
    
    rsdk_global_memfile.data = (const unsigned char*)data;
    rsdk_global_memfile.size = dataSize;
    rsdk_global_memfile.pos = 0;
    
    ov_callbacks callbacks;
    callbacks.read_func = rsdk_ogg_read;
    callbacks.seek_func = rsdk_ogg_seek;
    callbacks.tell_func = rsdk_ogg_tell;
    callbacks.close_func = rsdk_ogg_close;
    
    OggVorbis_File vf;
    int openResult = ov_open_callbacks(&rsdk_global_memfile, &vf, NULL, 0, callbacks);
    if (openResult != 0) {
        *outError = openResult;
        return;
    }
    
    vorbis_info* vi = ov_info(&vf, -1);
    if (!vi) {
        *outError = -101;
        ov_clear(&vf);
        return;
    }
    
    int channels = vi->channels;
    int sampleRate = vi->rate;
    ogg_int64_t totalSamples = ov_pcm_total(&vf, -1);
    
    if (totalSamples <= 0) {
        *outError = -102;
        ov_clear(&vf);
        return;
    }
    
    int bufferSize = (int)(totalSamples * channels * 2);
    
    char* pcmBuffer = (char*)malloc(bufferSize);
    if (!pcmBuffer) {
        *outError = -103;
        ov_clear(&vf);
        return;
    }
    
    int position = 0;
    int bitstream = 0;
    char readBuf[4096];
    
    while (position < bufferSize) {
        int toRead = bufferSize - position;
        if (toRead > 4096) toRead = 4096;
        long bytesRead = ov_read(&vf, readBuf, toRead, 0, 2, 1, &bitstream);
        if (bytesRead <= 0) break;
        memcpy(pcmBuffer + position, readBuf, bytesRead);
        position += bytesRead;
    }
    
    ov_clear(&vf);
    
    *outSuccess = true;
    *outChannels = channels;
    *outSampleRate = sampleRate;
    *outPcmData = (unsigned char*)pcmBuffer;
    *outPcmSize = position;
}
')
class Vorbis {
    public static function decodeFromBytes(bytes:Bytes):OggDecodeResult {
        var result = new OggDecodeResult();
        
        var dataPtr = NativeArray.address(bytes.getData(), 0);
        var dataLen = bytes.length;
        
        var success:Bool = false;
        var channels:Int = 0;
        var sampleRate:Int = 0;
        var pcmData:RawPointer<cpp.UInt8> = null;
        var pcmSize:Int = 0;
        var errorCode:Int = 0;
        
        untyped __cpp__("rsdk_decode_ogg({0}, {1}, &{2}, &{3}, &{4}, &{5}, &{6}, &{7})",
            dataPtr, dataLen, success, channels, sampleRate, pcmData, pcmSize, errorCode);
        
        result.success = success;
        result.channels = channels;
        result.sampleRate = sampleRate;
        result.pcmData = pcmData;
        result.pcmSize = pcmSize;
        result.errorCode = errorCode;
        
        return result;
    }
}