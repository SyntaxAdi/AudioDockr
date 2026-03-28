package com.akeno.audiodockr

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Handler
import android.os.Looper
import java.util.concurrent.Executors

class MainActivity : AudioServiceActivity() {
    private val mainHandler = Handler(Looper.getMainLooper())
    private val extractorExecutor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

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

    override fun onDestroy() {
        extractorExecutor.shutdown()
        super.onDestroy()
    }
}
