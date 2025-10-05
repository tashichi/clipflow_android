package com.example.clipflow_android

import android.content.Context
import android.media.MediaRecorder
import android.util.Log
import java.io.File

class VideoRecorder(private val context: Context) {
    private var mediaRecorder: MediaRecorder? = null
    private var isRecording = false
    private var recordingStartTime: Long = 0
    private var currentOutputPath: String? = null
    
    companion object {
        private const val TAG = "VideoRecorder"
        private const val MIN_RECORDING_DURATION_MS = 150L  // 最小録画時間
    }
    
    fun startRecording(outputPath: String, width: Int = 1920, height: Int = 1080): Boolean {
        if (isRecording) {
            Log.w(TAG, "Already recording")
            return false
        }
        
        return try {
            // 出力ディレクトリが存在することを確認
            val outputFile = File(outputPath)
            outputFile.parentFile?.mkdirs()
            
            mediaRecorder = MediaRecorder().apply {
                setAudioSource(MediaRecorder.AudioSource.MIC)
                setVideoSource(MediaRecorder.VideoSource.SURFACE)
                setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
                setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
                setVideoEncoder(MediaRecorder.VideoEncoder.H264)
                setOutputFile(outputPath)
                setVideoSize(width, height)
                setVideoFrameRate(30)
                setVideoEncodingBitRate(10_000_000)  // 10Mbps
                setAudioEncodingBitRate(128_000)     // 128kbps
                
                prepare()
                start()
            }
            
            isRecording = true
            recordingStartTime = System.currentTimeMillis()
            currentOutputPath = outputPath
            
            Log.d(TAG, "Recording started: $outputPath")
            true
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start recording", e)
            cleanup()
            false
        }
    }
    
    fun stopRecording(): Boolean {
        if (!isRecording) {
            Log.w(TAG, "Not recording, cannot stop")
            return false
        }
        
        // 重要: 最小録画時間を確保
        val recordingDuration = System.currentTimeMillis() - recordingStartTime
        if (recordingDuration < MIN_RECORDING_DURATION_MS) {
            val waitTime = MIN_RECORDING_DURATION_MS - recordingDuration
            Log.d(TAG, "Recording duration too short (${recordingDuration}ms), waiting ${waitTime}ms")
            Thread.sleep(waitTime)
        }
        
        return try {
            mediaRecorder?.apply {
                stop()
                release()
            }
            
            val finalDuration = System.currentTimeMillis() - recordingStartTime
            Log.d(TAG, "Recording stopped successfully. Duration: ${finalDuration}ms")
            
            // ファイルサイズを確認
            currentOutputPath?.let { path ->
                val file = File(path)
                val fileSize = file.length()
                Log.d(TAG, "File created: ${file.absolutePath}, size: $fileSize bytes")
                
                if (fileSize == 0L) {
                    Log.e(TAG, "WARNING: Empty file created!")
                    return false
                }
            }
            
            cleanup()
            true
            
        } catch (e: Exception) {
            Log.e(TAG, "Failed to stop recording", e)
            cleanup()
            false
        }
    }
    
    private fun cleanup() {
        mediaRecorder?.release()
        mediaRecorder = null
        isRecording = false
        currentOutputPath = null
    }
    
    fun isCurrentlyRecording(): Boolean = isRecording
    
    fun release() {
        if (isRecording) {
            stopRecording()
        }
        cleanup()
    }
}