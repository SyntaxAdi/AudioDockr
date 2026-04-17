package com.akeno.audiodockr

import android.app.ForegroundServiceStartNotAllowedException
import android.content.Intent
import android.os.Build
import android.os.Bundle
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterFragmentActivity() {
    private val activityScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val playerCommandsChannel = "com.akeno.audiodockr/player_commands"
    private val playerEventsChannel = "com.akeno.audiodockr/player_events"
    private var playbackListener: ((Map<String, Any?>) -> Unit)? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        // Automatic plugin registration is handled by super.configureFlutterEngine(flutterEngine)
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, playerEventsChannel)
            .setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        val listener: (Map<String, Any?>) -> Unit = { state ->
                            activityScope.launch {
                                events?.success(state)
                            }
                        }
                        playbackListener = listener
                        PlaybackService.registerPlaybackListener(listener)
                        PlaybackService.currentPlaybackState()?.let { events?.success(it) }
                    }

                    override fun onCancel(arguments: Any?) {
                        playbackListener?.let { PlaybackService.unregisterPlaybackListener(it) }
                        playbackListener = null
                    }
                },
            )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, playerCommandsChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "play" -> {
                        val url = call.argument<String>("url").orEmpty()
                        val title = call.argument<String>("title").orEmpty()
                        val artist = call.argument<String>("artist").orEmpty()
                        val artworkUrl = call.argument<String>("artworkUrl").orEmpty()
                        @Suppress("UNCHECKED_CAST")
                        val headers = (call.argument<Map<String, Any?>>("headers") ?: emptyMap())
                            .mapValues { it.value?.toString().orEmpty() }

                        if (url.isBlank()) {
                            result.error("playback_failed", "Missing stream URL.", null)
                            return@setMethodCallHandler
                        }

                        val intent = PlaybackService.buildPlayIntent(
                            this,
                            url,
                            headers,
                            title,
                            artist,
                            artworkUrl,
                        )
                        runCatching {
                            if (PlaybackService.isRunning()) {
                                startService(intent)
                            } else {
                                ContextCompat.startForegroundService(this, intent)
                            }
                        }.onSuccess {
                            result.success(null)
                        }.onFailure { error ->
                            val message = when (error) {
                                is ForegroundServiceStartNotAllowedException ->
                                    "Playback cannot be started while the app is in the background."
                                else -> error.message ?: "Unable to start playback."
                            }
                            result.error("playback_failed", message, null)
                        }
                    }
                    "pause" -> {
                        startService(PlaybackService.buildPauseIntent(this))
                        result.success(null)
                    }
                    "resume" -> {
                        val intent = PlaybackService.buildResumeIntent(this)
                        runCatching {
                            if (PlaybackService.isRunning()) {
                                startService(intent)
                            } else {
                                ContextCompat.startForegroundService(this, intent)
                            }
                        }.onSuccess {
                            result.success(null)
                        }.onFailure { error ->
                            val message = when (error) {
                                is ForegroundServiceStartNotAllowedException ->
                                    "Playback cannot be resumed while the app is in the background."
                                else -> error.message ?: "Unable to resume playback."
                            }
                            result.error("playback_failed", message, null)
                        }
                    }
                    "seekTo" -> {
                        val position = call.argument<Int>("position")?.toLong() ?: 0L
                        startService(PlaybackService.buildSeekIntent(this, position))
                        result.success(null)
                    }
                    "setRepeatMode" -> {
                        val mode = call.argument<String>("mode").orEmpty()
                        startService(PlaybackService.buildRepeatModeIntent(this, mode))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "audiodockr/extract")
            .setMethodCallHandler { call, result ->
                if (call.method != "extract") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val videoId = call.argument<String>("videoId").orEmpty()
                val videoUrl = call.argument<String>("videoUrl").orEmpty()

                activityScope.launch {
                    val extractionResult = withContext(Dispatchers.IO) {
                        YoutubeAudioExtractor.extract(
                            videoId = videoId,
                            videoUrl = videoUrl,
                        )
                    }

                    withContext(Dispatchers.Main.immediate) {
                        extractionResult.fold(
                            onSuccess = { streamUrl -> result.success(streamUrl) },
                            onFailure = { error ->
                                val playbackError = YoutubeAudioExtractor.mapError(error)
                                result.error(playbackError.code, playbackError.message, null)
                            },
                        )
                    }
                }
            }
    }

    override fun onDestroy() {
        playbackListener?.let { PlaybackService.unregisterPlaybackListener(it) }
        playbackListener = null
        activityScope.cancel()
        super.onDestroy()
    }
}
