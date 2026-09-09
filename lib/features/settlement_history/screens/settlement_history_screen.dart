import 'package:deliveryboy/commons/cubit/connectivity_cubit.dart';
import 'package:deliveryboy/commons/utils/debouncer.dart';
import 'package:deliveryboy/commons/utils/pagination_scroll_controller.dart';
import 'package:deliveryboy/commons/widgets/app_date_range_picker.dart';
import 'package:deliveryboy/commons/widgets/app_scaffold.dart';
import 'package:deliveryboy/commons/widgets/app_svg_icon.dart';
import 'package:deliveryboy/commons/widgets/custom_app_bar.dart';
import 'package:deliveryboy/commons/widgets/app_no_internet_widget.dart';
import 'package:deliveryboy/commons/widgets/app_snack_bar.dart';
import 'package:deliveryboy/core/constants/assets_constants.dart';
import 'package:deliveryboy/core/constants/theme_constants.dart';
import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/features/settlement_history/models/settlement_history_model.dart';
import 'package:deliveryboy/features/settlement_history/widgets/settlement_history_filter_sheet.dart';
import 'package:deliveryboy/features/settlement_history/widgets/settlement_history_list.dart';
import 'package:deliveryboy/utils/extensions/context_extensions.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:deliveryboy/utils/extensions/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:deliveryboy/core/theme/app_decorations.dart';
import 'package:deliveryboy/core/theme/app_radius.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:deliveryboy/commons/cubit/base_pagination_cubit.dart';
import '../cubit/settlement_history_cubit.dart';
import '../../../commons/widgets/empty_state_widget.dart';
import '../../../commons/widgets/list_skeleton_loader.dart';
import 'package:deliveryboy/core/theme/app_spacing.dart';

/// Screen showing paginated fund transfer/settlement history with search and date filters.
class SettlementHistoryScreen extends StatefulWidget {
  const SettlementHistoryScreen({super.key});

  @override
  State<SettlementHistoryScreen> createState() =>
      _SettlementHistoryScreenState();
}

class _SettlementHistoryScreenState extends State<SettlementHistoryScreen> {
  final _searchController = TextEditingController();
  late final PaginationScrollController _scrollController;
  final _debounce = Debouncer();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    context.read<SettlementHistoryCubit>().loadTransfers();
    _scrollController = PaginationScrollController(
      onLoadMore: () => context.read<SettlementHistoryCubit>().loadMore(),
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
      final cubit = context.read<SettlementHistoryCubit>();
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
    context.read<SettlementHistoryCubit>().clearFilters();
  }

  void _startSearch() => setState(() => _isSearching = true);

  void _cancelSearch() {
    setState(() => _isSearching = false);
    _searchController.clear();
    _onSearchChanged('');
  }

