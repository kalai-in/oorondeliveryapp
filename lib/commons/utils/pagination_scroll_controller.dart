import 'package:flutter/widgets.dart';

/// Wraps a [ScrollController] with a near-bottom listener that fires
/// [onLoadMore] once the user scrolls within [threshold] px of the end.
/// Create in `initState` (needs `context`/cubit access in [onLoadMore]),
/// dispose in `dispose`.
class PaginationScrollController {
  final ScrollController controller = ScrollController();
  final VoidCallback onLoadMore;
  final double threshold;

  PaginationScrollController({required this.onLoadMore, this.threshold = 150}) {
    controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (controller.position.pixels >=
        controller.position.maxScrollExtent - threshold) {
      onLoadMore();
    }
  }

  void dispose() => controller.dispose();
}
