import 'package:splittab_core/splittab_core.dart';

/// Plain, specific messages for the core package's error codes. They say what to do next.
String friendlyError(SplitError e) => switch (e.code) {
  'split_sum_mismatch' =>
    'The amounts do not add up to the total. Adjust them so they match.',
  'percent_sum_invalid' => 'Percentages must add up to 100.',
  'invalid_shares' => 'Give at least one person a share above zero.',
  'empty_split' => 'Choose at least one person to split with.',
  'missing_rate' => 'Enter the exchange rate for this currency.',
  'invalid_rate' => 'The exchange rate must be above zero.',
  'amount_too_large' => 'That amount is too large. Enter a smaller number.',
  'payer_sum_mismatch' => 'The payer amounts do not add up to the total.',
  'unknown_member' =>
    'One of the people on this expense is not part of the trip.',
  _ => 'Something is wrong with this expense. Check the details and try again.',
};
