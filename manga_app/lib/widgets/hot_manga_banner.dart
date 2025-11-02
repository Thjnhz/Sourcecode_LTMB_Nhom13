// lib/widgets/hot_manga_banner.dart
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/manga.dart';

class HotMangaBanner extends StatefulWidget {
  final List<Manga> mangaList;
  final Function(String mangaId, String title) onTapManga;

  const HotMangaBanner({
    super.key,
    required this.mangaList,
    required this.onTapManga,
  });

  @override
  State<HotMangaBanner> createState() => _HotMangaBannerState();
}

class _HotMangaBannerState extends State<HotMangaBanner> {
  int _current = 0;
  final CarouselSliderController _controller = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    if (widget.mangaList.isEmpty) {
      return Container(
        height: (MediaQuery.of(context).size.width - 32) / (2 / 1),
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(child: Text('Đang tải truyện hot...')),
      );
    }

    final List<Widget> imageSliders = widget.mangaList.map((mangaItem) {
      return GestureDetector(
        onTap: () => widget.onTapManga(mangaItem.id, mangaItem.title),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5.0),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            child: CachedNetworkImage(
              imageUrl: mangaItem.coverUrl,
              fit: BoxFit.cover,
              width: 1000.0,
              placeholder: (c, url) => Container(
                color: Colors.grey[200],
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (c, url, err) => Container(
                color: Colors.grey[200],
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
        ),
      );
    }).toList();

    return Column(
      children: [
        CarouselSlider(
          items: imageSliders,
          carouselController: _controller,
          options: CarouselOptions(
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            enableInfiniteScroll: widget.mangaList.length > 2,
            aspectRatio: 2 / 1,
            enlargeCenterPage: true,
            viewportFraction: 0.8,
            onPageChanged: (index, reason) {
              setState(() {
                _current = index;
              });
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: widget.mangaList.asMap().entries.map((entry) {
            return GestureDetector(
              onTap: () => _controller.animateToPage(entry.key),
              child: Container(
                width: 8.0,
                height: 8.0,
                margin: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 4.0,
                ),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black)
                          .withOpacity(_current == entry.key ? 0.9 : 0.4),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
