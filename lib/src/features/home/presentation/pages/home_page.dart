import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eventa/src/features/home/domain/entities/event.dart';
import 'package:eventa/src/features/home/data/local/home_local_storage.dart';
import 'package:eventa/src/features/home/data/remote/home_remote_storage.dart';
import 'package:eventa/src/features/profile/domain/entities/user_profile.dart';
import 'package:eventa/src/features/profile/data/profile_persistence.dart';
import 'package:eventa/src/features/home/presentation/pages/home_components.dart';
import 'package:eventa/src/core/app_runtime_config.dart';
import 'package:eventa/src/core/di/injection.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventa/src/features/venues/presentation/pages/venues_page.dart';
import 'package:eventa/src/features/meetings/data/meeting_repository.dart';
import 'package:eventa/src/features/meetings/presentation/pages/meetings_catalog_page.dart';
import 'package:flutter/foundation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _currentUserId = 'user-1';
  static const int _pageSize = 10;
  final HomeLocalStorage _localStorage = HomeLocalStorage();
  final bool _useFirebaseBackend =
      appUsesFirebaseBackend &&
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  HomeRemoteStorage? _remoteStorage;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _cityFilterController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Event> _events = [
    Event(
      id: 'event-1',
      createdAt: DateTime.now(),
      ownerId: 'system',
      organizerName: 'Eventa Team',
      title: 'Open Air Party',
      city: 'Almaty',
      category: 'Музыка',
      price: 2500,
      date: DateTime.now().add(const Duration(days: 2)),
      place: 'Central Park',
      description:
          'Join us for an unforgettable night with live music, food trucks, and more!',
      photos: [
        'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
        'https://images.unsplash.com/photo-1465101046530-73398c7f28ca',
        'https://images.unsplash.com/photo-1519125323398-675f0ddb6308',
      ],
      likes: 12,
      going: 5,
      comments: 3,
      hasTicket: true,
    ),
    Event(
      id: 'event-2',
      createdAt: DateTime.now(),
      ownerId: 'system',
      organizerName: 'Tech Community',
      title: 'Startup Meetup',
      city: 'Astana',
      category: 'Бизнес',
      price: 0,
      date: DateTime.now().add(const Duration(days: 5)),
      place: 'Tech Hub',
      description: 'Networking and talks for aspiring entrepreneurs.',
      photos: [
        'https://images.unsplash.com/photo-1515168833906-d2a3b82b3029',
        'https://images.unsplash.com/photo-1465101178521-c1a9136a3b99',
      ],
      likes: 7,
      going: 2,
      comments: 1,
      hasTicket: false,
    ),
  ];
  List<Event> _filteredEvents = [];
  bool _initialLoading = true;
  final Map<String, List<String>> _eventComments = {
    'event-1': ['Классный лайн-ап!', 'Кто еще идет?'],
    'event-2': ['Будет запись выступлений?'],
  };
  UserProfile _profile = UserProfile(
    id: 'profile-1',
    createdAt: DateTime.now(),
    ownerId: _currentUserId,
    name: 'Пользователь',
    bio: 'Расскажите о себе',
    role: 'user',
  );
  String _selectedCategory = 'Все';
  bool _freeOnly = false;
  DateTime? _selectedFilterDate;
  int _selectedTabIndex = 0;
  int _visibleCount = _pageSize;
  bool _isLoadingMore = false;
  List<String> _notifications = [];

  @override
  void initState() {
    super.initState();
    if (_useFirebaseBackend) {
      _remoteStorage = HomeRemoteStorage();
    }
    _loadState();
    _searchController.addListener(_onSearch);
    _scrollController.addListener(_onListScroll);
  }

  void _onSearch() {
    _applyFilters();
  }

  Future<void> _loadState() async {
    List<Event> savedEvents = [];
    UserProfile? savedProfile;
    Map<String, List<String>> savedComments = {};
    final savedNotifications = await _localStorage.readNotifications();

    try {
      if (_remoteStorage == null) {
        throw Exception('Remote storage disabled on this platform');
      }
      savedEvents = await _remoteStorage!.readEvents();
      savedProfile = await _remoteStorage!.readProfile(_currentUserId);
      savedComments = await _remoteStorage!.readCommentsMap();
    } catch (_) {
      // Fall back to local cache when network/Firestore is unavailable.
      savedEvents = await _localStorage.readEvents();
      savedProfile = await _localStorage.readProfile();
      savedComments = await _localStorage.readComments();
    }
    if (!mounted) return;

    setState(() {
      if (savedEvents.isNotEmpty) {
        _events
          ..clear()
          ..addAll(savedEvents);
      }
      if (savedProfile != null) {
        _profile = savedProfile;
      }
      if (savedComments.isNotEmpty) {
        _eventComments
          ..clear()
          ..addAll(savedComments);
      }
      if (savedNotifications.isNotEmpty) {
        _notifications = savedNotifications;
      }
      _initialLoading = false;
    });

    _applyFilters();
    _syncNotifications();
    await _persistState();
  }

  Future<void> _persistState() async {
    await _localStorage.saveEvents(_events);
    await _localStorage.saveProfile(_profile);
    await _localStorage.saveComments(_eventComments);
    await _localStorage.saveNotifications(_notifications);

    try {
      if (_remoteStorage == null) return;
      for (final event in _events) {
        await _remoteStorage!.upsertEvent(event);
      }
      await _remoteStorage!.saveProfile(_profile);
      await _remoteStorage!.saveCommentsMap(_eventComments);
    } catch (_) {
      // Keep app usable offline; local data is already saved.
    }
  }

  Future<void> _syncAttendee(
    Event event, {
    required bool going,
    required bool wasGoing,
  }) async {
    if (going == wasGoing) return;
    try {
      final uid =
          await getIt<AuthRepository>().currentUserId() ?? _currentUserId;
      final profile = await ProfilePersistence().read(uid) ?? _profile;
      await MeetingRepository().setEventGoing(
        eventId: event.id,
        uid: uid,
        interestsSnapshot: profile.interests,
        going: going,
      );
    } catch (_) {}
  }

  void _onListScroll() {
    if (_selectedTabIndex != 0) return;
    if (!_scrollController.hasClients) return;
    final nearBottom =
        _scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 200;
    if (nearBottom &&
        !_isLoadingMore &&
        _visibleCount < _filteredEvents.length) {
      setState(() {
        _isLoadingMore = true;
      });
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          _visibleCount = (_visibleCount + _pageSize).clamp(
            0,
            _filteredEvents.length,
          );
          _isLoadingMore = false;
        });
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();
    final city = _cityFilterController.text.trim().toLowerCase();
    setState(() {
      _filteredEvents =
          _events
              .where(
                (event) =>
                    (event.title.toLowerCase().contains(query) ||
                        event.place.toLowerCase().contains(query) ||
                        event.description.toLowerCase().contains(query)) &&
                    (city.isEmpty || event.city.toLowerCase().contains(city)) &&
                    (_selectedCategory == 'Все' ||
                        event.category == _selectedCategory) &&
                    (!_freeOnly || event.price == 0) &&
                    (_selectedFilterDate == null ||
                        (event.date.year == _selectedFilterDate!.year &&
                            event.date.month == _selectedFilterDate!.month &&
                            event.date.day == _selectedFilterDate!.day)),
              )
              .toList();
      _visibleCount = _pageSize.clamp(0, _filteredEvents.length);
    });
  }

  List<Event> _eventsForCurrentTab() {
    switch (_selectedTabIndex) {
      case 1:
        return _myEvents;
      case 2:
        return _events.where((event) => event.isBookmarked).toList();
      case 3:
        return _events.where((event) => event.hasTicket).toList();
      default:
        return _filteredEvents.take(_visibleCount).toList();
    }
  }

  void _reloadEvents() {
    try {
      setState(() {
        _searchController.clear();
        _cityFilterController.clear();
        _selectedCategory = 'Все';
        _freeOnly = false;
        _selectedFilterDate = null;
      });
      _applyFilters();
      _syncNotifications();
      _persistState();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Данные обновлены')));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось обновить данные. Попробуйте еще раз.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cityFilterController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _syncNotifications() {
    final now = DateTime.now();
    final upcoming =
        _events
            .where(
              (event) =>
                  event.date.isAfter(now) &&
                  event.date.difference(now).inHours <= 24,
            )
            .map(
              (event) =>
                  'Скоро событие: ${event.title} (${DateFormat('d MMM, HH:mm', 'ru').format(event.date)})',
            )
            .toList();
    _notifications = [
      ...upcoming,
      if (_profile.role == 'organizer') 'Режим организатора активен',
    ];
  }

  void _showAddEventPage() async {
    try {
      final event = await Navigator.push<Event>(
        context,
        MaterialPageRoute(
          builder:
              (context) => Scaffold(
                appBar: AppBar(
                  title: const Text('Новое мероприятие'),
                  centerTitle: true,
                ),
                body: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AddEventForm(ownerId: _currentUserId),
                ),
              ),
        ),
      );
      if (event != null) {
        setState(() {
          event.isCreatedByMe = true;
          _events.insert(0, event);
          _eventComments.putIfAbsent(event.id, () => []);
          _notifications.insert(0, 'Создано мероприятие: ${event.title}');
        });
        _applyFilters();
        _syncNotifications();
        _persistState();
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось сохранить мероприятие. Повторите еще раз.'),
        ),
      );
    }
  }

  List<Event> get _myEvents =>
      _events.where((event) => event.ownerId == _currentUserId).toList();

  List<Event> get _activityEvents =>
      _events
          .where(
            (event) => event.isLiked || event.isGoing || event.isBookmarked,
          )
          .toList();

  void _openEventDetails(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => EventDetailsPage(
              event: event,
              onOpenComments: () => _openCommentsPage(event),
              onOpenOrganizer: () => _openOrganizerProfile(event),
            ),
      ),
    );
  }

  void _openCommentsPage(Event event) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => CommentsPage(
              eventTitle: event.title,
              initialComments: List<String>.from(
                _eventComments[event.id] ?? [],
              ),
              onChanged: (updatedComments) {
                setState(() {
                  _eventComments[event.id] = updatedComments;
                  event.comments = updatedComments.length;
                });
                _persistState();
              },
            ),
      ),
    );
  }

  void _openOrganizerProfile(Event event) {
    final organizerEvents =
        _events.where((item) => item.ownerId == event.ownerId).toList();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => OrganizerProfilePage(
              organizerName: event.organizerName,
              events: organizerEvents,
              onOpenEvent: _openEventDetails,
            ),
      ),
    );
  }

  Future<void> _openProfilePage() async {
    try {
      final result = await Navigator.of(context).push<UserProfile>(
        MaterialPageRoute(
          builder: (_) => ProfilePage(initialProfile: _profile),
        ),
      );
      if (result == null) return;
      setState(() {
        _profile = result;
      });
      _syncNotifications();
      _persistState();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не удалось открыть профиль. Попробуйте еще раз.'),
        ),
      );
    }
  }

  Future<void> _editEvent(Event event) async {
    final edited = await Navigator.push<Event>(
      context,
      MaterialPageRoute(
        builder:
            (_) => Scaffold(
              appBar: AppBar(title: const Text('Редактирование мероприятия')),
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: AddEventForm(
                  ownerId: _currentUserId,
                  initialEvent: event,
                ),
              ),
            ),
      ),
    );
    if (edited == null) return;
    final index = _events.indexWhere((item) => item.id == event.id);
    if (index == -1) return;
    setState(() {
      _events[index] = edited.copyWith(isCreatedByMe: true);
      _notifications.insert(0, 'Мероприятие обновлено: ${edited.title}');
    });
    _applyFilters();
    _persistState();
  }

  void _deleteEvent(Event event) {
    setState(() {
      _events.removeWhere((item) => item.id == event.id);
      _eventComments.remove(event.id);
      _notifications.insert(0, 'Удалено мероприятие: ${event.title}');
    });
    _applyFilters();
    _persistState();
    Future<void>(() async {
      try {
        await _remoteStorage?.deleteEvent(event.id);
      } catch (_) {
        // Local state already updated and persisted.
      }
    });
  }

  void _toggleTicketUsed(Event event) {
    setState(() {
      event.isTicketUsed = !event.isTicketUsed;
      _notifications.insert(
        0,
        event.isTicketUsed
            ? 'Билет отмечен как использованный: ${event.title}'
            : 'Билет снова активен: ${event.title}',
      );
    });
    _persistState();
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => Scaffold(
              appBar: AppBar(title: const Text('Уведомления')),
              body:
                  _notifications.isEmpty
                      ? const Center(child: Text('Уведомлений пока нет'))
                      : ListView.builder(
                        itemCount: _notifications.length,
                        itemBuilder:
                            (_, index) =>
                                ListTile(title: Text(_notifications[index])),
                      ),
            ),
      ),
    );
  }

  Widget _buildFeedList() {
    if (_initialLoading) {
      return ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: 4,
        itemBuilder: (_, __) => const EventSkeletonCard(),
      );
    }
    final items = _eventsForCurrentTab();
    if (items.isEmpty) {
      return EmptyStateView(
        icon: Icons.event_note_outlined,
        title: 'Нет мероприятий',
        subtitle: 'Попробуйте изменить фильтры или обновить ленту',
        action: OutlinedButton.icon(
          onPressed: _reloadEvents,
          icon: const Icon(Icons.refresh),
          label: const Text('Обновить'),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: items.length + (_isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final event = items[index];
        return EventCard(
          event: event,
          onOpen: () => _openEventDetails(event),
          onLike: () {
            setState(() {
              event.isLiked = !event.isLiked;
              event.likes += event.isLiked ? 1 : -1;
            });
            _persistState();
          },
          onGoing: () {
            final wasGoing = event.isGoing;
            setState(() {
              event.isGoing = !event.isGoing;
              event.going += event.isGoing ? 1 : -1;
            });
            _persistState();
            _syncAttendee(event, going: event.isGoing, wasGoing: wasGoing);
          },
          onBookmark: () {
            setState(() {
              event.isBookmarked = !event.isBookmarked;
            });
            _persistState();
          },
          onBuyTicket: () {
            setState(() {
              event.hasTicket = true;
            });
            _persistState();
          },
          onComment: () => _openCommentsPage(event),
        );
      },
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 1:
        return MyEventsPage(
          events: _myEvents,
          onOpenEvent: _openEventDetails,
          onEditEvent: _editEvent,
          onDeleteEvent: _deleteEvent,
        );
      case 2:
        return FavoritesPage(
          events: _events.where((event) => event.isBookmarked).toList(),
          onOpenEvent: _openEventDetails,
        );
      case 3:
        return MyTicketsPage(
          events: _events.where((event) => event.hasTicket).toList(),
          onOpenEvent: _openEventDetails,
          onToggleUsed: _toggleTicketUsed,
        );
      case 4:
        return MyActivityPage(
          events: _activityEvents,
          onOpenEvent: _openEventDetails,
        );
      default:
        return _buildFeedList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventa'),
        titleTextStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: cs.onSurface,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Встречи',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MeetingsCatalogPage()),
              );
            },
            icon: const Icon(Icons.groups_outlined),
          ),
          IconButton(
            tooltip: 'Заведения',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (_) => VenuesPage(
                        initialCity:
                            _profile.city.isEmpty ? null : _profile.city,
                      ),
                ),
              );
            },
            icon: const Icon(Icons.storefront_outlined),
          ),
          IconButton(
            onPressed: _openNotifications,
            icon: const Icon(Icons.notifications_outlined),
          ),
          IconButton(
            onPressed: _openProfilePage,
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selectedTabIndex == 0) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Поиск мероприятий',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cityFilterController,
                      onChanged: (_) => _applyFilters(),
                      decoration: const InputDecoration(
                        hintText: 'Город',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedCategory,
                    items: const [
                      DropdownMenuItem(value: 'Все', child: Text('Все')),
                      DropdownMenuItem(value: 'Музыка', child: Text('Музыка')),
                      DropdownMenuItem(value: 'Бизнес', child: Text('Бизнес')),
                      DropdownMenuItem(
                        value: 'Образование',
                        child: Text('Образование'),
                      ),
                      DropdownMenuItem(value: 'Спорт', child: Text('Спорт')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      _selectedCategory = value;
                      _applyFilters();
                    },
                  ),
                ],
              ),
            ),
          ],
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: KeyedSubtree(
                key: ValueKey(_selectedTabIndex),
                child: _buildTabContent(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            (_selectedTabIndex == 0 && _profile.role == 'organizer')
                ? _showAddEventPage
                : null,
        icon: const Icon(Icons.add),
        label: Text(
          _profile.role == 'organizer'
              ? 'Добавить мероприятие'
              : 'Только для организатора',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTabIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: cs.surface,
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurfaceVariant,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        showUnselectedLabels: true,
        onTap: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Лента',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.event_note_outlined),
            label: 'Мои',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark_outline),
            label: 'Избранное',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_num_outlined),
            label: 'Билеты',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_activity_outlined),
            label: 'Активность',
          ),
        ],
      ),
    );
  }
}
