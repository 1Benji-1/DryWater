class OwnerPropertyInput {
  final String title;
  final String description;
  final double price;
  final String operationType;
  final String propertyType;
  final String zone;
  final List<String> amenities;

  const OwnerPropertyInput({
    required this.title,
    required this.description,
    required this.price,
    required this.operationType,
    required this.propertyType,
    required this.zone,
    required this.amenities,
  });
}
