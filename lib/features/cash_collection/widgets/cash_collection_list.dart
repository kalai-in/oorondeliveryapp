import 'package:deliveryboy/commons/widgets/empty_state_widget.dart';
import 'package:deliveryboy/commons/widgets/paginated_list_view.dart';
import 'package:deliveryboy/core/constants/assets_constants.dart';
import 'package:deliveryboy/core/constants/theme_constants.dart';
import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/utils/extensions/context_extensions.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import '../models/cash_collection_model.dart';
import 'cash_collection_card.dart';

/// Paginated, pull-to-refresh list of cash collection entries.
class CashCollectionList extends StatelessWidget {
  final List<CashCollectionModel> collections;
  final bool isLoadingMore;
  final bool hasMore;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;

  const CashCollectionList({
    super.key,
    required this.collections,
    required this.isLoadingMore,
    required this.hasMore,
    required this.scrollController,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (collections.isEmpty) {
      return EmptyStateWidget(
        imagePath: AssetsConstants.noCaseCollectionFound,
        title: context.translate(LanguageLabelKeys.noCashCollections),
        subtitle: context.translate(LanguageLabelKeys.noCashCollectionsDesc),
      );
    }

    return PaginatedListView<CashCollectionModel>(
      items: collections,
      isLoadingMore: isLoadingMore,
      hasMore: hasMore,
      scrollController: scrollController,
      onRefresh: onRefresh,
      refreshBackgroundColor: context.cs.surface,
      refreshStrokeWidth: 2.5,
      padding: const EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingL, ThemeConstants.paddingS, ThemeConstants.paddingL, ThemeConstants.spaceXXXL),
      itemBuilder: (context, item, index) => CashCollectionCard(item: item),
    );
  }
}
