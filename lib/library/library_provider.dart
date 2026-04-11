import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database_helper.dart';
import 'library_notifier.dart';
import 'library_state.dart';

export 'library_models.dart';
export 'library_state.dart';
export 'library_notifier.dart';

final libraryProvider =
    StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  return LibraryNotifier(DatabaseHelper.instance);
});
