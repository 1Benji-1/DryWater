import 'package:flutter/material.dart';

import '../../../properties/domain/entities/property.dart';

class MatchCard extends StatelessWidget {
  final Property property;
  final VoidCallback? onTap;

  const MatchCard({
    super.key,
    required this.property,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(property.title),
      subtitle: Text('${property.price} ${property.currency}'),
    );
  }
}
