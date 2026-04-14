import 'package:flutter/material.dart';

import '../../library/library_provider.dart';
import 'library_track_row.dart';

class LibraryPlaylistTrackList extends StatelessWidget {
  const LibraryPlaylistTrackList({
    super.key,
    required this.tracks,
    this.enableQueueActions = false,
  });

  final List<LibraryTrack> tracks;
  final bool enableQueueActions;

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return Center(
        child: Text(
          'NO TRACKS YET',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      );
    }

    return ListView.builder(
      itemExtent: 60,
      itemCount: tracks.length,
      itemBuilder: (context, index) {
        final track = tracks[index];
        return SizedBox(
          height: 60,
          child: LibraryTrackRow(
            track: track,
            enableQueueActions: enableQueueActions,
          ),
        );
      },
    );
  }
}
