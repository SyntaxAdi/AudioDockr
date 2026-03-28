package com.akeno.audiodockr

import android.util.Log
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.schabi.newpipe.extractor.NewPipe
import org.schabi.newpipe.extractor.downloader.Downloader
import org.schabi.newpipe.extractor.downloader.Request as NPRequest
import org.schabi.newpipe.extractor.downloader.Response
import org.schabi.newpipe.extractor.exceptions.AgeRestrictedContentException
import org.schabi.newpipe.extractor.exceptions.ContentNotAvailableException
import org.schabi.newpipe.extractor.exceptions.ExtractionException
import org.schabi.newpipe.extractor.exceptions.PrivateContentException
import org.schabi.newpipe.extractor.exceptions.ReCaptchaException
import org.schabi.newpipe.extractor.stream.AudioStream
import org.schabi.newpipe.extractor.stream.StreamInfo
import java.io.IOException
import java.util.concurrent.atomic.AtomicBoolean

data class ExtractorFailure(
    val code: String,
    val message: String,
)

private class AudiodockrDownloader : Downloader() {
    private val client = OkHttpClient()

    override fun execute(request: NPRequest): Response {
        val builder = Request.Builder()
            .url(request.url())
            .addHeader(
                "User-Agent",
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36",
            )

        request.headers().forEach { (name, values) ->
            values.forEach { value ->
                builder.addHeader(name, value)
            }
        }

        val method = request.httpMethod()
        val body = request.dataToSend()?.toRequestBody()
        builder.method(method, if (method == "GET" || method == "HEAD") null else body)

        val response = client.newCall(builder.build()).execute()
        val bodyText = response.body?.string().orEmpty()

        if (response.code == 429) {
            response.close()
            throw ReCaptchaException("YouTube is rate limiting playback requests.", request.url())
        }

        return Response(
            response.code,
            response.message,
            response.headers.toMultimap(),
            bodyText,
            response.request.url.toString(),
        )
    }
}

object YoutubeAudioExtractor {
    private const val TAG = "YoutubeAudioExtractor"
    private val initialized = AtomicBoolean(false)

    fun extract(videoId: String, videoUrl: String): Result<String> = runCatching {
        ensureInitialized()

        val targetCandidates = buildTargetCandidates(videoId = videoId, videoUrl = videoUrl)
        var lastError: Throwable? = null

        for (targetUrl in targetCandidates) {
            try {
                Log.d(TAG, "Trying stream extraction for $targetUrl")
                val streamInfo = StreamInfo.getInfo(NewPipe.getService(0), targetUrl)
                Log.d(
                    TAG,
                    "Stream info loaded. audio=${streamInfo.audioStreams.size}, video=${streamInfo.videoStreams.size}, videoOnly=${streamInfo.videoOnlyStreams.size}",
                )

                pickBestAudioStream(streamInfo.audioStreams)?.content?.takeIf { it.isNotBlank() }?.let {
                    Log.d(TAG, "Selected audio stream for ${streamInfo.id}")
                    return@runCatching it
                }

                streamInfo.videoStreams
                    .firstOrNull { !it.content.isNullOrBlank() }
                    ?.content
                    ?.takeIf { it.isNotBlank() }
                    ?.let {
                        Log.d(TAG, "Falling back to muxed stream for ${streamInfo.id}")
                        return@runCatching it
                    }
            } catch (error: Throwable) {
                lastError = error
                Log.e(TAG, "Extraction failed for $targetUrl: ${error.message}", error)
            }
        }

        throw lastError ?: ExtractionException("No playable stream was found.")
    }

    fun mapError(error: Throwable): ExtractorFailure {
        return when (error) {
            is ReCaptchaException -> ExtractorFailure(
                code = "rate_limited",
                message = "YouTube is rate limiting playback requests right now. Try again soon.",
            )
            is AgeRestrictedContentException -> ExtractorFailure(
                code = "extract_failed",
                message = "This track is age restricted and could not be played.",
            )
            is PrivateContentException, is ContentNotAvailableException -> ExtractorFailure(
                code = "extract_failed",
                message = "This track is not available for playback.",
            )
            is IOException -> ExtractorFailure(
                code = "temporary_unavailable",
                message = "Playback is temporarily unavailable. Please try again.",
            )
            else -> ExtractorFailure(
                code = "extract_failed",
                message = buildString {
                    append("Unable to prepare audio playback for this track.")
                    error.message?.takeIf { it.isNotBlank() }?.let {
                        append(" ")
                        append(it)
                    }
                },
            )
        }
    }

    private fun ensureInitialized() {
        if (initialized.compareAndSet(false, true)) {
            NewPipe.init(AudiodockrDownloader())
        }
    }

    private fun pickBestAudioStream(streams: List<AudioStream>): AudioStream? {
        return streams
            .filter { stream -> !stream.content.isNullOrBlank() }
            .sortedWith(
                compareByDescending<AudioStream> { stream ->
                    stream.bitrate
                }.thenByDescending { stream ->
                    when {
                        stream.format?.name.equals("M4A", ignoreCase = true) -> 3
                        stream.format?.name.equals("WEBMA", ignoreCase = true) -> 2
                        else -> 1
                    }
                },
            )
            .firstOrNull()
    }

    private fun buildTargetCandidates(videoId: String, videoUrl: String): List<String> {
        val candidates = linkedSetOf<String>()

        if (videoUrl.isNotBlank()) {
            candidates += videoUrl
            if (videoUrl.contains("music.youtube.com")) {
                candidates += videoUrl.replace("music.youtube.com", "www.youtube.com")
            } else if (videoUrl.contains("www.youtube.com")) {
                candidates += videoUrl.replace("www.youtube.com", "music.youtube.com")
            }
        }

        if (videoId.isNotBlank()) {
            candidates += "https://www.youtube.com/watch?v=$videoId"
            candidates += "https://music.youtube.com/watch?v=$videoId"
            candidates += "https://youtu.be/$videoId"
        }

        if (candidates.isEmpty()) {
            throw IllegalArgumentException("Missing video identifier.")
        }

        return candidates.toList()
    }
}
