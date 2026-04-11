import '../api/youtube_service.dart';
import 'playback_models.dart';

abstract final class PlaybackErrorMapper {
  static PlaybackFailure fromSearchError(YoutubeServiceException error) {
    switch (error.code) {
      case 'no_results':
        return const PlaybackFailure(
          'no_results',
          'No YouTube result was found for this imported Spotify track.',
        );
      case 'temporary_unavailable':
        return const PlaybackFailure(
          'temporary_unavailable',
          'YouTube is temporarily unavailable. Please try again in a moment.',
        );
      case 'rate_limited':
        return const PlaybackFailure(
          'rate_limited',
          'YouTube is rate limiting search requests right now. Try again soon.',
        );
      default:
        return PlaybackFailure(error.code, error.message);
    }
  }

  static PlaybackFailure fromExtractError(YoutubeServiceException error) {
    switch (error.code) {
      case 'temporary_unavailable':
        return const PlaybackFailure(
          'temporary_unavailable',
          'YouTube is temporarily unavailable. Please try playing this track again.',
        );
      case 'rate_limited':
        return const PlaybackFailure(
          'rate_limited',
          'YouTube is rate limiting playback requests right now. Try again soon.',
        );
      case 'unsupported_response':
        return const PlaybackFailure(
          'unsupported_response',
          'YouTube returned an unsupported playback response.',
        );
      case 'extract_failed':
        return const PlaybackFailure(
          'extract_failed',
          'Unable to prepare audio playback for this track.',
        );
      default:
        return PlaybackFailure(error.code, error.message);
    }
  }
}
