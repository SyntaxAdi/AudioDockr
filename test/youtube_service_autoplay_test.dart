import 'package:audiodockr/api/youtube_service.dart';
import 'package:audiodockr/recommendations/recommendation_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  YoutubeSearchItem item({
    required String id,
    required String title,
    required String uploader,
    required int seconds,
  }) {
    return YoutubeSearchItem(
      id: id,
      url: 'https://youtube.com/watch?v=$id',
      title: title,
      uploader: uploader,
      duration: Duration(seconds: seconds),
      lowThumbnailUrl: '',
      mediumThumbnailUrl: '',
      highThumbnailUrl: '',
    );
  }

  test('selectAutoplayCandidate skips advertisement-like matches', () {
    final results = [
      item(
        id: 'ad1',
        title: 'Sponsored Promo - Artist Song',
        uploader: 'Brand Channel',
        seconds: 30,
      ),
      item(
        id: 'song1',
        title: 'Song Title',
        uploader: 'Artist Name - Topic',
        seconds: 215,
      ),
    ];

    final match = YoutubeService.selectAutoplayCandidate(
      results,
      title: 'Song Title',
      artist: 'Artist Name',
    );

    expect(match?.id, 'song1');
  });

  test('rankAutoplayCandidates de-prioritizes short clips', () {
    final results = [
      item(
        id: 'clip1',
        title: 'Song Title',
        uploader: 'Artist Name',
        seconds: 20,
      ),
      item(
        id: 'song1',
        title: 'Song Title',
        uploader: 'Artist Name',
        seconds: 205,
      ),
    ];

    final ranked = YoutubeService.rankAutoplayCandidates(
      results,
      title: 'Song Title',
      artist: 'Artist Name',
    );

    expect(ranked.first.id, 'song1');
  });

  test('youtube fallback metadata dedupes same song across channels', () {
    final a = RecommendedTrack.fromYoutubeSearchItem(
      item(
        id: 'song1',
        title: 'Ruth B. - Dandelions (Lyrics)',
        uploader: '7clouds Rock',
        seconds: 205,
      ),
    );
    final b = RecommendedTrack.fromYoutubeSearchItem(
      item(
        id: 'song2',
        title: 'Ruth B. - Dandelions (Lyrics)',
        uploader: '7clouds Chill',
        seconds: 210,
      ),
    );

    expect(a.artist, 'Ruth B.');
    expect(a.title, 'Dandelions');
    expect(a.dedupKey, b.dedupKey);
  });

  test('selectAutoplayCandidate rejects long or edited variants', () {
    final results = [
      item(
        id: 'loop1',
        title: "Car's Outside [1 Hour Version]",
        uploader: 'James Arthur',
        seconds: 3605,
      ),
      item(
        id: 'sped1',
        title: "Car's Outside (Sped Up Version)",
        uploader: 'James Arthur',
        seconds: 190,
      ),
      item(
        id: 'song1',
        title: "James Arthur - Car's Outside",
        uploader: 'James Arthur - Topic',
        seconds: 247,
      ),
    ];

    final match = YoutubeService.selectAutoplayCandidate(
      results,
      title: "Car's Outside",
      artist: 'James Arthur',
    );

    expect(match?.id, 'song1');
  });

  test('title normalization collapses long-version and translation variants',
      () {
    final a = RecommendedTrack.fromYoutubeSearchItem(
      item(
        id: 'song1',
        title: "Car's Outside [1 Hour Version]",
        uploader: 'James Arthur',
        seconds: 3605,
      ),
    );
    final b = RecommendedTrack.fromYoutubeSearchItem(
      item(
        id: 'song2',
        title: "Car's Outside / 1 hour Lyrics",
        uploader: 'James Arthur',
        seconds: 3600,
      ),
    );
    final c = RecommendedTrack.fromYoutubeSearchItem(
      item(
        id: 'song3',
        title: "Car's Outside | Lirik Terjemahan",
        uploader: 'James Arthur',
        seconds: 247,
      ),
    );

    expect(a.title, "Car's Outside");
    expect(a.dedupKey, b.dedupKey);
    expect(a.dedupKey, c.dedupKey);
  });

  test('dedupKeyFor normalizes raw seed metadata consistently', () {
    final normalized = RecommendedTrack.dedupKeyFor(
      artist: 'Ruth B.',
      title: 'Dandelions (Lyrics)',
    );
    final raw = RecommendedTrack.dedupKeyFor(
      artist: 'Ruth B.',
      title: 'Dandelions',
    );

    expect(normalized, raw);
  });

  test('dedupKeyFor strips minute-version and edit markers', () {
    final base = RecommendedTrack.dedupKeyFor(
      artist: 'Madison Beer',
      title: 'Good In Goodbye',
    );
    final minute = RecommendedTrack.dedupKeyFor(
      artist: 'Madison Beer',
      title: 'Good In Goodbye | 25 MIN',
    );
    final edit = RecommendedTrack.dedupKeyFor(
      artist: 'Madison Beer',
      title: 'Good In Goodbye [Edit Audio]',
    );

    expect(minute, base);
    expect(edit, base);
  });

  test('selectAutoplayCandidate rejects results longer than 8 minutes', () {
    final results = [
      item(
        id: 'long1',
        title: 'Artist Name - Song Title',
        uploader: 'Artist Name - Topic',
        seconds: 601,
      ),
      item(
        id: 'song1',
        title: 'Artist Name - Song Title',
        uploader: 'Artist Name - Topic',
        seconds: 245,
      ),
    ];

    final match = YoutubeService.selectAutoplayCandidate(
      results,
      title: 'Song Title',
      artist: 'Artist Name',
      maxDuration: YoutubeService.maxRecommendationDuration,
    );

    expect(match?.id, 'song1');
  });
}
