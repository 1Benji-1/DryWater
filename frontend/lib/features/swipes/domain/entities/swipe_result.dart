class SwipeResult {
  final String status;
  final String message;
  final String propertyId;
  final String action;
  final bool isMatch;
  final bool createdMatch;
  final String? matchId;

  const SwipeResult({
    required this.status,
    required this.message,
    required this.propertyId,
    required this.action,
    required this.isMatch,
    required this.createdMatch,
    this.matchId,
  });

  factory SwipeResult.fromJson(Map<String, dynamic> json) {
    return SwipeResult(
      status: json['status']?.toString() ?? 'success',
      message: json['message']?.toString() ?? '',
      propertyId: json['property_id']?.toString() ?? '',
      action: json['action']?.toString() ?? '',
      isMatch: json['is_match'] == true,
      createdMatch: json['created_match'] == true || json['is_match'] == true,
      matchId: json['match_id']?.toString(),
    );
  }

  bool get processed => status == 'success';
}
