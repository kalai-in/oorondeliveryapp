import 'package:deliveryboy/core/constants/navigation_service.dart';
import 'package:deliveryboy/core/constants/theme_constants.dart';
import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/utils/extensions/context_extensions.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:deliveryboy/utils/show_app_bottom_sheet.dart';
import 'package:deliveryboy/commons/animations/slide_animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/settlement_history_cubit.dart';
import '../models/settlement_entry_type.dart';
import 'package:deliveryboy/commons/widgets/app_text.dart';

void showSettlementHistoryFilterSheet(BuildContext context) {
  final fundTransferCubit = context.read<SettlementHistoryCubit>();
  final filters = [
    (context.translate(LanguageLabelKeys.all), SettlementEntryType.all),
    (
      context.translate(LanguageLabelKeys.deliveryCommission),
      SettlementEntryType.deliveryCommission,
    ),
    (
      context.translate(LanguageLabelKeys.returnCommission),
      SettlementEntryType.returnCommission,
    ),
    (
      context.translate(LanguageLabelKeys.withdrawal),
      SettlementEntryType.withdrawal,
    ),
    (
      context.translate(LanguageLabelKeys.cashDepositCash),
      SettlementEntryType.cashDepositCash,
    ),
    (
      context.translate(LanguageLabelKeys.cashDepositWallet),
      SettlementEntryType.cashDepositWallet,
    ),
  ];

  showAppBottomSheet(
    context,
    title: context.translate(LanguageLabelKeys.filterByType),
    padding: const EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingXL, ThemeConstants.paddingM, ThemeConstants.paddingXL, ThemeConstants.paddingXXL),
    builder: (_) => StatefulBuilder(
      builder: (ctx, setSheetState) {
        SettlementEntryType selected = SettlementEntryType.fromValue(
          fundTransferCubit.entryType,
        );
        return Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          children: [
            RadioGroup<SettlementEntryType>(
              groupValue: selected,
              onChanged: (val) {
                if (val != null) {
                  setSheetState(() => selected = val);
                  fundTransferCubit.updateFilters(
                    entryType: val.value,
                    startDate: fundTransferCubit.startDate,
                    endDate: fundTransferCubit.endDate,
                  );
                  AppNavigator.pop(context);
                }
              },
              child: SlideAnimationList(
                children: filters
                    .map(
                      (f) => RadioListTile<SettlementEntryType>(
                        title: AppText(f.$1),
                        value: f.$2,
                        activeColor: context.cs.primary,
                        controlAffinity: ListTileControlAffinity.trailing,
                        contentPadding: EdgeInsetsDirectional.zero,
                        visualDensity: const VisualDensity(
                          horizontal: 0,
                          vertical: -4,
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        );
      },
    ),
  );
}
