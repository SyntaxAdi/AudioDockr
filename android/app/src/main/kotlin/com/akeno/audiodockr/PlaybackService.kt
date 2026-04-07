package com.akeno.audiodockr

import android.app.Notification
import android.app.NotificationChannel
import android.app.ForegroundServiceStartNotAllowedException
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
import com.akeno.audiodockr.BuildConfig
import androidx.core.app.NotificationCompat
import androidx.media3.common.AudioAttributes
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.datasource.DefaultHttpDataSource
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.exoplayer.DefaultLoadControl
import androidx.media3.exoplayer.source.DefaultMediaSourceFactory
import androidx.media3.exoplayer.trackselection.DefaultTrackSelector
import androidx.media3.session.MediaSession
import androidx.media3.session.MediaSessionService
import androidx.media3.ui.PlayerNotificationManager
import java.util.concurrent.CopyOnWriteArraySet
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request

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
    private var isForegroundActive = false
    private var isSwitchingTrack = false
    private val serviceScope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val artworkHttpClient = OkHttpClient()
    private val artworkCache = object : LruCache<String, Bitmap>((Runtime.getRuntime().maxMemory() / 16L).toInt()) {
        override fun sizeOf(key: String, value: Bitmap): Int = value.byteCount
    }
    private val mainHandler = Handler(Looper.getMainLooper())
    private val progressRunnable = object : Runnable {
        override fun run() {
            publishState()
            if (player.isPlaying && listeners.isNotEmpty()) {
                mainHandler.postDelayed(this, PROGRESS_UPDATE_MS)
            }
        }
    }

    override fun onCreate() {
        super.onCreate()
        instance = this

        val trackSelector = DefaultTrackSelector(this).apply {
            setParameters(
                buildUponParameters()
                    .setTrackTypeDisabled(C.TRACK_TYPE_VIDEO, true)
                    .setForceHighestSupportedBitrate(false),
            )
        }
        val loadControl = DefaultLoadControl.Builder()
            .setBufferDurationsMs(
                2_500,
                10_000,
                250,
                500,
            )
            .build()

        player = ExoPlayer.Builder(this)
            .setTrackSelector(trackSelector)
            .setLoadControl(loadControl)
            .build()
            .also { exoPlayer ->
                exoPlayer.setAudioAttributes(audioAttributes, true)
                exoPlayer.setHandleAudioBecomingNoisy(true)
                exoPlayer.addListener(
                    object : Player.Listener {
                        override fun onIsPlayingChanged(isPlaying: Boolean) {
                            if (isPlaying) {
                                isSwitchingTrack = false
                                startProgressUpdates()
                            } else {
                                stopProgressUpdates()
                            }
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
                            if (playbackState == Player.STATE_READY && player.isPlaying) {
                                isSwitchingTrack = false
                                startProgressUpdates()
                            } else if (playbackState == Player.STATE_ENDED ||
                                playbackState == Player.STATE_IDLE
                            ) {
                                stopProgressUpdates()
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
                stopProgressUpdates()
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
                startProgressUpdates()
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
        if (BuildConfig.DEBUG) {
            Log.d(TAG, "Starting playback for $url")
        }
        isSwitchingTrack = true
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
        player.playWhenReady = true
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
            "playbackState" to playbackStateName(player.playbackState),
            "repeatMode" to currentRepeatMode,
            "error" to error,
        )

        lastState = state
        listeners.forEach { listener ->
            listener(state)
        }
    }

    private fun shouldKeepForeground(): Boolean {
        return isSwitchingTrack ||
            player.isPlaying ||
            player.playWhenReady ||
            player.playbackState == Player.STATE_BUFFERING ||
            player.mediaItemCount > 0
    }

    override fun onGetSession(controllerInfo: MediaSession.ControllerInfo): MediaSession? {
        return mediaSession
    }

    override fun onDestroy() {
        stopProgressUpdates()
        notificationManager.setPlayer(null)
        serviceScope.cancel()
        stopForeground(STOP_FOREGROUND_REMOVE)
        mediaSession?.release()
        mediaSession = null
        player.release()
        instance = null
        super.onDestroy()
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        if (!player.isPlaying) {
            stopProgressUpdates()
            stopSelf()
        }
        super.onTaskRemoved(rootIntent)
    }

    override fun onTrimMemory(level: Int) {
        super.onTrimMemory(level)
        if (level >= TRIM_MEMORY_RUNNING_LOW) {
            artworkCache.trimToSize(artworkCache.maxSize() / 2)
        }
        if (level >= TRIM_MEMORY_RUNNING_CRITICAL || level >= TRIM_MEMORY_BACKGROUND) {
            artworkCache.evictAll()
        }
        if (!player.isPlaying) {
            stopProgressUpdates()
        }
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
        private const val PROGRESS_UPDATE_MS = 1000L
        private const val NOTIFICATION_ARTWORK_SIZE = 256

        @Volatile
        private var instance: PlaybackService? = null
        private val listeners = CopyOnWriteArraySet<(Map<String, Any?>) -> Unit>()
        private var lastState: Map<String, Any?> = mapOf(
            "isPlaying" to false,
            "position" to 0L,
            "duration" to 0L,
            "playbackState" to "idle",
            "repeatMode" to "off",
            "error" to null,
        )

        fun registerPlaybackListener(listener: (Map<String, Any?>) -> Unit) {
            listeners.add(listener)
            instance?.startProgressUpdates()
        }

        fun unregisterPlaybackListener(listener: (Map<String, Any?>) -> Unit) {
            listeners.remove(listener)
            if (listeners.isEmpty()) {
                instance?.stopProgressUpdates()
            }
        }

        fun currentPlaybackState(): Map<String, Any?> = lastState

        fun isRunning(): Boolean = instance != null

        private fun playbackStateName(playbackState: Int): String {
            return when (playbackState) {
                Player.STATE_IDLE -> "idle"
                Player.STATE_BUFFERING -> "buffering"
                Player.STATE_READY -> "ready"
                Player.STATE_ENDED -> "ended"
                else -> "unknown"
            }
        }

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

    private fun startProgressUpdates() {
        mainHandler.removeCallbacks(progressRunnable)
        if (player.isPlaying && listeners.isNotEmpty()) {
            mainHandler.post(progressRunnable)
        }
    }

    private fun stopProgressUpdates() {
        mainHandler.removeCallbacks(progressRunnable)
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

                        serviceScope.launch {
                            runCatching {
                                withContext(Dispatchers.IO) {
                                    fetchScaledArtworkBitmap(artworkUri.toString(), NOTIFICATION_ARTWORK_SIZE)
                                }
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
                        if (ongoing || shouldKeepForeground()) {
                            if (!isForegroundActive) {
                                try {
                                    startForeground(notificationId, notification)
                                    isForegroundActive = true
                                } catch (error: ForegroundServiceStartNotAllowedException) {
                                    if (BuildConfig.DEBUG) {
                                        Log.w(TAG, "Foreground start not allowed", error)
                                    }
                                }
                            }
                        } else {
                            if (isForegroundActive) {
                                stopForeground(STOP_FOREGROUND_DETACH)
                                isForegroundActive = false
                            }
                        }
                    }

                    override fun onNotificationCancelled(notificationId: Int, dismissedByUser: Boolean) {
                        if (shouldKeepForeground()) {
                            return
                        }
                        stopForeground(STOP_FOREGROUND_REMOVE)
                        isForegroundActive = false
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

    private fun fetchScaledArtworkBitmap(url: String, targetSize: Int): Bitmap? {
        val request = Request.Builder()
            .url(url)
            .get()
            .build()
        artworkHttpClient.newCall(request).execute().use { response ->
            if (!response.isSuccessful) {
                return null
            }
            val bytes = response.body?.bytes() ?: return null
            val bounds = BitmapFactory.Options().apply {
                inJustDecodeBounds = true
            }
            BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
            val decodeOptions = BitmapFactory.Options().apply {
                inSampleSize = calculateInSampleSize(bounds, targetSize, targetSize)
                inPreferredConfig = Bitmap.Config.ARGB_8888
            }
            return BitmapFactory.decodeByteArray(bytes, 0, bytes.size, decodeOptions)
        }
    }

    private fun calculateInSampleSize(
        options: BitmapFactory.Options,
        reqWidth: Int,
        reqHeight: Int,
    ): Int {
        val height = options.outHeight
        val width = options.outWidth
        var inSampleSize = 1

        if (height > reqHeight || width > reqWidth) {
            var halfHeight = height / 2
            var halfWidth = width / 2

            while ((halfHeight / inSampleSize) >= reqHeight &&
                (halfWidth / inSampleSize) >= reqWidth
            ) {
                inSampleSize *= 2
            }
        }

        return inSampleSize.coerceAtLeast(1)
    }
}
