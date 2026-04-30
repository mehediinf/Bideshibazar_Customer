// lib/presentation/widgets/image_viewer.dart

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import '../../core/utils/app_error_helper.dart';

class ImageViewer extends StatefulWidget {
  final String imageUrl;
  final String? heroTag;

  const ImageViewer({
    super.key,
    required this.imageUrl,
    this.heroTag,
  });

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  final TransformationController _transformationController = TransformationController();
  final Dio _dio = Dio();
  TapDownDetails? _doubleTapDetails;
  bool _isDownloading = false;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_doubleTapDetails == null) return;

    if (_transformationController.value != Matrix4.identity()) {
      // If zoomed in, reset to original
      _transformationController.value = Matrix4.identity();
    } else {
      // If not zoomed, zoom to 2x at tap position
      final position = _doubleTapDetails!.localPosition;
      _transformationController.value = Matrix4.identity()
        ..translateByDouble(-position.dx, -position.dy, 0, 1)
        ..scaleByDouble(2.0, 2.0, 1.0, 1.0);
    }
  }

  Future<bool> _requestDownloadPermission() async {
    if (await Gal.hasAccess()) return true;
    return Gal.requestAccess();
  }

  String _fileNameFromUrl(String imageUrl) {
    try {
      final uri = Uri.parse(imageUrl);
      final lastSegment = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
      final cleaned = lastSegment.split('?').first.trim();
      if (cleaned.isNotEmpty) {
        final dotIndex = cleaned.lastIndexOf('.');
        return dotIndex > 0 ? cleaned.substring(0, dotIndex) : cleaned;
      }
    } catch (_) {}
    return 'bideshibazar_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _downloadImage() async {
    if (_isDownloading) return;

    if (widget.imageUrl.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image URL is missing.')),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      final granted = await _requestDownloadPermission();
      if (!granted) {
        throw Exception('Permission denied. Please allow photo/storage access.');
      }

      final response = await _dio.get<List<int>>(
        widget.imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Could not download image data.');
      }

      await Gal.putImageBytes(
        Uint8List.fromList(bytes),
        name: _fileNameFromUrl(widget.imageUrl),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image saved to your gallery')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppErrorHelper.toUserMessage(
              e,
              fallback: 'Failed to download image. Please try again.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      imageUrl: widget.imageUrl,
      fit: BoxFit.contain,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorWidget: (context, url, error) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey.shade900,
          alignment: Alignment.center,
          child: const Icon(
            Icons.broken_image_outlined,
            size: 88,
            color: Colors.white54,
          ),
        );
      },
    );

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: _isDownloading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.download, color: Colors.white),
            onPressed: _isDownloading ? null : _downloadImage,
          ),
        ],
      ),
      body: GestureDetector(
        onDoubleTapDown: _handleDoubleTapDown,
        onDoubleTap: _handleDoubleTap,
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.8,
          maxScale: 4.0,
          child: SizedBox.expand(
            child: widget.heroTag != null
                ? Hero(tag: widget.heroTag!, child: image)
                : image,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Text(
            'Pinch to zoom • Double tap to zoom in/out • Drag to pan',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
