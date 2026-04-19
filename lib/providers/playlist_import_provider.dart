import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../library/library_provider.dart';
import '../services/playlist_import_models.dart';
import '../services/spotify_playlist_import_service.dart';
import '../services/youtube_playlist_import_service.dart';

class PlaylistImportState {
  const PlaylistImportState({
    this.isImporting = false,
    this.errorMessage,
    this.importedPlaylistName,
    this.importSourceLabel = 'Spotify',
  });

  final bool isImporting;
  final String? errorMessage;
  final String? importedPlaylistName;
  final String importSourceLabel;

  PlaylistImportState copyWith({
    bool? isImporting,
    Object? errorMessage = _noChange,
    Object? importedPlaylistName = _noChange,
    String? importSourceLabel,
  }) {
    return PlaylistImportState(
      isImporting: isImporting ?? this.isImporting,
      errorMessage: identical(errorMessage, _noChange)
          ? this.errorMessage
          : errorMessage as String?,
      importedPlaylistName: identical(importedPlaylistName, _noChange)
          ? this.importedPlaylistName
          : importedPlaylistName as String?,
      importSourceLabel: importSourceLabel ?? this.importSourceLabel,
    );
  }
}

const Object _noChange = Object();

final playlistImportProvider =
    StateNotifierProvider<PlaylistImportNotifier, PlaylistImportState>((ref) {
  final spotifyService = ref.read(spotifyPlaylistImportServiceProvider);
  final youtubeService = ref.read(youtubePlaylistImportServiceProvider);
  final libraryNotifier = ref.read(libraryProvider.notifier);
  return PlaylistImportNotifier(
    spotifyService,
    youtubeService,
    libraryNotifier,
  );
});

class PlaylistImportNotifier extends StateNotifier<PlaylistImportState> {
  PlaylistImportNotifier(
    this._spotifyService,
    this._youtubeService,
    this._libraryNotifier,
  ) : super(const PlaylistImportState());

  final SpotifyPlaylistImportService _spotifyService;
  final YoutubePlaylistImportService _youtubeService;
  final LibraryNotifier _libraryNotifier;

  Future<void> importSpotifyPlaylist(String spotifyUrl) async {
    await _runImport(
      sourceLabel: 'Spotify',
      action: () async {
        final tracks = await _spotifyService.importPlaylist(spotifyUrl);
        return _libraryNotifier.importSpotifyPlaylist(tracks);
      },
      fallbackError: 'Unable to import this Spotify playlist right now.',
    );
  }

  Future<void> importYoutubePlaylist(String youtubeUrl) async {
    await _runImport(
      sourceLabel: 'YouTube',
      action: () async {
        final tracks = await _youtubeService.importPlaylist(youtubeUrl);
        return _libraryNotifier.importYoutubePlaylist(tracks);
      },
      fallbackError: 'Unable to import this YouTube playlist right now.',
    );
  }

  Future<void> _runImport({
    required String sourceLabel,
    required Future<String> Function() action,
    required String fallbackError,
  }) async {
    if (state.isImporting) {
      return;
    }

    state = state.copyWith(
      isImporting: true,
      errorMessage: null,
      importedPlaylistName: null,
      importSourceLabel: sourceLabel,
    );

    try {
      final playlistName = await action();
      state = state.copyWith(
        isImporting: false,
        errorMessage: null,
        importedPlaylistName: playlistName,
      );
    } on PlaylistImportException catch (error) {
      state = state.copyWith(
        isImporting: false,
        errorMessage: error.message,
        importedPlaylistName: null,
      );
    } catch (_) {
      state = state.copyWith(
        isImporting: false,
        errorMessage: fallbackError,
        importedPlaylistName: null,
      );
    }
  }
}
