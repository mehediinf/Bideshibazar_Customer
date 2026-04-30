class TeamMember {
  final String name;
  final String title;
  final String description;
  final String imageAsset;
  bool isExpanded;

  TeamMember({
    required this.name,
    required this.title,
    required this.description,
    required this.imageAsset,
    this.isExpanded = false,
  });
}

