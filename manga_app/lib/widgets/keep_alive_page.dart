// lib/widgets/keep_alive_page.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class KeepAlivePage extends StatefulWidget {
  final String imageUrl;

  const KeepAlivePage({required this.imageUrl, Key? key}) : super(key: key);

  @override
  State<KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 4.0,
      child: CachedNetworkImage(
        imageUrl: widget.imageUrl,
        fit: BoxFit.contain,
        placeholder: (context, url) => Container(
          height: 300,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => Container(
          height: 300,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
        // Nếu muốn giới hạn bộ nhớ cache:
        // memCacheWidth: 1200,
        // memCacheHeight: 1800,
      ),
    );
  }
}
