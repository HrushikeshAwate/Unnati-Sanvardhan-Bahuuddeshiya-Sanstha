class QueryModel {
  final String id;
  final String userId;
  final String category;
  final String description;
  final String status;

  QueryModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.description,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'category': category,
        'description': description,
        'status': status,
      };
}
