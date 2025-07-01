import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Event {
  final String title;
  final DateTime date;
  final String place;
  final String description;
  final List<String> photos;
  int likes;
  int going;
  int comments;
  bool isLiked;
  bool isGoing;
  bool isBookmarked;
  bool hasTicket;

  Event({
    required this.title,
    required this.date,
    required this.place,
    required this.description,
    required this.photos,
    this.likes = 0,
    this.going = 0,
    this.comments = 0,
    this.isLiked = false,
    this.isGoing = false,
    this.isBookmarked = false,
    this.hasTicket = false,
  });
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final List<Event> _events = [
    Event(
      title: 'Open Air Party',
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
      title: 'Startup Meetup',
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

  @override
  void initState() {
    super.initState();
    _filteredEvents = _events;
    _searchController.addListener(_onSearch);
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredEvents =
          _events
              .where(
                (event) =>
                    event.title.toLowerCase().contains(query) ||
                    event.place.toLowerCase().contains(query) ||
                    event.description.toLowerCase().contains(query),
              )
              .toList();
    });
  }

  void _showAddEventPage() async {
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
                child: _AddEventForm(),
              ),
            ),
      ),
    );
    if (event != null) {
      setState(() {
        _events.insert(0, event);
        _filteredEvents = _events;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Eventa',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск мероприятий',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child:
                _filteredEvents.isEmpty
                    ? const Center(child: Text('Нет мероприятий'))
                    : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: _filteredEvents.length,
                      itemBuilder: (context, index) {
                        final event = _filteredEvents[index];
                        return _EventCard(
                          event: event,
                          onLike: () {
                            setState(() {
                              event.isLiked = !event.isLiked;
                              event.likes += event.isLiked ? 1 : -1;
                            });
                          },
                          onGoing: () {
                            setState(() {
                              event.isGoing = !event.isGoing;
                              event.going += event.isGoing ? 1 : -1;
                            });
                          },
                          onBookmark: () {
                            setState(() {
                              event.isBookmarked = !event.isBookmarked;
                            });
                          },
                          onBuyTicket: () {
                            setState(() {
                              event.hasTicket = true;
                            });
                          },
                          onComment: () {
                            // Здесь можно реализовать переход к комментариям
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddEventPage,
        icon: const Icon(Icons.add),
        label: const Text('Добавить мероприятие'),
        backgroundColor: Colors.purpleAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onLike;
  final VoidCallback onGoing;
  final VoidCallback onBookmark;
  final VoidCallback onBuyTicket;
  final VoidCallback onComment;
  const _EventCard({
    required this.event,
    required this.onLike,
    required this.onGoing,
    required this.onBookmark,
    required this.onBuyTicket,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: PageView.builder(
                itemCount: event.photos.length,
                itemBuilder: (context, index) {
                  return Image.network(
                    event.photos[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('d MMM, HH:mm', 'ru').format(event.date),
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.place, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      event.place,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(event.description, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            event.isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color:
                                event.isLiked ? Colors.red : Colors.grey[600],
                          ),
                          onPressed: onLike,
                        ),
                        Text('${event.likes}'),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            event.isGoing ? Icons.person : Icons.person_outline,
                            color:
                                event.isGoing ? Colors.blue : Colors.grey[600],
                          ),
                          onPressed: onGoing,
                        ),
                        Text('${event.going}'),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            event.hasTicket
                                ? Icons.confirmation_num
                                : Icons.confirmation_num_outlined,
                            color:
                                event.hasTicket
                                    ? Colors.orange
                                    : Colors.grey[600],
                          ),
                          onPressed: event.hasTicket ? null : onBuyTicket,
                          tooltip:
                              event.hasTicket ? 'Билет куплен' : 'Купить билет',
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            event.isBookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color:
                                event.isBookmarked
                                    ? Colors.purple
                                    : Colors.grey[600],
                          ),
                          onPressed: onBookmark,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.comment_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: onComment,
                        ),
                        Text('${event.comments}'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddEventForm extends StatefulWidget {
  const _AddEventForm();

  @override
  State<_AddEventForm> createState() => _AddEventFormState();
}

class _AddEventFormState extends State<_AddEventForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _placeController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  final List<String> _photoUrls = [];
  final _photoController = TextEditingController();

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      locale: const Locale('ru'),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _addPhoto() {
    final url = _photoController.text.trim();
    if (url.isNotEmpty) {
      setState(() {
        _photoUrls.add(url);
        _photoController.clear();
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _photoUrls.isNotEmpty) {
      Navigator.pop(
        context,
        Event(
          title: _titleController.text.trim(),
          date: _selectedDate!,
          place: _placeController.text.trim(),
          description: _descriptionController.text.trim(),
          photos: List.from(_photoUrls),
          likes: 0,
          going: 0,
          comments: 0,
          isLiked: false,
          isGoing: false,
          isBookmarked: false,
          hasTicket: false,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Новое мероприятие',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Название'),
              validator:
                  (v) => v == null || v.isEmpty ? 'Введите название' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _placeController,
              decoration: const InputDecoration(labelText: 'Место'),
              validator: (v) => v == null || v.isEmpty ? 'Введите место' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Описание'),
              maxLines: 3,
              validator:
                  (v) => v == null || v.isEmpty ? 'Введите описание' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDate == null
                        ? 'Дата и время не выбраны'
                        : DateFormat(
                          'd MMM, HH:mm',
                          'ru',
                        ).format(_selectedDate!),
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Выбрать'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Фото (URL):'),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _photoController,
                    decoration: const InputDecoration(
                      hintText: 'Вставьте ссылку на фото',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_a_photo),
                  onPressed: _addPhoto,
                ),
              ],
            ),
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children:
                    _photoUrls
                        .map(
                          (url) => Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                url,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Добавить', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
