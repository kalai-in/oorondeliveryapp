import 'package:deliveryboy/commons/animations/slide_animation.dart';
import 'package:deliveryboy/commons/cubit/connectivity_cubit.dart';
import 'package:deliveryboy/commons/utils/debouncer.dart';
import 'package:deliveryboy/commons/utils/pagination_scroll_controller.dart';
import 'package:deliveryboy/commons/widgets/app_button.dart';
import 'package:deliveryboy/commons/widgets/app_date_range_picker.dart';
import 'package:deliveryboy/commons/widgets/app_scaffold.dart';
import 'package:deliveryboy/commons/widgets/app_svg_icon.dart';
import 'package:deliveryboy/commons/widgets/app_text.dart';
import 'package:deliveryboy/commons/widgets/custom_app_bar.dart';
import 'package:deliveryboy/commons/widgets/app_no_internet_widget.dart';
import 'package:deliveryboy/commons/widgets/date_range_filter_field.dart';
import 'package:deliveryboy/commons/widgets/empty_state_widget.dart';
import 'package:deliveryboy/core/constants/assets_constants.dart';
import 'package:deliveryboy/core/constants/navigation_service.dart';
import 'package:deliveryboy/core/constants/theme_constants.dart';
import 'package:deliveryboy/core/theme/app_decorations.dart';
import 'package:deliveryboy/core/theme/app_spacing.dart';
import 'package:deliveryboy/utils/extensions/size_extensions.dart';
import 'package:deliveryboy/utils/extensions/string_extensions.dart';
import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/utils/extensions/context_extensions.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:deliveryboy/utils/show_app_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/cash_collection_cubit.dart';
import '../widgets/cash_collection_list.dart';
import '../widgets/cash_collection_summary_card.dart';
import '../../../commons/widgets/list_skeleton_loader.dart';

/// Screen showing cash-in-hand summary and paginated cash collection history.
class CashCollectionScreen extends StatefulWidget {
  const CashCollectionScreen({super.key});

  @override
  State<CashCollectionScreen> createState() => _CashCollectionScreenState();
}

