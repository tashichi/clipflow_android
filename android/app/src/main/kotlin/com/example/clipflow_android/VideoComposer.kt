package com.example.clipflow_android

import android.content.Context
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import java.io.File

class VideoComposer(private val context: Context) {
    
    fun composeVideos(inputPaths: List<String>, outputPath: String): Boolean {
        var muxer: MediaMuxer? = null
        
        try {
            // 入力ファイルの存在確認
            for (path in inputPaths) {
                val file = File(path)
                if (!file.exists()) {
                    println("VideoComposer: File not found: $path")
                    return false
                }
                println("VideoComposer: File exists: $path (${file.length()} bytes)")
            }
            
            // 最初のファイルからフォーマット情報を取得
            val firstExtractor = MediaExtractor()
            firstExtractor.setDataSource(inputPaths[0])
            
            var videoFormat: MediaFormat? = null
            var audioFormat: MediaFormat? = null
            
            for (i in 0 until firstExtractor.trackCount) {
                val format = firstExtractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: continue
                
                when {
                    mime.startsWith("video/") && videoFormat == null -> {
                        videoFormat = format
                        println("VideoComposer: Found video track: $mime")
                    }
                    mime.startsWith("audio/") && audioFormat == null -> {
                        audioFormat = format
                        println("VideoComposer: Found audio track: $mime")
                    }
                }
            }
            firstExtractor.release()
            
            if (videoFormat == null) {
                println("VideoComposer: No video track found")
                return false
            }
            
            // Muxer作成
            muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            val muxerVideoTrack = muxer.addTrack(videoFormat)
            val muxerAudioTrack = if (audioFormat != null) muxer.addTrack(audioFormat) else -1
            
            // 回転情報を設定（縦画面対応）
            muxer.setOrientationHint(90)
            
            muxer.start()
            println("VideoComposer: Muxer started")
            
            var currentTimeUs = 0L
            
            // 各ファイルをコピー
            for ((index, inputPath) in inputPaths.withIndex()) {
                println("VideoComposer: Processing file ${index + 1}/${inputPaths.size}, baseTime: $currentTimeUs")
                
                val extractor = MediaExtractor()
                extractor.setDataSource(inputPath)
                
                var maxDuration = 0L
                
                // ビデオトラックとオーディオトラックをコピー
                for (i in 0 until extractor.trackCount) {
                    val format = extractor.getTrackFormat(i)
                    val mime = format.getString(MediaFormat.KEY_MIME) ?: continue
                    
                    if (mime.startsWith("video/")) {
                        val duration = copyTrack(extractor, i, muxer, muxerVideoTrack, currentTimeUs)
                        maxDuration = maxOf(maxDuration, duration)
                    } else if (mime.startsWith("audio/") && muxerAudioTrack != -1) {
                        val duration = copyTrack(extractor, i, muxer, muxerAudioTrack, currentTimeUs)
                        maxDuration = maxOf(maxDuration, duration)
                    }
                }
                
                extractor.release()
                currentTimeUs += maxDuration
            }
            
            muxer.stop()
            muxer.release()
            println("VideoComposer: Composition complete: $outputPath")
            
            return true
            
        } catch (e: Exception) {
            e.printStackTrace()
            println("VideoComposer: Error: ${e.message}")
            
            try {
                muxer?.release()  // stop()を削除
            } catch (ignored: Exception) {
            }
            
            return false
        }
    }
    
    private fun copyTrack(
        extractor: MediaExtractor, 
        trackIndex: Int, 
        muxer: MediaMuxer, 
        muxerTrackIndex: Int,
        baseTimeUs: Long
    ): Long {
        extractor.selectTrack(trackIndex)
        extractor.seekTo(0, MediaExtractor.SEEK_TO_CLOSEST_SYNC)
        
        val bufferInfo = MediaCodec.BufferInfo()
        val buffer = java.nio.ByteBuffer.allocate(1024 * 1024)
        
        var sampleCount = 0
        var maxTimeUs = 0L
        
        while (true) {
            val sampleSize = extractor.readSampleData(buffer, 0)
            if (sampleSize < 0) break
            
            val sampleTime = extractor.sampleTime
            if (sampleTime < 0) {
                extractor.advance()
                continue
            }
            
            bufferInfo.offset = 0
            bufferInfo.size = sampleSize
            bufferInfo.presentationTimeUs = sampleTime + baseTimeUs
            bufferInfo.flags = extractor.sampleFlags
            
            maxTimeUs = maxOf(maxTimeUs, sampleTime)
            
            muxer.writeSampleData(muxerTrackIndex, buffer, bufferInfo)
            sampleCount++
            
            extractor.advance()
        }
        
        println("VideoComposer: Copied $sampleCount samples, duration: $maxTimeUs us")
        extractor.unselectTrack(trackIndex)
        
        return maxTimeUs
    }
}