import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/session_service.dart';
import 'package:provider/provider.dart';
import 'package:photo_view/photo_view.dart';

class FrontPage extends StatefulWidget {
  const FrontPage({super.key});

  @override
  State<FrontPage> createState() => _FrontPageState();
}

class _FrontPageState extends State<FrontPage> {
  final _searchCtrl = TextEditingController();
  Map<String, Map<String, List<String>>> _folderStructure = {};
  Map<String, Map<String, List<String>>> _filteredFolderStructure = {};

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      final Map<String, Map<String, List<String>>> folderStructure = {};

      for (final assetPath in manifestMap.keys) {
        if (assetPath.startsWith('assets/pedali/')) {
          final parts = assetPath.split('/');
          // parts example: ['assets', 'pedali', 'CB', '5052ET', 'file.png']
          if (parts.length >= 4) {
            final province = parts[2];
            final car = parts[3];
            final fileName = parts.length > 4 ? parts.sublist(4).join('/') : '';
            if (fileName.isNotEmpty &&
                !fileName.startsWith('.') &&
                !fileName.contains('.DS_Store')) {
              folderStructure.putIfAbsent(province, () => {});
              folderStructure[province]!.putIfAbsent(car, () => []);
              folderStructure[province]![car]!.add(assetPath);
            }
          } else if (parts.length == 3) {
            // province folder with no car subfolder or images
            final province = parts[2];
            folderStructure.putIfAbsent(province, () => {});
          }
        }
      }

      // Sort keys and images
      for (var province in folderStructure.keys) {
        folderStructure[province]!.forEach((car, images) {
          images.sort();
        });
      }

      final sortedFolderStructure = Map<String, Map<String, List<String>>>.fromEntries(
        folderStructure.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)),
      );

      setState(() {
        _folderStructure = sortedFolderStructure;
        _filteredFolderStructure = Map.from(_folderStructure);
      });
    } catch (e) {
      setState(() {
        _folderStructure = {};
        _filteredFolderStructure = {};
      });
    }
  }

  void _filterFolders(String query) {
    final lowerQuery = query.toLowerCase();
    final Map<String, Map<String, List<String>>> filtered = {};

    _folderStructure.forEach((province, cars) {
      final provinceMatches = province.toLowerCase().contains(lowerQuery);
      final Map<String, List<String>> filteredCars = {};

      cars.forEach((car, images) {
        final carMatches = car.toLowerCase().contains(lowerQuery);
        if (provinceMatches || carMatches) {
          filteredCars[car] = images;
        }
      });

      if (provinceMatches || filteredCars.isNotEmpty) {
        filtered[province] = filteredCars;
      }
    });

    setState(() {
      _filteredFolderStructure = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('P.E.D.A.L.'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<SessionService>().logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by folder name',
              ),
              onChanged: (value) {
                _filterFolders(value);
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _filteredFolderStructure.isEmpty
                  ? const Center(child: Text('No folders found.'))
                  : ListView(
                      children: _filteredFolderStructure.entries.map((provinceEntry) {
                        final province = provinceEntry.key;
                        final cars = provinceEntry.value;
                        return ExpansionTile(
                          key: PageStorageKey<String>('province_$province'),
                          title: Text(province),
                          children: cars.entries.map((carEntry) {
                            final car = carEntry.key;
                            final images = carEntry.value;
                            return ExpansionTile(
                              key: PageStorageKey<String>('car_${province}_$car'),
                              title: Text(car),
                              children: images.isEmpty
                                  ? [const ListTile(title: Text('No images'))]
                                  : images.map((imagePath) {
                                      return ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                        title: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ImageViewerPage(imagePath: imagePath),
                                              ),
                                            );
                                          },
                                          child: SizedBox(
                                            height: 100,
                                            child: Image.asset(
                                              imagePath,
                                              fit: BoxFit.contain,
                                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                            );
                          }).toList(),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class ImageViewerPage extends StatelessWidget {
  final String imagePath;

  const ImageViewerPage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: PhotoView(
          imageProvider: AssetImage(imagePath),
          backgroundDecoration: const BoxDecoration(color: Colors.black),
        ),
      ),
    );
  }
}