/// Thrown for invalid input. [code] is one of the stable codes listed in `fixtures/README.md`
/// (`split_sum_mismatch`, `percent_sum_invalid`, `payer_sum_mismatch`, `unknown_member`, ...)
/// so the UI can map each one to a friendly message.
class SplitError implements Exception {
  final String code;
  final String detail;

  const SplitError(this.code, [this.detail = '']);

  @override
  String toString() =>
      detail.isEmpty ? 'SplitError($code)' : 'SplitError($code: $detail)';
}
