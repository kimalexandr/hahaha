import 'package:eventa/src/features/home/domain/entities/event.dart';
import 'package:eventa/src/features/home/domain/event_geo.dart';
import 'package:eventa/src/features/home/presentation/pages/home_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

class EventsMapPage extends StatelessWidget {
  const EventsMapPage({
    super.key,
    required this.events,
    required this.onOpenEvent,
  });

  final List<Event> events;
  final void Function(Event event) onOpenEvent;

  List<_MapEventPin> get _pins {
    final result = <_MapEventPin>[];
    for (final event in events) {
      LatLng? point;
      if (event.latitude != null && event.longitude != null) {
        point = LatLng(event.latitude!, event.longitude!);
      } else {
        point = coordinatesForCity(event.city);
      }
      if (point == null) continue;
      // Небольшой разброс, если несколько событий в одном городе.
      final jitter = (event.id.hashCode % 17) * 0.0012 - 0.01;
      result.add(
        _MapEventPin(
          event: event,
          point: LatLng(
            point.latitude + jitter,
            point.longitude + jitter * 0.7,
          ),
        ),
      );
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final pins = _pins;
    final center =
        pins.isNotEmpty ? pins.first.point : const LatLng(43.238949, 76.945465);

    return Scaffold(
      appBar: AppBar(title: const Text('Карта мероприятий')),
      body:
          pins.isEmpty
              ? const EmptyStateView(
                icon: Icons.map_outlined,
                title: 'Нет событий с координатами',
                subtitle: 'Укажите город или координаты у мероприятия',
              )
              : FlutterMap(
                options: MapOptions(initialCenter: center, initialZoom: 11),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.eventus.app',
                  ),
                  MarkerLayer(
                    markers:
                        pins
                            .map(
                              (pin) => Marker(
                                point: pin.point,
                                width: 44,
                                height: 44,
                                child: GestureDetector(
                                  onTap:
                                      () => _showEventSheet(context, pin.event),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Color(0xFFE53935),
                                    size: 40,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
    );
  }

  void _showEventSheet(BuildContext context, Event event) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(event.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text(
                '${event.city} · ${event.place}\n'
                '${DateFormat('d MMM yyyy, HH:mm', 'ru').format(event.date)}',
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  onOpenEvent(event);
                },
                child: const Text('Открыть мероприятие'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MapEventPin {
  const _MapEventPin({required this.event, required this.point});
  final Event event;
  final LatLng point;
}
