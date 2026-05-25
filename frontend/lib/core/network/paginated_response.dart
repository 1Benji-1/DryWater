/// Respuesta paginada estándar que llega desde FastAPI.
///
/// Formato esperado:
/// {
///   "items": [],
///   "pagination": {
///     "page": 1,
///     "page_size": 20,
///     "total": 100,
///     "has_next": true
///   }
/// }
class PaginatedResponse<T> {
  final List<T> items;
  final PaginationMeta pagination;

  const PaginatedResponse({
    required this.items,
    required this.pagination,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> itemJson) itemFromJson,
  ) {
    final rawItems = json['items'];

    final items = rawItems is List
        ? rawItems.whereType<Map<String, dynamic>>().map(itemFromJson).toList()
        : <T>[];

    return PaginatedResponse<T>(
      items: items,
      pagination: PaginationMeta.fromJson(
        json['pagination'] is Map<String, dynamic>
            ? json['pagination'] as Map<String, dynamic>
            : const {},
      ),
    );
  }
}

class PaginationMeta {
  final int page;
  final int pageSize;
  final int total;
  final bool hasNext;

  const PaginationMeta({
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasNext,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: _readInt(json['page'], fallback: 1),
      pageSize: _readInt(json['page_size'], fallback: 20),
      total: _readInt(json['total']),
      hasNext: json['has_next'] == true,
    );
  }

  static int _readInt(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
