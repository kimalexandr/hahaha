import 'package:eventa/src/features/venues/data/demo_venue_catalog.dart';
import 'package:eventa/src/features/venues/domain/entities/venue.dart';
import 'package:eventa/src/features/venues/presentation/pages/venue_details_page.dart';
import 'package:flutter/material.dart';

class VenuesPage extends StatefulWidget {
  const VenuesPage({super.key, this.initialCity});

  final String? initialCity;

  @override
  State<VenuesPage> createState() => _VenuesPageState();
}

class _VenuesPageState extends State<VenuesPage> {
  late final List<Venue> _venues;
  late final TextEditingController _cityController;
  VenueType? _typeFilter;

  @override
  void initState() {
    super.initState();
    _venues = DemoVenueCatalog.all();
    _cityController = TextEditingController(text: widget.initialCity ?? '');
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  List<Venue> get _filtered {
    final city = _cityController.text.trim().toLowerCase();
    return _venues.where((venue) {
      final typeOk = _typeFilter == null || venue.type == _typeFilter;
      final cityOk = city.isEmpty || venue.city.toLowerCase().contains(city);
      return typeOk && cityOk;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Scaffold(
      appBar: AppBar(title: const Text('Заведения')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'Город',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Все'),
                  selected: _typeFilter == null,
                  onSelected: (_) => setState(() => _typeFilter = null),
                ),
                const SizedBox(width: 8),
                ...VenueType.values.map(
                  (type) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(type.labelRu),
                      selected: _typeFilter == type,
                      onSelected: (selected) {
                        setState(() => _typeFilter = selected ? type : null);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child:
                items.isEmpty
                    ? const Center(child: Text('Нет заведений по фильтру'))
                    : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final venue = items[index];
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: CircleAvatar(
                              backgroundColor:
                                  Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                              child: Text(venue.type.labelRu.substring(0, 1)),
                            ),
                            title: Text(venue.name),
                            subtitle: Text(
                              '${venue.type.labelRu} · ${venue.city}\n${venue.address}',
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (_) => VenueDetailsPage(venue: venue),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
