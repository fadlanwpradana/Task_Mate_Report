import 'package:flutter/material.dart';

class PostImageGallery extends StatefulWidget {
  const PostImageGallery({required this.imageUrls, super.key});

  final List<String> imageUrls;

  @override
  State<PostImageGallery> createState() => _PostImageGalleryState();
}

class _PostImageGalleryState extends State<PostImageGallery> {
  var _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                itemCount: widget.imageUrls.length,
                onPageChanged: (page) => setState(() => _currentPage = page),
                itemBuilder: (context, index) => _PostNetworkImage(
                  url: widget.imageUrls[index],
                  onTap: () => _openViewer(context, index),
                ),
              ),
              if (widget.imageUrls.length > 1)
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: Text(
                        '${_currentPage + 1}/${widget.imageUrls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openViewer(BuildContext context, int initialPage) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PostImageViewer(
          imageUrls: widget.imageUrls,
          initialPage: initialPage,
        ),
      ),
    );
  }
}

class _PostNetworkImage extends StatelessWidget {
  const _PostNetworkImage({required this.url, this.onTap});

  final String url;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            final total = progress.expectedTotalBytes;
            return Center(
              child: CircularProgressIndicator(
                value: total == null
                    ? null
                    : progress.cumulativeBytesLoaded / total,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) =>
              const Center(child: Icon(Icons.broken_image_outlined, size: 40)),
        ),
      ),
    );
  }
}

class _PostImageViewer extends StatefulWidget {
  const _PostImageViewer({required this.imageUrls, required this.initialPage});

  final List<String> imageUrls;
  final int initialPage;

  @override
  State<_PostImageViewer> createState() => _PostImageViewerState();
}

class _PostImageViewerState extends State<_PostImageViewer> {
  late final PageController _controller = PageController(
    initialPage: widget.initialPage,
  );
  late var _currentPage = widget.initialPage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentPage + 1}/${widget.imageUrls.length}'),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.imageUrls.length,
        onPageChanged: (page) => setState(() => _currentPage = page),
        itemBuilder: (context, index) => Center(
          child: InteractiveViewer(
            child: Image.network(
              widget.imageUrls[index],
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const CircularProgressIndicator(color: Colors.white);
              },
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.broken_image_outlined,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
