import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import '../playback/playback_url_resolver.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';

class DownloadFailure implements Exception {
  const DownloadFailure(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => message;
}

class DownloadCancellationHandle {
  HttpClient? _client;
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void attachClient(HttpClient client) {
    _client = client;
    if (_isCancelled) {
      client.close(force: true);
    }
  }

  void cancel() {
    _isCancelled = true;
    try {
      _client?.close(force: true);
    } catch (_) {
      // HttpClient.close can throw if the socket is mid-stream; safe to ignore.
    }
  }
}

class DownloadResult {
  const DownloadResult({
    required this.videoUrl,
    required this.localPath,
  });

  final String videoUrl;
  final String localPath;
}

class DownloadService {
  const DownloadService({
    required PlaybackUrlResolver resolver,
  }) : _resolver = resolver;

  final PlaybackUrlResolver _resolver;

  static Future<void> ensureDownloadPermissions() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    final status = await Permission.manageExternalStorage.status;
    if (status.isGranted) {
      return;
    }

    final requested = await Permission.manageExternalStorage.request();
    if (!requested.isGranted) {
      throw const DownloadFailure(
        'storage_permission_denied',
        'Storage access required before saving downloads to Music folder.',
      );
    }
  }

  Future<DownloadResult> downloadTrack({
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
    required String thumbnailUrl,
    required String downloadDirectoryPath,
    required DownloadCancellationHandle cancellationHandle,
    required void Function(double progress) onProgress,
  }) async {
    final resolvedMedia = await _resolver.resolveVideoUrlIfNeeded(
      videoId: videoId,
      videoUrl: videoUrl,
      title: title,
      artist: artist,
    );

    final streamUrl = await _resolver.extractTrackUrl(
      resolvedMedia.realYoutubeId,
      resolvedMedia.videoUrl,
    );
    if (streamUrl == null || streamUrl.isEmpty) {
      throw const DownloadFailure(
        'extract_empty',
        'Audio download could not be prepared for this track.',
      );
    }

    final downloadDirectory = Directory(downloadDirectoryPath);
    try {
      await downloadDirectory.create(recursive: true);
    } on FileSystemException {
      throw const DownloadFailure(
        'storage_unavailable',
        'The selected download folder could not be created or accessed.',
      );
    }

    final filePath = await _downloadStreamToFile(
      streamUrl: streamUrl,
      downloadDirectoryPath: downloadDirectory.path,
      title: title,
      artist: artist,
      thumbnailUrl: thumbnailUrl,
      cancellationHandle: cancellationHandle,
      onProgress: onProgress,
    );

    return DownloadResult(
      videoUrl: resolvedMedia.videoUrl,
      localPath: filePath,
    );
  }

