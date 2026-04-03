import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/spotify_import_service.dart';
import 'library_provider.dart';

class SpotifyImportState {
  const SpotifyImportState({
    this.isImporting = false,
    this.errorMessage,
    this.importedPlaylistName,
  });

  final bool isImporting;
  final String? errorMessage;
  final String? importedPlaylistName;

  SpotifyImportState copyWith({
    bool? isImporting,
    Object? errorMessage = _spotifyImportNoChange,
    Object? importedPlaylistName = _spotifyImportNoChange,
  }) {
    return SpotifyImportState(
      isImporting: isImporting ?? this.isImporting,
      errorMessage: identical(errorMessage, _spotifyImportNoChange)
          ? this.errorMessage
          : errorMessage as String?,
      importedPlaylistName: identical(importedPlaylistName, _spotifyImportNoChange)
          ? this.importedPlaylistName
          : importedPlaylistName as String?,
    );
  }
}

const Object _spotifyImportNoChange = Object();

final spotifyImportProvider =
    StateNotifierProvider<SpotifyImportNotifier, SpotifyImportState>((ref) {
  final service = ref.read(spotifyImportServiceProvider);
  final libraryNotifier = ref.read(libraryProvider.notifier);
  return SpotifyImportNotifier(service, libraryNotifier);
});

class SpotifyImportNotifier extends StateNotifier<SpotifyImportState> {
  SpotifyImportNotifier(this._service, this._libraryNotifier)
      : super(const SpotifyImportState());

  final SpotifyImportService _service;
  final LibraryNotifier _libraryNotifier;

  Future<void> importPlaylist(String spotifyUrl) async {
    if (state.isImporting) {
      return;
    }

    state = state.copyWith(
      isImporting: true,
      errorMessage: null,
      importedPlaylistName: null,
    );

    try {
      final tracks = await _service.importPlaylist(spotifyUrl);
      final playlistName = await _libraryNotifier.importSpotifyPlaylist(tracks);
      state = state.copyWith(
        isImporting: false,
        errorMessage: null,
        importedPlaylistName: playlistName,
      );
    } on SpotifyImportException catch (error) {
      state = state.copyWith(
        isImporting: false,
        errorMessage: error.message,
        importedPlaylistName: null,
      );
    } catch (_) {
      state = state.copyWith(
        isImporting: false,
        errorMessage: 'Unable to import this Spotify playlist right now.',
        importedPlaylistName: null,
      );
    }
  }
}
