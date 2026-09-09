import 'package:deliveryboy/commons/cubit/connectivity_cubit.dart';
import 'package:deliveryboy/commons/utils/debouncer.dart';
import 'package:deliveryboy/commons/utils/pagination_scroll_controller.dart';
import 'package:deliveryboy/commons/widgets/app_date_range_picker.dart';
import 'package:deliveryboy/commons/widgets/app_scaffold.dart';
import 'package:deliveryboy/commons/widgets/custom_app_bar.dart';
import 'package:deliveryboy/commons/widgets/app_no_internet_widget.dart';
import 'package:deliveryboy/commons/widgets/empty_state_widget.dart';
import 'package:deliveryboy/core/constants/assets_constants.dart';
import 'package:deliveryboy/utils/extensions/string_extensions.dart';
import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/cash_collection_cubit.dart';
import '../widgets/cash_collection_app_bar_actions.dart';
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

  Future<void> _pickDateRange() async {
    final cubit = context.read<CashCollectionCubit>();
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
    if (range != null && mounted) {
      cubit.updateFilters(
        search: _searchController.text.trim(),
        startDate: range.start.toApiDateString(),
        endDate: range.end.toApiDateString(),
      );
    }
  }

  void _clearFilters() {
    _debounce.cancel();
    _searchController.clear();
    context.read<CashCollectionCubit>().clearFilters();
  }

  void _startSearch() => setState(() => _isSearching = true);

  void _cancelSearch() {
    setState(() => _isSearching = false);
    _debounce.cancel();
    _searchController.clear();
    _onSearchChanged('');
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
            isSearching: _isSearching,
            searchController: _searchController,
            onSearchChanged: _onSearchChanged,
            onSearchStart: _startSearch,
            onSearchCancel: _cancelSearch,
            searchHint: context.translate(LanguageLabelKeys.searchCollections),
            actions: [
              CashCollectionAppBarActions(
                onPickDateRange: _pickDateRange,
                onClearFilters: _clearFilters,
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
