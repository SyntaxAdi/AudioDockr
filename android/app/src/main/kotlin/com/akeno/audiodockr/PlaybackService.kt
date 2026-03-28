package com.akeno.audiodockr

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService
import java.util.concurrent.CopyOnWriteArraySet

class PlaybackService : MediaSessionService() {
    private lateinit var player: ExoPlayer
    private var mediaSession: MediaSession? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    private val progressRunnable = object : Runnable {
        override fun run() {
            publishState()
            mainHandler.postDelayed(this, 500L)
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this

        player = ExoPlayer.Builder(this).build().also { exoPlayer ->
            exoPlayer.addListener(
                object : Player.Listener {
                    override fun onIsPlayingChanged(isPlaying: Boolean) {
                        publishState()
                    }

                    override fun onPlaybackStateChanged(playbackState: Int) {
                        publishState()
                    }

                    override fun onPlayerError(error: PlaybackException) {
                        publishState(error.errorCodeName ?: error.localizedMessage)
                    }
                },
            )
        }

        mediaSession = MediaSession.Builder(this, player).build()
        mainHandler.post(progressRunnable)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_PLAY -> {
                val url = intent.getStringExtra(EXTRA_URL).orEmpty()
                val title = intent.getStringExtra(EXTRA_TITLE).orEmpty()
                val artist = intent.getStringExtra(EXTRA_ARTIST).orEmpty()
                val artworkUrl = intent.getStringExtra(EXTRA_ARTWORK_URL).orEmpty()
                val headers = decodeHeaders(intent.getStringArrayListExtra(EXTRA_HEADERS))
                if (url.isNotBlank()) {
                    play(url, headers, title, artist, artworkUrl)
                } else {
                    publishState("Missing stream URL.")
                }
            }
            ACTION_PAUSE -> {
                player.pause()
                publishState()
            }
            ACTION_RESUME -> {
                player.play()
                publishState()
            }
            ACTION_SEEK -> {
                player.seekTo(intent.getLongExtra(EXTRA_POSITION, 0L))
                publishState()
            }
        }

        return START_STICKY
    }

    private fun play(url: String, headers: Map<String, String>, title: String, artist: String, artworkUrl: String) {
        Log.d(TAG, "Starting playback for $url")
        val dataSourceFactory = DefaultHttpDataSource.Factory()
            .setDefaultRequestProperties(headers)
            .setAllowCrossProtocolRedirects(true)

        val mediaSourceFactory = DefaultMediaSourceFactory(this)
            .setDataSourceFactory(dataSourceFactory)

        val mediaItem = MediaItem.Builder()
            .setUri(url)
            .setMediaMetadata(
                MediaMetadata.Builder()
                    .setIsPlayable(true)
                    .setTitle(title)
                    .setArtist(artist)
                    .setArtworkUri(if (artworkUrl.isNotBlank()) android.net.Uri.parse(artworkUrl) else null)
                    .build(),
            )
            .build()

        player.setMediaSource(mediaSourceFactory.createMediaSource(mediaItem))
        player.prepare()
        player.play()
        publishState()
    }

    private fun publishState(error: String? = null) {
        val state = mapOf<String, Any?>(
            "isPlaying" to player.isPlaying,
            "position" to player.currentPosition.coerceAtLeast(0L),
            "duration" to (player.duration.takeIf { it > 0 } ?: 0L),
            "error" to error,
        )

        lastState = state
        listeners.forEach { listener ->
            listener(state)
        }
    }

    override fun onGetSession(controllerInfo: MediaSession.ControllerInfo): MediaSession? {
        return mediaSession
    }

    override fun onDestroy() {
        mainHandler.removeCallbacks(progressRunnable)
        mediaSession?.release()
        mediaSession = null
        player.release()
        instance = null
        super.onDestroy()
    }

    companion object {
        private const val TAG = "PlaybackService"
        private const val ACTION_PLAY = "com.akeno.audiodockr.action.PLAY"
        private const val ACTION_PAUSE = "com.akeno.audiodockr.action.PAUSE"
        private const val ACTION_RESUME = "com.akeno.audiodockr.action.RESUME"
        private const val ACTION_SEEK = "com.akeno.audiodockr.action.SEEK"
        private const val EXTRA_URL = "url"
        private const val EXTRA_HEADERS = "headers"
        private const val EXTRA_POSITION = "position"
        private const val EXTRA_TITLE = "title"
        private const val EXTRA_ARTIST = "artist"
        private const val EXTRA_ARTWORK_URL = "artworkUrl"

        @Volatile
        private var instance: PlaybackService? = null
        private val listeners = CopyOnWriteArraySet<(Map<String, Any?>) -> Unit>()
        private var lastState: Map<String, Any?> = mapOf(
            "isPlaying" to false,
            "position" to 0L,
            "duration" to 0L,
            "error" to null,
        )

        fun registerPlaybackListener(listener: (Map<String, Any?>) -> Unit) {
            listeners.add(listener)
        }

        fun unregisterPlaybackListener(listener: (Map<String, Any?>) -> Unit) {
            listeners.remove(listener)
        }

        fun currentPlaybackState(): Map<String, Any?> = lastState

        fun buildPlayIntent(
            context: Context,
            url: String,
            headers: Map<String, String>,
            title: String,
            artist: String,
            artworkUrl: String,
        ): Intent {
            return Intent(context, PlaybackService::class.java).apply {
                action = ACTION_PLAY
                putExtra(EXTRA_URL, url)
                putExtra(EXTRA_TITLE, title)
                putExtra(EXTRA_ARTIST, artist)
                putExtra(EXTRA_ARTWORK_URL, artworkUrl)
                putStringArrayListExtra(
                    EXTRA_HEADERS,
                    ArrayList(headers.map { "${it.key}=${it.value}" }),
                )
            }
        }

        fun buildPauseIntent(context: Context): Intent {
            return Intent(context, PlaybackService::class.java).apply {
                action = ACTION_PAUSE
            }
        }

        fun buildResumeIntent(context: Context): Intent {
            return Intent(context, PlaybackService::class.java).apply {
                action = ACTION_RESUME
            }
        }

        fun buildSeekIntent(context: Context, position: Long): Intent {
            return Intent(context, PlaybackService::class.java).apply {
                action = ACTION_SEEK
                putExtra(EXTRA_POSITION, position)
            }
        }

        private fun decodeHeaders(serialized: ArrayList<String>?): Map<String, String> {
            if (serialized.isNullOrEmpty()) {
                return emptyMap()
            }

            return serialized.mapNotNull { entry ->
                val separatorIndex = entry.indexOf('=')
                if (separatorIndex <= 0) {
                    null
                } else {
                    entry.substring(0, separatorIndex) to entry.substring(separatorIndex + 1)
                }
            }.toMap()
        }
    }
}
