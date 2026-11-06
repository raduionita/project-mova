import 'package:flutter/material.dart';

import 'app_tag.dart';

/// Gold personal record badge used on the workout summary.
class PrBadge extends StatelessWidget {
  const PrBadge({super.key, this.label = 'NEW PR'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return AppTag(label: label, variant: AppTagVariant.gold);
  }
}
