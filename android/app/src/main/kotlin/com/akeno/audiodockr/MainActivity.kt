package com.akeno.audiodockr

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import okhttp3.OkHttpClient
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import org.schabi.newpipe.extractor.Image
import org.schabi.newpipe.extractor.InfoItem
import org.schabi.newpipe.extractor.NewPipe
import org.schabi.newpipe.extractor.ServiceList
import org.schabi.newpipe.extractor.StreamingService
import org.schabi.newpipe.extractor.downloader.Downloader
import org.schabi.newpipe.extractor.downloader.Request
import org.schabi.newpipe.extractor.downloader.Response
import org.schabi.newpipe.extractor.exceptions.ReCaptchaException
import org.schabi.newpipe.extractor.localization.ContentCountry
import org.schabi.newpipe.extractor.localization.Localization
import org.schabi.newpipe.extractor.stream.StreamInfo
import org.schabi.newpipe.extractor.stream.StreamInfoItem
import java.util.Locale
import java.util.concurrent.TimeUnit

class MainActivity : AudioServiceActivity() {
    private val searchChannel = "audiodockr/search"
    private val extractChannel = "audiodockr/extract"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        AndroidYoutubeBridge.ensureInitialized()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, searchChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "search") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val query = call.argument<String>("query")
                if (query.isNullOrBlank()) {
                    result.error("INVALID_ARGUMENT", "Query is null", null)
                    return@setMethodCallHandler
                }

                CoroutineScope(Dispatchers.IO).launch {
                    runCatching { AndroidYoutubeBridge.search(query) }
                        .onSuccess { rows ->
                            launch(Dispatchers.Main) {
                                result.success(rows)
                            }
                        }
                        .onFailure { error ->
                            launch(Dispatchers.Main) {
                                result.error("SEARCH_FAILED", error.message, null)
                            }
                        }
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, extractChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "extract") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }

                val videoUrl = call.argument<String>("video_url")
                val videoId = call.argument<String>("video_id")
                val target = videoUrl ?: videoId

                if (target.isNullOrBlank()) {
                    result.error("INVALID_ARGUMENT", "Video URL is null", null)
                    return@setMethodCallHandler
                }

                CoroutineScope(Dispatchers.IO).launch {
                    runCatching { AndroidYoutubeBridge.extractAudioUrl(target) }
                        .onSuccess { audioUrl ->
                            launch(Dispatchers.Main) {
                                result.success(audioUrl)
                            }
                        }
                        .onFailure { error ->
                            launch(Dispatchers.Main) {
                                result.error("EXTRACT_FAILED", error.message, null)
                            }
                        }
                }
            }
    }
}

private object AndroidYoutubeBridge {
    @Volatile
    private var initialized = false

    @Synchronized
    fun ensureInitialized() {
        if (initialized) {
            return
        }

        val locale = Locale.getDefault()
        val countryCode = locale.country.ifBlank { "US" }
        NewPipe.init(
            AndroidDownloader(),
            Localization.fromLocale(locale),
            ContentCountry(countryCode),
        )
        initialized = true
    }

    fun search(query: String): List<String> {
        ensureInitialized()
        val extractor = youtubeService().getSearchExtractor(query)
        val page = extractor.initialPage
        return page.items.mapNotNull(::toSearchRow)
    }

    fun extractAudioUrl(videoUrlOrId: String): String {
        ensureInitialized()
        val info = StreamInfo.getInfo(youtubeService(), normalizeYoutubeUrl(videoUrlOrId))
        val bestAudioUrl = info.audioStreams
            .mapNotNull { stream ->
                stream.url?.takeIf { it.isNotBlank() }?.let { url ->
                    url to stream.averageBitrate
                }
            }
            .maxByOrNull { it.second }
            ?.first

        return when {
            bestAudioUrl != null -> bestAudioUrl
            !info.hlsUrl.isNullOrBlank() -> info.hlsUrl!!
            !info.dashMpdUrl.isNullOrBlank() -> info.dashMpdUrl!!
            else -> throw IllegalStateException("No playable audio stream was found.")
        }
    }

    private fun youtubeService(): StreamingService {
        return ServiceList.YouTube
    }

    private fun toSearchRow(item: InfoItem): String? {
        if (item.infoType != InfoItem.InfoType.STREAM || item !is StreamInfoItem) {
            return null
        }

        return JSONObject().apply {
            put("id", extractVideoId(item.url))
            put("url", item.url)
            put("title", item.name)
            put("uploader", item.uploaderName)
            put("duration", item.duration)
            put("thumbnails", item.thumbnails.toJsonArray())
        }.toString()
    }

    private fun List<Image>.toJsonArray(): JSONArray {
        val array = JSONArray()
        forEach { image ->
            array.put(
                JSONObject().apply {
                    put("url", image.url)
                },
            )
        }
        return array
    }

    private fun normalizeYoutubeUrl(videoUrlOrId: String): String {
        return if (
            videoUrlOrId.startsWith("http://") || videoUrlOrId.startsWith("https://")
        ) {
            videoUrlOrId
        } else {
            "https://www.youtube.com/watch?v=$videoUrlOrId"
        }
    }

    private fun extractVideoId(url: String): String {
        val regex = Regex("""(?:v=|/)([0-9A-Za-z_-]{11})(?:[?&/]|$)""")
        return regex.find(url)?.groupValues?.getOrNull(1) ?: url
    }
}

private class AndroidDownloader : Downloader() {
    private val client = OkHttpClient.Builder()
        .readTimeout(30, TimeUnit.SECONDS)
        .build()

    override fun execute(request: Request): Response {
        val requestBody = request.dataToSend()?.toRequestBody()
        val requestBuilder = okhttp3.Request.Builder()
            .url(request.url())
            .method(request.httpMethod(), requestBody)
            .addHeader(
                "User-Agent",
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:140.0) Gecko/20100101 Firefox/140.0",
            )

        request.headers().forEach { (headerName, headerValues) ->
            requestBuilder.removeHeader(headerName)
            headerValues.forEach { headerValue ->
                requestBuilder.addHeader(headerName, headerValue)
            }
        }

        client.newCall(requestBuilder.build()).execute().use { response ->
            if (response.code == 429) {
                throw ReCaptchaException("reCaptcha challenge requested", request.url())
            }

            return Response(
                response.code,
                response.message,
                response.headers.toMultimap(),
                response.body?.string().orEmpty(),
                response.request.url.toString(),
            )
        }
    }
}
