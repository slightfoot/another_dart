//

class AssetItem {
  const AssetItem({
    required this.title,
    required this.palette,
    required this.bytecode,
    required this.polygon1,
    required this.polygon2,
  });

  final String title;
  final String palette;
  final String bytecode;
  final String polygon1;
  final String polygon2;
}

const assets = [
  AssetItem(
    title: 'Introduction',
    palette: 'file023.dat',
    bytecode: 'file024.dat',
    polygon1: 'file025.dat',
    polygon2: '',
  ),
  AssetItem(
    title: 'Water',
    palette: 'file026.dat',
    bytecode: 'file027.dat',
    polygon1: 'file028.dat',
    polygon2: 'file017.dat',
  ),
];
