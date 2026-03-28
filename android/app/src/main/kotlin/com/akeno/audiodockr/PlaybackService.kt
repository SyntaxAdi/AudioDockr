package com.akeno.audiodockr

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.net.toUri
import androidx.media3.common.AudioAttributes
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.C
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService
import androidx.media3.ui.PlayerNotificationManager
import java.net.URL
import java.util.concurrent.CopyOnWriteArraySet
import java.util.concurrent.Executors

class PlaybackService : MediaSessionService() {
    private val audioAttributes = AudioAttributes.Builder()
        .setUsage(C.USAGE_MEDIA)
        .setContentType(C.AUDIO_CONTENT_TYPE_MUSIC)
        .build()

    private lateinit var player: ExoPlayer
    private var mediaSession: MediaSession? = null
    private lateinit var notificationManager: PlayerNotificationManager
    private val artworkExecutor = Executors.newSingleThreadExecutor()
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

        player = ExoPlayer.Builder(this)
            .build()
            .also { exoPlayer ->
                exoPlayer.setAudioAttributes(audioAttributes, true)
                exoPlayer.setHandleAudioBecomingNoisy(true)
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
        ensureNotificationChannel()
        notificationManager = buildNotificationManager().also {
            it.setPlayer(player)
        }
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
        notificationManager.invalidate()
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
        notificationManager.setPlayer(null)
        artworkExecutor.shutdown()
        mediaSession?.release()
        mediaSession = null
        player.release()
        instance = null
        super.onDestroy()
    }

    companion object {
        private const val TAG = "PlaybackService"
        private const val NOTIFICATION_CHANNEL_ID = "audiodockr_playback"
        private const val NOTIFICATION_CHANNEL_NAME = "AudioDockr Playback"
        private const val NOTIFICATION_ID = 1001
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

    private fun ensureNotificationChannel() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val channel = NotificationChannel(
            NOTIFICATION_CHANNEL_ID,
            NOTIFICATION_CHANNEL_NAME,
            NotificationManager.IMPORTANCE_LOW,
        )
        manager.createNotificationChannel(channel)
    }

    private fun buildNotificationManager(): PlayerNotificationManager {
        return PlayerNotificationManager.Builder(
            this,
            NOTIFICATION_ID,
            NOTIFICATION_CHANNEL_ID,
        )
            .setSmallIconResourceId(android.R.drawable.ic_media_play)
            .setMediaDescriptionAdapter(
                object : PlayerNotificationManager.MediaDescriptionAdapter {
                    override fun createCurrentContentIntent(player: Player) = packageManager
                        .getLaunchIntentForPackage(packageName)
                        ?.let { intent ->
                            androidx.core.app.PendingIntentCompat.getActivity(
                                this@PlaybackService,
                                0,
                                intent,
                                0,
                                false,
                            )
                        }

                    override fun getCurrentContentText(player: Player): CharSequence {
                        return player.mediaMetadata.artist ?: "AudioDockr"
                    }

                    override fun getCurrentContentTitle(player: Player): CharSequence {
                        return player.mediaMetadata.title ?: "AudioDockr"
                    }

                    override fun getCurrentLargeIcon(
                        player: Player,
                        callback: PlayerNotificationManager.BitmapCallback,
                    ): Bitmap? {
                        val artworkUri = player.mediaMetadata.artworkUri ?: return null
                        artworkExecutor.execute {
                            runCatching {
                                URL(artworkUri.toString()).openStream().use(BitmapFactory::decodeStream)
                            }.getOrNull()?.let(callback::onBitmap)
                        }
                        return null
                    }
                },
            )
            .setNotificationListener(
                object : PlayerNotificationManager.NotificationListener {
                    override fun onNotificationPosted(
                        notificationId: Int,
                        notification: Notification,
                        ongoing: Boolean,
                    ) {
                        if (ongoing) {
                            startForeground(notificationId, notification)
                        } else {
                            stopForeground(STOP_FOREGROUND_DETACH)
                        }
                    }

                    override fun onNotificationCancelled(notificationId: Int, dismissedByUser: Boolean) {
                        stopForeground(STOP_FOREGROUND_REMOVE)
                    }
                },
            )
            .build()
            .apply {
                setUseNextAction(false)
                setUsePreviousAction(false)
                setPriority(NotificationCompat.PRIORITY_LOW)
            }
    }
}
