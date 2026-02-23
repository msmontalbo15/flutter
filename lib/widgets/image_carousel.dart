import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  final double height;
  final BorderRadius? borderRadius;

  const ImageCarousel({
    super.key,
    required this.imageUrls,
    this.height = 200,
    this.borderRadius,
  });

  @override
  State<ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<ImageCarousel> {
  int _current = 0;
  final CarouselSliderController _controller = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) return const SizedBox.shrink();
    if (widget.imageUrls.length == 1) {
      return ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
        child: Image.network(
          widget.imageUrls.first,
          height: widget.height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.zero,
          child: CarouselSlider(
            carouselController: _controller, // 👈 attach controller
            options: CarouselOptions(
              height: widget.height,
              viewportFraction: 1.0,
              enableInfiniteScroll: false,
              onPageChanged: (index, reason) {
                setState(() => _current = index);
              },
            ),
            items: widget.imageUrls.map((url) {
              return Image.network(
                url,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(
                    Icons.broken_image,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // ◀ Left arrow
        if (_current > 0)
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: _ArrowButton(
                icon: Icons.chevron_left,
                onTap: () => _controller.previousPage(),
              ),
            ),
          ),

        // ▶ Right arrow
        if (_current < widget.imageUrls.length - 1)
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: _ArrowButton(
                icon: Icons.chevron_right,
                onTap: () => _controller.nextPage(),
              ),
            ),
          ),

        // Dot indicators
        Positioned(
          bottom: 8,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: widget.imageUrls.asMap().entries.map((entry) {
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(
                    alpha: _current == entry.key ? 0.9 : 0.4,
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Image counter badge
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_current + 1}/${widget.imageUrls.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: const Color.fromARGB(255, 255, 255, 255),
          size: 20,
        ),
      ),
    );
  }
}