  Future<String> _downloadStreamToFile({
    required String streamUrl,
    required String downloadDirectoryPath,
    required String title,
    required String artist,
    required String thumbnailUrl,
    required DownloadCancellationHandle cancellationHandle,
    required void Function(double progress) onProgress,
  }) async {
    final uri = Uri.parse(streamUrl);
    final client = HttpClient();
    cancellationHandle.attachClient(client);

    File? partFile;
    IOSink? sink;

    try {
      final request = await client.getUrl(uri);
      final headers = PlaybackUrlResolver.buildPlaybackHeaders();
      headers.forEach((key, value) {
        request.headers.set(key, value);
      });

      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw DownloadFailure(
          'download_failed',
          'Download failed with status ${response.statusCode}.',
        );
      }

      final baseName = _sanitizeFileName('$artist - $title');
      final finalPath = await _nextAvailablePath(
        directoryPath: downloadDirectoryPath,
        baseName: baseName,
        extension: 'mp3',
      );
      final partPath = '$finalPath.part';

      partFile = File(partPath);
      if (await partFile.exists()) {
        await partFile.delete();
      }

      sink = partFile.openWrite();

      var receivedBytes = 0;
      final totalBytes = response.contentLength;

      await for (final chunk in response) {
        if (cancellationHandle.isCancelled) {
          throw const DownloadFailure(
            'download_cancelled',
            'Download cancelled.',
          );
        }

        sink.add(chunk);
        receivedBytes += chunk.length;

        if (totalBytes > 0) {
          onProgress((receivedBytes / totalBytes).clamp(0, 1).toDouble());
        }
      }

      await sink.flush();
      await sink.close();
      sink = null;

      if (cancellationHandle.isCancelled) {
        throw const DownloadFailure(
          'download_cancelled',
          'Download cancelled.',
        );
      }

      final tempThumbPath = '$finalPath.jpg';
      if (thumbnailUrl.isNotEmpty) {
        try {
          final thumbReq = await client.getUrl(Uri.parse(thumbnailUrl));
          final thumbRes = await thumbReq.close();
          if (thumbRes.statusCode >= 200 && thumbRes.statusCode < 300) {
            final tFile = File(tempThumbPath);
            final tSink = tFile.openWrite();
            await tSink.addStream(thumbRes);
            await tSink.flush();
            await tSink.close();
          }
        } catch (_) {}
      }

      final args = <String>['-y', '-i', partPath];
      final hasThumb = await File(tempThumbPath).exists();
      if (hasThumb) {
        args.addAll(['-i', tempThumbPath, '-map', '0:a', '-map', '1:v', '-c:v', 'mjpeg', '-disposition:v', 'attached_pic']);
      } else {
        args.addAll(['-map', '0:a']);
      }
      
      args.addAll([
        '-c:a', 'libmp3lame',
        '-q:a', '2',
        '-id3v2_version', '3',
        '-metadata', 'title=$title',
        '-metadata', 'artist=$artist',
        finalPath,
      ]);

      final session = await FFmpegKit.executeWithArguments(args);
      final returnCode = await session.getReturnCode();
      
      if (hasThumb) {
        await File(tempThumbPath).delete();
      }
      
      if (returnCode == null || !ReturnCode.isSuccess(returnCode)) {
        final logs = await session.getLogsAsString();
        throw DownloadFailure('transcode_failed', 'FFmpeg failed code ${returnCode?.getValue()}: \n$logs');
      }

      onProgress(1);
      return finalPath;
    } on HttpException {
      if (cancellationHandle.isCancelled) {
        throw const DownloadFailure('download_cancelled', 'Download cancelled.');
      }
      throw const DownloadFailure(
        'network_error',
        'The download connection was interrupted unexpectedly.',
      );
    } on SocketException {
      if (cancellationHandle.isCancelled) {
        throw const DownloadFailure('download_cancelled', 'Download cancelled.');
      }
      throw const DownloadFailure(
        'network_error',
        'The download could not be completed because the network connection was lost.',
      );
    } on HandshakeException {
      throw const DownloadFailure(
        'network_error',
        'The download could not be completed because the secure connection failed.',
      );
    } on FileSystemException catch (error) {
      throw DownloadFailure(
        'storage_write_failed',
        error.message.isEmpty
            ? 'Audio file could not be written to selected folder.'
            : error.message,
      );
    } finally {
      await sink?.close();
      if (partFile != null && await partFile.exists()) {
        await partFile.delete();
      }
      client.close(force: true);
    }
  }

  Future<String> _nextAvailablePath({
    required String directoryPath,
    required String baseName,
    required String extension,
  }) async {
    var suffix = 0;
    while (true) {
      final candidateName = suffix == 0
          ? '$baseName.$extension'
          : '$baseName ($suffix).$extension';
      final candidatePath = '$directoryPath${Platform.pathSeparator}$candidateName';
      if (!await File(candidatePath).exists()) {
        return candidatePath;
      }
      suffix += 1;
    }
  }

  String _sanitizeFileName(String value) {
    final sanitized = value
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (sanitized.isEmpty) {
      return 'AudioDockr Track';
    }
    return sanitized;
  }
}