  Future<void> _pickDateRange() async {
    final cubit = context.read<SettlementHistoryCubit>();
    final now = DateTime.now();
    final range = await showAppDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: cubit.startDate != null && cubit.endDate != null
          ? DateTimeRange(
              start: DateTime.parse(cubit.startDate!),
              end: DateTime.parse(cubit.endDate!),
            )
          : null,
    );
    if (range == null) return;
    cubit.updateFilters(
      startDate: range.start.toApiDateString(),
      endDate: range.end.toApiDateString(),
    );
  }

  void _clearDateRange() {
    context.read<SettlementHistoryCubit>().updateFilters(
      startDate: null,
      endDate: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConnectivityCubit, ConnectivityState>(
      listener: (context, state) {
        if (state is ConnectivityConnected) {
          context.read<SettlementHistoryCubit>().loadTransfers();
        }
      },
      builder: (context, connectivityState) {
        final isOffline = connectivityState is ConnectivityDisconnected;
        return AppScaffold(
          appBar: CustomAppBar(
            title: context.translate(LanguageLabelKeys.settlementHistory),
            isSearching: _isSearching,
            searchController: _searchController,
            onSearchChanged: _onSearchChanged,
            onSearchStart: _startSearch,
            onSearchCancel: _cancelSearch,
            searchHint: context.translate(LanguageLabelKeys.searchTransfers),
            actions: [
              BlocBuilder<
                SettlementHistoryCubit,
                PaginationState<SettlementHistoryData>
              >(
                builder: (context, _) {
                  final hasFilters = context
                      .read<SettlementHistoryCubit>()
                      .hasActiveFilters;
                  if (!hasFilters || _isSearching) {
                    return const SizedBox.shrink();
                  }
                  return Tooltip(
                    message: context.translate(LanguageLabelKeys.clearFilters),
                    child: InkWell(
                      onTap: _clearFilters,
                      borderRadius: AppRadius.r10,
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: AppDecorations.outlinedCard(
                          color: context.cs.surface,
                          borderColor: context.cs.outline,
                        ),
                        child: AppSvgIcon(
                          AssetsConstants.closeIcon,
                          size: 16,
                          color: context.cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (!_isSearching)
                BlocBuilder<
                  SettlementHistoryCubit,
                  PaginationState<SettlementHistoryData>
                >(
                  builder: (context, _) {
                    final cubit = context.read<SettlementHistoryCubit>();
                    final hasDate =
                        cubit.startDate != null || cubit.endDate != null;
                    if (!hasDate) {
                      return IconButton(
                        icon: AppSvgIcon(
                          AssetsConstants.dateIcon,
                          size: 24,
                          color: context.cs.onSurfaceVariant,
                        ),
                        onPressed: _pickDateRange,
                        tooltip: context.translate(LanguageLabelKeys.dateRange),
                      );
                    }
                    return Container(
                      height: 40,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: AppDecorations.outlinedCard(
                        color: context.cs.surface,
                        borderColor: context.cs.primary,
                      ),
                      child: Row(
                        mainAxisSize: .min,
                        children: [
                          Tooltip(
                            message: '${cubit.startDate} → ${cubit.endDate}',
                            child: InkWell(
                              onTap: _pickDateRange,
                              borderRadius: AppRadius.r10,
                              child: Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  start: 10,
                                  end: ThemeConstants.paddingXS,
                                  top: ThemeConstants.paddingS,
                                  bottom: ThemeConstants.paddingS,
                                ),
                                child: AppSvgIcon(
                                  AssetsConstants.dateIcon,
                                  size: 20,
                                  color: context.cs.primary,
                                ),
                              ),
                            ),
                          ),
                          Tooltip(
                            message: context.translate(
                              LanguageLabelKeys.clearFilters,
                            ),
                            child: InkWell(
                              onTap: _clearDateRange,
                              borderRadius: AppRadius.r10,
                              child: Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  start: ThemeConstants.paddingXS,
                                  end: 10,
                                  top: ThemeConstants.paddingS,
                                  bottom: ThemeConstants.paddingS,
                                ),
                                child: AppSvgIcon(
                                  AssetsConstants.closeIcon,
                                  size: 14,
                                  color: context.cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              if (!_isSearching)
                Builder(
                  builder: (ctx) => IconButton(
                    icon: AppSvgIcon(
                      AssetsConstants.filterIcon,
                      size: 24,
                      color: context.cs.onSurfaceVariant,
                    ),
                    onPressed: () => showSettlementHistoryFilterSheet(context),
                  ),
                ),
              AppSpacing.w4,
            ],
          ),
          // Offline state lives in the body so the app bar — and its back
          // button — stays available on this pushed route.
          body: isOffline
              ? AppNoInternetFullScreen(
                  embedded: true,
                  onRetry: () =>
                      context.read<SettlementHistoryCubit>().loadTransfers(),
                )
              : BlocConsumer<
                  SettlementHistoryCubit,
                  PaginationState<SettlementHistoryData>
                >(
                  listener: (context, state) {
                    if (state is PaginationError<SettlementHistoryData>) {
                      AppSnackBar.show(
                        context: context,
                        message: state.message,
                        type: SnackBarType.error,
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is PaginationLoading<SettlementHistoryData>) {
                      return const ListSkeletonLoader();
                    }
                    if (state is PaginationError<SettlementHistoryData>) {
                      return EmptyStateWidget(
                        imagePath: AssetsConstants.noFundFound,
                        title: state.message,
                        subtitle: context.translate(
                          LanguageLabelKeys.pullDownToRefresh,
                        ),
                        onRetry: () => context
                            .read<SettlementHistoryCubit>()
                            .loadTransfers(),
                      );
                    }
                    if (state is PaginationLoaded<SettlementHistoryData>) {
                      return TransferList(
                        transfers: state.data,
                        isLoadingMore: state.isFetchingMore,
                        hasMore: state.hasMore,
                        scrollController: _scrollController.controller,
                        onRefresh: () => context
                            .read<SettlementHistoryCubit>()
                            .loadTransfers(),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
        );
      },
    );
  }
}
