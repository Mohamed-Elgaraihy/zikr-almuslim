class AzkarItem {
  const AzkarItem({
    required this.id,
    required this.text,
    required this.count,
    this.heading,
    this.virtue,
  });

  final int id;
  final String text;
  final int count;
  final String? heading;
  final String? virtue;

  factory AzkarItem.fromJson(Map<String, dynamic> json) {
    return AzkarItem(
      id: json['id'] as int,
      text: json['text'] as String,
      count: json['count'] as int,
      heading: json['heading'] as String?,
      virtue: json['virtue'] as String?,
    );
  }
}

class AzkarCategory {
  const AzkarCategory({
    required this.id,
    required this.title,
    required this.group,
    required this.daily,
    required this.items,
    this.blurb,
  });

  final String id;
  final String title;
  final String group;
  final bool daily;
  final String? blurb;
  final List<AzkarItem> items;

  int get repeats => items.fold(0, (sum, item) => sum + item.count);

  factory AzkarCategory.fromJson(Map<String, dynamic> json) {
    return AzkarCategory(
      id: json['id'] as String,
      title: json['title'] as String,
      group: json['group'] as String,
      daily: json['daily'] as bool? ?? false,
      blurb: json['blurb'] as String?,
      items: (json['items'] as List<dynamic>)
          .map((item) => AzkarItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AzkarGroup {
  const AzkarGroup({required this.id, required this.title});

  final String id;
  final String title;

  factory AzkarGroup.fromJson(Map<String, dynamic> json) {
    return AzkarGroup(id: json['id'] as String, title: json['title'] as String);
  }
}

class AzkarLibrary {
  const AzkarLibrary({
    required this.title,
    required this.source,
    required this.groups,
    required this.categories,
  });

  final String title;
  final String source;
  final List<AzkarGroup> groups;
  final List<AzkarCategory> categories;

  AzkarCategory byId(String id) {
    return categories.firstWhere((category) => category.id == id);
  }

  AzkarCategory get morning => byId('morning');

  AzkarCategory get evening => byId('evening');

  List<AzkarCategory> inGroup(String groupId) {
    return categories.where((category) => category.group == groupId).toList();
  }

  factory AzkarLibrary.fromJson(Map<String, dynamic> json) {
    return AzkarLibrary(
      title: json['title'] as String,
      source: json['source'] as String,
      groups: (json['groups'] as List<dynamic>)
          .map((group) => AzkarGroup.fromJson(group as Map<String, dynamic>))
          .toList(),
      categories: (json['categories'] as List<dynamic>)
          .map(
            (category) =>
                AzkarCategory.fromJson(category as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
