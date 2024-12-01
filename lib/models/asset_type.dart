class AssetType {
  final String name;
  final String icon;
  final String description;

  const AssetType({
    required this.name,
    required this.icon,
    required this.description,
  });

  static const List<AssetType> types = [
    AssetType(
      name: 'Tool',
      icon: '🛠️',
      description: 'Hand tools and power tools used in repairs',
    ),
    AssetType(
      name: 'Equipment',
      icon: '⚙️',
      description: 'Large machinery and specialized equipment',
    ),
    AssetType(
      name: 'Computer',
      icon: '💻',
      description: 'Desktop computers and laptops',
    ),
    AssetType(
      name: 'Mobile Device',
      icon: '📱',
      description: 'Smartphones, tablets, and other mobile devices',
    ),
    AssetType(
      name: 'Furniture',
      icon: '🪑',
      description: 'Office furniture and storage units',
    ),
    AssetType(
      name: 'Vehicle',
      icon: '🚗',
      description: 'Company vehicles and transportation equipment',
    ),
    AssetType(
      name: 'Network Equipment',
      icon: '🌐',
      description: 'Routers, switches, and networking hardware',
    ),
    AssetType(
      name: 'Testing Equipment',
      icon: '📊',
      description: 'Diagnostic and testing tools',
    ),
    AssetType(
      name: 'Safety Equipment',
      icon: '⛑️',
      description: 'Personal protective equipment and safety gear',
    ),
    AssetType(
      name: 'Other',
      icon: '📦',
      description: 'Miscellaneous assets',
    ),
  ];
} 