import 'dart:async';
import 'package:sqflite/sqflite.dart';

import 'database/database_manager.dart';
import 'database/track_repository.dart';
import 'database/playlist_repository.dart';
import 'database/playlist_track_repository.dart';
import 'database/search_history_repository.dart';
import 'database/models.dart';

export 'database/models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  late final DatabaseManager _dbManager;
  late final TrackRepository _trackRepo;
  late final PlaylistRepository _playlistRepo;
  late final PlaylistTrackRepository _playlistTrackRepo;
  late final SearchHistoryRepository _searchHistoryRepo;

  DatabaseHelper._init() {
    _dbManager = DatabaseManager.instance;
    _trackRepo = TrackRepository(_dbManager);
    _playlistRepo = PlaylistRepository(_dbManager);
    _playlistTrackRepo = PlaylistTrackRepository(_dbManager, _trackRepo);
    _searchHistoryRepo = SearchHistoryRepository(_dbManager);
  }

  Future<Database> get database => _dbManager.database;

  Future<String> createPlaylist(String name) =>
      _playlistRepo.createPlaylist(name);

  Future<void> updatePlaylist({
    required String playlistId,
    required String name,
    required String coverImagePath,
  }) =>
      _playlistRepo.updatePlaylist(
        playlistId: playlistId,
        name: name,
        coverImagePath: coverImagePath,
      );

  Future<void> togglePinPlaylist(String playlistId, bool isPinned) =>
      _playlistRepo.togglePinPlaylist(playlistId, isPinned);

  Future<bool> addTrackToPlaylist({
    required String playlistId,
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
    required String thumbnailUrl,
    required int durationSeconds,
  }) =>
      _playlistTrackRepo.addTrackToPlaylist(
        playlistId: playlistId,
        videoId: videoId,
        videoUrl: videoUrl,
        title: title,
        artist: artist,
        thumbnailUrl: thumbnailUrl,
        durationSeconds: durationSeconds,
      );

  Future<void> removeTrackFromPlaylist({
    required String playlistId,
    required String videoId,
  }) =>
      _playlistTrackRepo.removeTrackFromPlaylist(
        playlistId: playlistId,
        videoId: videoId,
      );

  Future<void> setTrackHiddenInPlaylist({
    required String playlistId,
    required String videoId,
    required bool hidden,
  }) =>
      _playlistTrackRepo.setTrackHiddenInPlaylist(
        playlistId: playlistId,
        videoId: videoId,
        hidden: hidden,
      );

  Future<void> deletePlaylist(String playlistId) =>
      _playlistRepo.deletePlaylist(playlistId);

  Future<Set<String>> fetchPlaylistIdsForTrack(String videoId) =>
      _playlistTrackRepo.fetchPlaylistIdsForTrack(videoId);

  Future<void> saveTrack({
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
    required String thumbnailUrl,
    required int durationSeconds,
  }) =>
      _trackRepo.saveTrack(
        videoId: videoId,
        videoUrl: videoUrl,
        title: title,
        artist: artist,
        thumbnailUrl: thumbnailUrl,
        durationSeconds: durationSeconds,
      );

  Future<void> addTracksToPlaylistBulk({
    required String playlistId,
    required List<TrackWriteData> tracks,
  }) =>
      _playlistTrackRepo.addTracksToPlaylistBulk(
        playlistId: playlistId,
        tracks: tracks,
      );

  Future<void> updateTrackVideoUrl({
    required String videoId,
    required String videoUrl,
  }) =>
      _trackRepo.updateTrackVideoUrl(
        videoId: videoId,
        videoUrl: videoUrl,
      );

  Future<void> setTrackReaction({
    required String videoId,
    required String videoUrl,
    required String title,
    required String artist,
    required String thumbnailUrl,
    required int durationSeconds,
    required String reaction,
  }) =>
      _trackRepo.setTrackReaction(
        videoId: videoId,
        videoUrl: videoUrl,
        title: title,
        artist: artist,
        thumbnailUrl: thumbnailUrl,
        durationSeconds: durationSeconds,
        reaction: reaction,
      );

  Future<List<StoredTrack>> fetchAllTracks() => _trackRepo.fetchAllTracks();

  Future<List<StoredTrack>> fetchLikedTracks() => _trackRepo.fetchLikedTracks();

  Future<List<StoredTrack>> fetchPlaylistTracks(String playlistId) =>
      _playlistTrackRepo.fetchPlaylistTracks(playlistId);

  Future<List<StoredTrack>> fetchRecentlyPlayed({int? limit}) =>
      _trackRepo.fetchRecentlyPlayed(limit: limit);

  Future<void> recordPlaylistOpened(String playlistId) =>
      _playlistRepo.recordPlaylistOpened(playlistId);

  Future<List<StoredPlaylist>> fetchRecentlyOpenedPlaylists({int? limit}) =>
      _playlistRepo.fetchRecentlyOpenedPlaylists(limit: limit);

  Future<List<StoredPlaylist>> fetchPlaylists() => _playlistRepo.fetchPlaylists();

  Future<void> saveSearchQuery(String query) =>
      _searchHistoryRepo.saveSearchQuery(query);

  Future<List<String>> fetchSearchHistory({int limit = 12}) =>
      _searchHistoryRepo.fetchSearchHistory(limit: limit);
}
