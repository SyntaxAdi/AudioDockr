package com.akeno.audiodockr

import android.os.Handler
import android.os.Looper
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : AudioServiceActivity() {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val extractorExecutor = Executors.newSingleThreadExecutor()
    private val playerCommandsChannel = "com.akeno.audiodockr/player_commands"
    private val playerEventsChannel = "com.akeno.audiodockr/player_events"
    private var eventSink: EventChannel.EventSink? = null
    private var player: ExoPlayer? = null
    private val playerEventRunnable = object : Runnable {
        override fun run() {
            pushPlayerState()
            mainHandler.postDelayed(this, 500L)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, playerEventsChannel)
            .setStreamHandler(
                object : EventChannel.StreamHandler {
                    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                        eventSink = events
                        pushPlayerState()
                    }

                    override fun onCancel(arguments: Any?) {
                        eventSink = null
                    }
                },
            )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, playerCommandsChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "play" -> {
                        val url = call.argument<String>("url").orEmpty()
                        @Suppress("UNCHECKED_CAST")
                        val headers = (call.argument<Map<String, Any?>>("headers") ?: emptyMap())
                            .mapValues { it.value?.toString().orEmpty() }
                        if (url.isBlank()) {
                            result.error("playback_failed", "Missing stream URL.", null)
                            return@setMethodCallHandler
                        }

                        startPlayback(url, headers)
                        result.success(null)
                    }
                    "pause" -> {
                        player?.pause()
                        pushPlayerState()
                        result.success(null)
                    }
                    "resume" -> {
                        player?.play()
                        pushPlayerState()
                        result.success(null)
                    }
                    "seekTo" -> {
                        val position = call.argument<Int>("position")?.toLong() ?: 0L
                        player?.seekTo(position)
                        pushPlayerState()
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

                extractorExecutor.execute {
                    val extractionResult = YoutubeAudioExtractor.extract(
                        videoId = videoId,
                        videoUrl = videoUrl,
                    )

                    mainHandler.post {
                        extractionResult.fold(
                            onSuccess = { streamUrl -> result.success(streamUrl) },
                            onFailure = { error ->
                                val playbackError = YoutubeAudioExtractor.mapError(error)
                                result.error(
                                    playbackError.code,
                                    playbackError.message,
                                    null,
                                )
                            },
                        )
                    }
                }
            }
    }

    private fun startPlayback(url: String, headers: Map<String, String>) {
        val activePlayer = player ?: createPlayer().also { player = it }
        val dataSourceFactory = DefaultHttpDataSource.Factory()
            .setDefaultRequestProperties(headers)
            .setAllowCrossProtocolRedirects(true)

        val mediaSourceFactory = DefaultMediaSourceFactory(this)
            .setDataSourceFactory(dataSourceFactory)

        activePlayer.setMediaSource(
            mediaSourceFactory.createMediaSource(MediaItem.fromUri(url)),
        )
        activePlayer.prepare()
        activePlayer.play()
        pushPlayerState()
    }

    private fun createPlayer(): ExoPlayer {
        return ExoPlayer.Builder(this)
            .build()
            .also { exoPlayer ->
                exoPlayer.addListener(
                    object : Player.Listener {
                        override fun onIsPlayingChanged(isPlaying: Boolean) {
                            pushPlayerState()
                        }

                        override fun onPlaybackStateChanged(playbackState: Int) {
                            pushPlayerState()
                        }

                        override fun onPlayerError(error: PlaybackException) {
                            pushPlayerState(error.errorCodeName ?: error.localizedMessage)
                        }
                    },
                )
                mainHandler.removeCallbacks(playerEventRunnable)
                mainHandler.post(playerEventRunnable)
            }
    }

    private fun pushPlayerState(error: String? = null) {
        val activePlayer = player ?: run {
            eventSink?.success(
                mapOf(
                    "isPlaying" to false,
                    "position" to 0L,
                    "duration" to 0L,
                    "error" to error,
                ),
            )
            return
        }

        eventSink?.success(
                mapOf(
                    "isPlaying" to activePlayer.isPlaying,
                    "position" to activePlayer.currentPosition.coerceAtLeast(0L),
                    "duration" to (activePlayer.duration.takeIf { it > 0 } ?: 0L),
                    "error" to error,
                ),
            )
    }

    override fun onDestroy() {
        mainHandler.removeCallbacks(playerEventRunnable)
        player?.release()
        player = null
        extractorExecutor.shutdown()
        super.onDestroy()
    }
}
