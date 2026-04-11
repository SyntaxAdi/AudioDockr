import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: bgBase,
        elevation: 0,
        title: Text('DOWNLOADS', style: Theme.of(context).textTheme.displayLarge),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                _buildSectionHeader('ACTIVE DOWNLOADS'),
                _buildActiveDownloadItem(context),
                _buildSectionHeader('COMPLETED'),
                _buildCompletedItem(context),
              ],
            ),
          ),
          _buildStorageInfoBar(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.12),
      ),
    );
  }

  Widget _buildActiveDownloadItem(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      color: bgCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Downloading Track Title...', style: Theme.of(context).textTheme.bodyLarge),
          Text('UPLOADER', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 2,
                  color: bgDivider,
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(widthFactor: 0.47, child: Container(color: accentPrimary)),
                ),
              ),
              const SizedBox(width: 16),
              const Text('47%', style: TextStyle(color: accentPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: accentRed),
              foregroundColor: accentRed,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: const Text('CANCEL'),
          )
        ],
      ),
    );
  }

  Widget _buildCompletedItem(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
         children: [
           Container(width: 56, height: 56, color: bgDivider),
           const SizedBox(width: 16),
           Expanded(
             child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Completed Track Title', style: Theme.of(context).textTheme.bodyLarge),
                  Text('ARTIST', style: Theme.of(context).textTheme.labelSmall),
                ],
             ),
           ),
         ],
      ),
    );
  }

  Widget _buildStorageInfoBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: bgSurface,
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('USED: 2.3 GB', style: TextStyle(fontSize: 11, color: textPrimary)),
              Text('DEVICE STORAGE', style: TextStyle(fontSize: 11, color: textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            color: bgDivider,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(widthFactor: 0.6, child: Container(color: accentPrimary)),
          )
        ],
      ),
    );
  }
}