class _CashCollectionScreenState extends State<CashCollectionScreen> {
  final _searchController = TextEditingController();
  late final PaginationScrollController _scrollController;
  final _debounce = Debouncer();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    context.read<CashCollectionCubit>().loadCollections();
    _scrollController = PaginationScrollController(
      onLoadMore: () => context.read<CashCollectionCubit>().loadMore(),
    );
  }

  @override
  void dispose() {
    _debounce.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce(() {
      final cubit = context.read<CashCollectionCubit>();
      cubit.updateFilters(
        search: value.trim(),
        startDate: cubit.startDate,
        endDate: cubit.endDate,
      );
    });
  }

  void _clearFilters() {
    _debounce.cancel();
    _searchController.clear();
    context.read<CashCollectionCubit>().clearFilters();
  }

  void _showFilterSheet() {
    final cubit = context.read<CashCollectionCubit>();
    var tempStartDate = cubit.startDate;
    var tempEndDate = cubit.endDate;

    showAppBottomSheet(
      context,
      title: context.translate(LanguageLabelKeys.filters),
      padding: const EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingXL, ThemeConstants.paddingM, ThemeConstants.paddingXL, ThemeConstants.paddingXXL),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return SlideAnimationList(
            crossAxisAlignment: .start,
            children: [
              AppText(
                ctx.translate(LanguageLabelKeys.dateRange),
                style: ctx.tt.labelLarge,
              ),
              AppSpacing.h8,
              DateRangeFilterField(
                startDate: tempStartDate,
                endDate: tempEndDate,
                onTap: () async {
                  final now = DateTime.now();
                  final range = await showAppDateRangePicker(
                    context: ctx,
                    firstDate: DateTime(now.year - 2),
                    lastDate: now,
                    initialDateRange:
                        tempStartDate != null && tempEndDate != null
                        ? DateTimeRange(
                            start: DateTime.parse(tempStartDate!),
                            end: DateTime.parse(tempEndDate!),
                          )
                        : null,
                  );
                  if (range == null) return;
                  setSheetState(() {
                    tempStartDate = range.start.toApiDateString();
                    tempEndDate = range.end.toApiDateString();
                  });
                },
                onClear: () => setSheetState(() {
                  tempStartDate = null;
                  tempEndDate = null;
                }),
              ),
              AppSpacing.h28,
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: ctx.translate(LanguageLabelKeys.clear),
                      variant: AppButtonVariant.outline,
                      height: ctx.heightFraction(0.05),
                      onPressed: () {
                        AppNavigator.pop(sheetCtx);
                        // Only re-fetch when a filter is actually applied —
                        // otherwise there's nothing to clear server-side, so
                        // just close the sheet.
                        if (cubit.hasActiveFilters) _clearFilters();
                      },
                    ),
                  ),
                  AppSpacing.w12,
                  Expanded(
                    child: AppButton(
                      label: ctx.translate(LanguageLabelKeys.apply),
                      height: ctx.heightFraction(0.05),
                      onPressed: () {
                        AppNavigator.pop(sheetCtx);
                        cubit.updateFilters(
                          search: _searchController.text.trim(),
                          startDate: tempStartDate,
                          endDate: tempEndDate,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  void _startSearch() => setState(() => _isSearching = true);

  void _cancelSearch() {
    setState(() => _isSearching = false);
    _debounce.cancel();
    final hadText = _searchController.text.trim().isNotEmpty;
    _searchController.clear();
    if (hadText) _onSearchChanged('');
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConnectivityCubit, ConnectivityState>(
      listener: (context, state) {
        if (state is ConnectivityConnected) {
          context.read<CashCollectionCubit>().loadCollections();
        }
      },
      builder: (context, connectivityState) {
        final isOffline = connectivityState is ConnectivityDisconnected;
        return AppScaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: CustomAppBar(
            title: context.translate(LanguageLabelKeys.cashCollection),
            scrollController: _scrollController.controller,
            isSearching: _isSearching,
            searchController: _searchController,
            onSearchChanged: _onSearchChanged,
            onSearchStart: _startSearch,
            onSearchCancel: _cancelSearch,
            searchHint: context.translate(LanguageLabelKeys.searchCollections),
            actions: [
              if (!_isSearching)
                BlocBuilder<CashCollectionCubit, CashCollectionState>(
                  builder: (context, _) {
                    final hasFilters = context
                        .read<CashCollectionCubit>()
                        .hasActiveFilters;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: AppSvgIcon(
                            AssetsConstants.filterIcon,
                            size: ThemeConstants.iconS,
                            color: context.cs.onSurfaceVariant,
                          ),
                          onPressed: _showFilterSheet,
                          tooltip: context.translate(LanguageLabelKeys.filters),
                        ),
                        if (hasFilters)
                          PositionedDirectional(
                            end: 10,
                            top: 10,
                            child: Container(
                              width: context.screenWidth * 0.019,
                              height: context.screenWidth * 0.019,
                              decoration: AppDecorations.circle(
                                color: context.cs.primary,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
            ],
          ),
          // Offline state lives in the body so the app bar — and its back
          // button — stays available on this pushed route.
          body: isOffline
              ? AppNoInternetFullScreen(
                  embedded: true,
                  onRetry: () =>
                      context.read<CashCollectionCubit>().loadCollections(),
                )
              : Column(
                  children: [
                    const CashCollectionSummaryCard(),
                    Expanded(
                      child:
                          BlocConsumer<
                            CashCollectionCubit,
                            CashCollectionState
                          >(
                            listener: (context, state) {},
                            builder: (context, state) {
                              if (state is CashCollectionLoading) {
                                return const ListSkeletonLoader();
                              }
                              if (state is CashCollectionError) {
                                return EmptyStateWidget(
                                  imagePath:
                                      AssetsConstants.noCaseCollectionFound,
                                  title: state.message,
                                  subtitle: context.translate(
                                    LanguageLabelKeys.pullDownToRefresh,
                                  ),
                                  onRetry: () => context
                                      .read<CashCollectionCubit>()
                                      .loadCollections(),
                                );
                              }
                              if (state is CashCollectionLoaded) {
                                return CashCollectionList(
                                  collections: state.data,
                                  isLoadingMore: state.isFetchingMore,
                                  hasMore: state.hasMore,
                                  scrollController: _scrollController.controller,
                                  onRefresh: () => context
                                      .read<CashCollectionCubit>()
                                      .loadCollections(),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
