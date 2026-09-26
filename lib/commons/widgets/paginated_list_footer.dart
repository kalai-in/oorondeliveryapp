import 'package:deliveryboy/commons/widgets/loading_widget.dart';
import 'package:deliveryboy/core/constants/theme_constants.dart';
import 'package:flutter/material.dart';

/// Shows a loading spinner, an "end of list" message, or nothing at the bottom of a paginated list.
class PaginatedListFooter extends StatelessWidget {
  final bool isLoadingMore;
  final bool hasMore;

  const PaginatedListFooter({
    super.key,
    required this.isLoadingMore,
    required this.hasMore,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsetsDirectional.symmetric(vertical: ThemeConstants.paddingL),
        child: Center(child: LoadingWidget(size: ThemeConstants.loaderSize)),
      );
    }
    return const SizedBox.shrink();
  }
}
