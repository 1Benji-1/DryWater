import 'package:flutter/material.dart';

class ImageUploadGrid extends StatelessWidget {
  final List<String> imageUrls;

  const ImageUploadGrid({
    super.key,
    this.imageUrls = const [],
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return const Center(child: Text('Sin imágenes seleccionadas.'));
    }

    return GridView.builder(
      shrinkWrap: true,
      itemCount: imageUrls.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
      ),
      itemBuilder: (context, index) {
        return Image.network(imageUrls[index], fit: BoxFit.cover);
      },
    );
  }
}
