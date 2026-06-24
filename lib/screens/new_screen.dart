import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class Business {
  final String name;
  final String category;
  final double distanceMiles;
  final bool blackOwnedVerified;

  const Business({
    required this.name,
    required this.category,
    required this.distanceMiles,
    required this.blackOwnedVerified,
  });
}

const demoBusinesses = <Business>[
  Business(name: 'Harlem Coffee Bar', category: 'Restaurant', distanceMiles: 0.8, blackOwnedVerified: true),
  Business(name: 'Brooklyn Books', category: 'Retail', distanceMiles: 2.2, blackOwnedVerified: true),
  Business(name: 'Queens Fitness Studio', category: 'Services', distanceMiles: 4.7, blackOwnedVerified: false),
  Business(name: 'Bronx Vegan Kitchen', category: 'Restaurant', distanceMiles: 7.9, blackOwnedVerified: true),
  Business(name: 'Newark Skin Care', category: 'Retail', distanceMiles: 14.2, blackOwnedVerified: false),
];

class BrokenLocationFilterScreen extends StatefulWidget {
  const BrokenLocationFilterScreen({super.key});

  @override
  State<BrokenLocationFilterScreen> createState() => _BrokenLocationFilterScreenState();
}

class _BrokenLocationFilterScreenState extends State<BrokenLocationFilterScreen> {
  bool isLocating = false;
  bool useMyLocation = false;
  String selectedCategory = 'All';
  bool verifiedOnly = false;
  double maxDistanceMiles = 5;
  String status = 'Tap "Use my location" to test permission flow.';

  Future<void> useCurrentLocation() async {
    setState(() {
      isLocating = true;
      status = 'Checking location services...';
    });

    // FIX BUG 4: Check if location services are enabled before anything else.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    if (!serviceEnabled) {
      setState(() {
        isLocating = false;
        status = 'Location services are disabled. Please enable them in Settings.';
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (!mounted) return;

    // FIX BUG 1 & 2: If denied (not forever), actually request permission.
    if (permission == LocationPermission.denied) {
      setState(() => status = 'Requesting location permission...');
      permission = await Geolocator.requestPermission();
      if (!mounted) return;

      // FIX BUG 3: Reset isLocating on every early return path.
      if (permission == LocationPermission.denied) {
        setState(() {
          isLocating = false;
          status = 'Location permission denied.';
        });
        return;
      }
    }

    // FIX BUG 2 & 3: Handle deniedForever separately with an Open Settings dialog.
    if (permission == LocationPermission.deniedForever) {
      setState(() => isLocating = false);
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'Location access is permanently denied. '
            'Please open Settings to enable it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Geolocator.openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      return;
    }

    // Permission granted — get position.
    if (!mounted) return;
    setState(() => status = 'Getting your location...');

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 15),
      );

      // FIX BUG 5: mounted check after every async gap before setState/showDialog.
      if (!mounted) return;

      setState(() {
        useMyLocation = true;
        isLocating = false;
        status =
            'Location loaded: ${position.latitude.toStringAsFixed(3)}, '
            '${position.longitude.toStringAsFixed(3)}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isLocating = false;
        status = 'Could not get location. Please try again.';
      });
    }
  }

  List<Business> get filteredBusinesses {
    // Start from a fresh copy so filters always compose on the full list.
    var list = List<Business>.from(demoBusinesses);

    if (selectedCategory != 'All') {
      list = list.where((b) => b.category == selectedCategory).toList();
    }

    // FIX BUG 6: No fallback — zero verified matches correctly shows zero results.
    if (verifiedOnly) {
      list = list.where((b) => b.blackOwnedVerified).toList();
    }

    // FIX BUG 7: No fallback — zero nearby matches correctly shows zero results.
    if (useMyLocation) {
      list = list.where((b) => b.distanceMiles <= maxDistanceMiles).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final businesses = filteredBusinesses;

    return Scaffold(
      appBar: AppBar(title: const Text('Location + Filter Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: isLocating ? null : useCurrentLocation,
                  child: Text(isLocating ? 'Locating...' : 'Use my location'),
                ),
                DropdownButton<String>(
                  value: selectedCategory,
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All')),
                    DropdownMenuItem(value: 'Restaurant', child: Text('Restaurant')),
                    DropdownMenuItem(value: 'Retail', child: Text('Retail')),
                    DropdownMenuItem(value: 'Services', child: Text('Services')),
                  ],
                  onChanged: (value) => setState(() => selectedCategory = value ?? 'All'),
                ),
                FilterChip(
                  label: const Text('Verified only'),
                  selected: verifiedOnly,
                  onSelected: (value) => setState(() => verifiedOnly = value),
                ),
                SizedBox(
                  width: 220,
                  child: Row(
                    children: [
                      const Text('Distance'),
                      Expanded(
                        child: Slider(
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: '${maxDistanceMiles.round()} mi',
                          value: maxDistanceMiles,
                          onChanged: (value) => setState(() => maxDistanceMiles = value),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(status),
            const Divider(height: 32),
            Text('Results (${businesses.length})', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Expanded(
              child: businesses.isEmpty
                  ? const Center(child: Text('No matching businesses.'))
                  : ListView.builder(
                      itemCount: businesses.length,
                      itemBuilder: (context, index) {
                        final b = businesses[index];
                        return ListTile(
                          title: Text(b.name),
                          subtitle: Text('${b.category} • ${b.distanceMiles} mi'),
                          trailing: b.blackOwnedVerified ? const Icon(Icons.verified) : null,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
