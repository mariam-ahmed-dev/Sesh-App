abstract final class SeshCategoryQueryMapper {
  static const queries = <String, String>{
    'Ancient Egypt': 'ancient Egypt',
    'Archaeology': 'archaeology AND Egypt',
    'Pharaohs': 'pharaoh OR pharaohs OR Egyptian king',
    'Artifacts': 'ancient Egyptian artifact',
    'Museums': 'Egypt museum',
    'Discoveries': 'Egypt archaeological discovery',
  };

  static String queryFor(String category) => queries[category] ?? queries['Ancient Egypt']!;
}
