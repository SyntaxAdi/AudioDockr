package com.akeno.audiodockr

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.ColorMatrix
import android.graphics.ColorMatrixColorFilter
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.Shader
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.util.LruCache
import androidx.core.app.NotificationCompat
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
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
    private var currentRepeatMode: String = "off"
    private var repeatOnePendingReplay = false
    private val artworkExecutor = Executors.newSingleThreadExecutor()
    private val artworkCache = object : LruCache<String, Bitmap>(24) {}
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
                            if (playbackState == Player.STATE_ENDED &&
                                currentRepeatMode == "one" &&
                                repeatOnePendingReplay
                            ) {
                                repeatOnePendingReplay = false
                                player.seekToDefaultPosition()
                                player.prepare()
                                player.play()
                                publishState()
                                return
                            }

                            if (playbackState == Player.STATE_ENDED &&
                                currentRepeatMode == "one" &&
                                !repeatOnePendingReplay
                            ) {
                                currentRepeatMode = "off"
                            }
                            publishState()
                        }

                        override fun onPlayerError(error: PlaybackException) {
                            publishState(error.errorCodeName ?: error.localizedMessage)
                        }
                    },
                )
            }

        mediaSession = MediaSession.Builder(this, player).build().also { session ->
            createSessionActivity()?.let(session::setSessionActivity)
        }
        ensureNotificationChannel()
        notificationManager = buildNotificationManager().also {
            mediaSession?.platformToken?.let(it::setMediaSessionToken)
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
                if (player.playbackState == Player.STATE_ENDED) {
                    player.seekToDefaultPosition()
                    if (player.mediaItemCount > 0) {
                        player.prepare()
                    }
                }
                player.play()
                publishState()
            }
            ACTION_SEEK -> {
                player.seekTo(intent.getLongExtra(EXTRA_POSITION, 0L))
                publishState()
            }
            ACTION_SET_REPEAT_MODE -> {
                when (intent.getStringExtra(EXTRA_REPEAT_MODE)) {
                    "one" -> {
                        currentRepeatMode = "one"
                        repeatOnePendingReplay = true
                        player.repeatMode = Player.REPEAT_MODE_OFF
                    }
                    "all" -> {
                        currentRepeatMode = "all"
                        repeatOnePendingReplay = false
                        player.repeatMode = Player.REPEAT_MODE_ALL
                    }
                    else -> {
                        currentRepeatMode = "off"
                        repeatOnePendingReplay = false
                        player.repeatMode = Player.REPEAT_MODE_OFF
                    }
                }
                publishState()
            }
        }

        return START_STICKY
    }

    private fun play(
        url: String,
        headers: Map<String, String>,
        title: String,
        artist: String,
        artworkUrl: String,
    ) {
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
                    .setArtworkUri(
                        artworkUrl.takeIf { it.isNotBlank() }?.let(android.net.Uri::parse),
                    )
                    .build(),
            )
            .build()

        player.stop()
        player.clearMediaItems()
        if (currentRepeatMode == "one") {
            repeatOnePendingReplay = true
        }
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
            "repeatMode" to currentRepeatMode,
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
        stopForeground(STOP_FOREGROUND_REMOVE)
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
        private const val ACTION_SET_REPEAT_MODE = "com.akeno.audiodockr.action.SET_REPEAT_MODE"
        private const val EXTRA_URL = "url"
        private const val EXTRA_HEADERS = "headers"
        private const val EXTRA_POSITION = "position"
        private const val EXTRA_REPEAT_MODE = "repeatMode"
        private const val EXTRA_TITLE = "title"
        private const val EXTRA_ARTIST = "artist"
        private const val EXTRA_ARTWORK_URL = "artworkUrl"
        private const val NOTIFICATION_CHANNEL_ID = "audiodockr_playback"
        private const val NOTIFICATION_CHANNEL_NAME = "AudioDockr Playback"
        private const val NOTIFICATION_ID = 1001

        @Volatile
        private var instance: PlaybackService? = null
        private val listeners = CopyOnWriteArraySet<(Map<String, Any?>) -> Unit>()
        private var lastState: Map<String, Any?> = mapOf(
            "isPlaying" to false,
            "position" to 0L,
            "duration" to 0L,
            "repeatMode" to "off",
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

        fun buildRepeatModeIntent(context: Context, mode: String): Intent {
            return Intent(context, PlaybackService::class.java).apply {
                action = ACTION_SET_REPEAT_MODE
                putExtra(EXTRA_REPEAT_MODE, mode)
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

    private fun createSessionActivity(): PendingIntent? {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName) ?: return null
        return PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
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
                    override fun createCurrentContentIntent(player: Player): PendingIntent? {
                        return createSessionActivity()
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
                        artworkCache.get(artworkUri.toString())?.let { cachedBitmap ->
                            return cachedBitmap
                        }

                        artworkExecutor.execute {
                            runCatching {
                                URL(artworkUri.toString()).openStream().use(BitmapFactory::decodeStream)
                            }.getOrNull()?.let { rawBitmap ->
                                val processedBitmap = processNotificationArtwork(rawBitmap)
                                artworkCache.put(artworkUri.toString(), processedBitmap)
                                callback.onBitmap(processedBitmap)
                            }
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
                setColorized(true)
                setUseNextAction(false)
                setUsePreviousAction(false)
                setUsePlayPauseActions(true)
                setPriority(NotificationCompat.PRIORITY_LOW)
            }
    }

    private fun processNotificationArtwork(source: Bitmap): Bitmap {
        val targetSize = source.width.coerceAtMost(source.height).coerceAtLeast(256)
        val croppedBitmap = centerCropSquare(source, targetSize)
        val output = Bitmap.createBitmap(
            croppedBitmap.width,
            croppedBitmap.height,
            Bitmap.Config.ARGB_8888,
        )
        val canvas = Canvas(output)

        val basePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            colorFilter = ColorMatrixColorFilter(
                ColorMatrix().apply {
                    set(
                        floatArrayOf(
                            1.08f, 0f, 0f, 0f, -6f,
                            0f, 1.08f, 0f, 0f, -6f,
                            0f, 0f, 1.08f, 0f, -6f,
                            0f, 0f, 0f, 1f, 0f,
                        ),
                    )
                    postConcat(
                        ColorMatrix().apply {
                            setSaturation(1.08f)
                        },
                    )
                },
            )
        }
        canvas.drawBitmap(croppedBitmap, 0f, 0f, basePaint)

        canvas.drawColor(Color.argb(118, 0, 0, 0))

        val vignettePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = LinearGradient(
                0f,
                output.height * 0.35f,
                0f,
                output.height.toFloat(),
                intArrayOf(
                    Color.argb(0, 0, 0, 0),
                    Color.argb(70, 0, 0, 0),
                    Color.argb(150, 0, 0, 0),
                ),
                floatArrayOf(0f, 0.68f, 1f),
                Shader.TileMode.CLAMP,
            )
        }
        canvas.drawRect(
            0f,
            0f,
            output.width.toFloat(),
            output.height.toFloat(),
            vignettePaint,
        )

        return output
    }

    private fun centerCropSquare(source: Bitmap, targetSize: Int): Bitmap {
        val squareSize = source.width.coerceAtMost(source.height)
        val left = (source.width - squareSize) / 2
        val top = (source.height - squareSize) / 2
        val sourceRect = Rect(left, top, left + squareSize, top + squareSize)
        val output = Bitmap.createBitmap(targetSize, targetSize, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val destinationRect = Rect(0, 0, targetSize, targetSize)
        canvas.drawBitmap(source, sourceRect, destinationRect, Paint(Paint.ANTI_ALIAS_FLAG))
        return output
    }
}
