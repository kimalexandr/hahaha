import 'package:eventa/src/features/home/domain/entities/event.dart';
import 'package:eventa/src/features/profile/domain/entities/user_profile.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onOpen;
  final VoidCallback onLike;
  final VoidCallback onGoing;
  final VoidCallback onBookmark;
  final VoidCallback onBuyTicket;
  final VoidCallback onComment;

  const EventCard({
    super.key,
    required this.event,
    required this.onOpen,
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
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onOpen,
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
                  itemBuilder:
                      (context, index) => RetryableNetworkImage(
                        url: event.photos[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
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
                  const SizedBox(height: 4),
                  Text(
                    '${event.category} • ${event.city} • ${event.price == 0 ? 'Бесплатно' : '${event.price.toStringAsFixed(0)} тг'}',
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
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
                    children: [
                      IconButton(
                        icon: Icon(
                          event.isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: event.isLiked ? Colors.red : Colors.grey[600],
                        ),
                        onPressed: onLike,
                      ),
                      Text('${event.likes}'),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          event.isGoing ? Icons.person : Icons.person_outline,
                          color: event.isGoing ? Colors.blue : Colors.grey[600],
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
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  final UserProfile initialProfile;

  const ProfilePage({super.key, required this.initialProfile});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  String _role = 'user';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialProfile.name);
    _bioController = TextEditingController(text: widget.initialProfile.bio);
    _role = widget.initialProfile.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    Navigator.of(context).pop(
      widget.initialProfile.copyWith(
        name:
            _nameController.text.trim().isEmpty
                ? 'Пользователь'
                : _nameController.text.trim(),
        bio:
            _bioController.text.trim().isEmpty
                ? 'Без описания'
                : _bioController.text.trim(),
        role: _role,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Имя'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(labelText: 'О себе'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            // ignore: deprecated_member_use — value устарел в новых SDK; initialValue недоступен на старых Flutter.
            DropdownButtonFormField<String>(
              value: _role,
              decoration: const InputDecoration(labelText: 'Роль'),
              items: const [
                DropdownMenuItem(value: 'user', child: Text('Пользователь')),
                DropdownMenuItem(
                  value: 'organizer',
                  child: Text('Организатор'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _role = value;
                });
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Сохранить профиль'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyEventsPage extends StatelessWidget {
  final List<Event> events;
  final void Function(Event) onOpenEvent;
  final void Function(Event) onEditEvent;
  final void Function(Event) onDeleteEvent;
  const MyEventsPage({
    super.key,
    required this.events,
    required this.onOpenEvent,
    required this.onEditEvent,
    required this.onDeleteEvent,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои мероприятия')),
      body:
          events.isEmpty
              ? const Center(
                child: Text('Вы еще не добавили ни одного мероприятия'),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return ListTile(
                    title: Text(event.title),
                    subtitle: Text(
                      DateFormat('d MMM, HH:mm', 'ru').format(event.date),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'open') onOpenEvent(event);
                        if (value == 'edit') onEditEvent(event);
                        if (value == 'delete') onDeleteEvent(event);
                      },
                      itemBuilder:
                          (_) => const [
                            PopupMenuItem(
                              value: 'open',
                              child: Text('Открыть'),
                            ),
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Редактировать'),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Удалить'),
                            ),
                          ],
                    ),
                    onTap: () => onOpenEvent(event),
                  );
                },
              ),
    );
  }
}

class MyActivityPage extends StatelessWidget {
  final List<Event> events;
  final void Function(Event) onOpenEvent;
  const MyActivityPage({
    super.key,
    required this.events,
    required this.onOpenEvent,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Моя активность')),
      body:
          events.isEmpty
              ? const Center(child: Text('Пока нет активности по мероприятиям'))
              : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final tags = <String>[
                    if (event.isLiked) 'Лайк',
                    if (event.isGoing) 'Иду',
                    if (event.isBookmarked) 'Сохранено',
                  ].join(' • ');
                  return ListTile(
                    title: Text(event.title),
                    subtitle: Text(tags),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onOpenEvent(event),
                  );
                },
              ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  final List<Event> events;
  final void Function(Event) onOpenEvent;
  const FavoritesPage({
    super.key,
    required this.events,
    required this.onOpenEvent,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Избранное')),
      body:
          events.isEmpty
              ? const Center(child: Text('В избранном пока пусто'))
              : ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return ListTile(
                    title: Text(event.title),
                    subtitle: Text('${event.category} • ${event.city}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => onOpenEvent(event),
                  );
                },
              ),
    );
  }
}

class MyTicketsPage extends StatelessWidget {
  final List<Event> events;
  final void Function(Event) onOpenEvent;
  final void Function(Event) onToggleUsed;
  const MyTicketsPage({
    super.key,
    required this.events,
    required this.onOpenEvent,
    required this.onToggleUsed,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои билеты')),
      body:
          events.isEmpty
              ? const Center(child: Text('Купленных билетов пока нет'))
              : ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  final ticketCode = 'EVT-${event.id.hashCode.abs()}';
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(event.title),
                            subtitle: Text(
                              'Код билета: $ticketCode\nСтатус: ${event.isTicketUsed ? 'Использован' : 'Активен'}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => onOpenEvent(event),
                          ),
                          Center(
                            child: QrImageView(
                              data: ticketCode,
                              version: QrVersions.auto,
                              size: 120,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: OutlinedButton(
                              onPressed: () => onToggleUsed(event),
                              child: Text(
                                event.isTicketUsed
                                    ? 'Отметить как активный'
                                    : 'Отметить как использованный',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}

class CommentsPage extends StatefulWidget {
  final String eventTitle;
  final List<String> initialComments;
  final void Function(List<String>) onChanged;
  const CommentsPage({
    super.key,
    required this.eventTitle,
    required this.initialComments,
    required this.onChanged,
  });
  @override
  State<CommentsPage> createState() => _CommentsPageState();
}

class _CommentsPageState extends State<CommentsPage> {
  late List<String> _comments;
  final TextEditingController _commentController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _comments = List<String>.from(widget.initialComments);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _addComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() => _comments.insert(0, text));
    widget.onChanged(_comments);
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Обсуждение: ${widget.eventTitle}')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Написать комментарий',
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _addComment,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _comments.isEmpty
                    ? const Center(child: Text('Комментариев пока нет'))
                    : ListView.builder(
                      itemCount: _comments.length,
                      itemBuilder:
                          (context, index) =>
                              ListTile(title: Text(_comments[index])),
                    ),
          ),
        ],
      ),
    );
  }
}

class OrganizerProfilePage extends StatelessWidget {
  final String organizerName;
  final List<Event> events;
  final void Function(Event) onOpenEvent;
  const OrganizerProfilePage({
    super.key,
    required this.organizerName,
    required this.events,
    required this.onOpenEvent,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль организатора')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(organizerName),
            subtitle: Text('Событий: ${events.length}'),
          ),
          const Divider(height: 1),
          Expanded(
            child:
                events.isEmpty
                    ? const Center(
                      child: Text('У организатора пока нет событий'),
                    )
                    : ListView.builder(
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return ListTile(
                          title: Text(event.title),
                          subtitle: Text(
                            DateFormat('d MMM, HH:mm', 'ru').format(event.date),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => onOpenEvent(event),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

class EventDetailsPage extends StatelessWidget {
  final Event event;
  final VoidCallback onOpenComments;
  final VoidCallback onOpenOrganizer;
  const EventDetailsPage({
    super.key,
    required this.event,
    required this.onOpenComments,
    required this.onOpenOrganizer,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(event.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SizedBox(
            height: 220,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: RetryableNetworkImage(
                url: event.photos.first,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            DateFormat('d MMMM yyyy, HH:mm', 'ru').format(event.date),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text('${event.category} • ${event.city}'),
          const SizedBox(height: 8),
          Text(
            event.price == 0
                ? 'Цена: Бесплатно'
                : 'Цена: ${event.price.toStringAsFixed(0)} тг',
          ),
          const SizedBox(height: 8),
          Text(event.place, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
          Text(event.description, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onOpenOrganizer,
            icon: const Icon(Icons.person_outline),
            label: Text('Организатор: ${event.organizerName}'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onOpenComments,
            icon: const Icon(Icons.comment_outlined),
            label: Text('Комментарии (${event.comments})'),
          ),
        ],
      ),
    );
  }
}

class RetryableNetworkImage extends StatefulWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  const RetryableNetworkImage({
    super.key,
    required this.url,
    required this.fit,
    this.width,
    this.height,
  });
  @override
  State<RetryableNetworkImage> createState() => _RetryableNetworkImageState();
}

class _RetryableNetworkImageState extends State<RetryableNetworkImage> {
  int _retrySeed = 0;
  void _retry() => setState(() => _retrySeed++);
  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: widget.url,
      cacheKey: '${widget.url}#$_retrySeed',
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      placeholder:
          (_, __) => Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
      errorWidget:
          (_, __, ___) => Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[300],
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.grey,
                  size: 32,
                ),
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: _retry,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Повторить'),
                ),
              ],
            ),
          ),
    );
  }
}

class AddEventForm extends StatefulWidget {
  final String ownerId;
  final Event? initialEvent;
  const AddEventForm({super.key, required this.ownerId, this.initialEvent});
  @override
  State<AddEventForm> createState() => _AddEventFormState();
}

class _AddEventFormState extends State<AddEventForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _cityController = TextEditingController();
  final _placeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController(text: '0');
  String _category = 'Музыка';
  DateTime? _selectedDate;
  final List<String> _photoUrls = [];
  final _photoController = TextEditingController();
  @override
  void initState() {
    super.initState();
    final initial = widget.initialEvent;
    if (initial != null) {
      _titleController.text = initial.title;
      _cityController.text = initial.city;
      _placeController.text = initial.place;
      _descriptionController.text = initial.description;
      _priceController.text = initial.price.toStringAsFixed(0);
      _category = initial.category;
      _selectedDate = initial.date;
      _photoUrls.addAll(initial.photos);
    }
  }

  void _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
      locale: const Locale('ru'),
    );
    if (!mounted) return;
    if (picked == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (!mounted) return;
    if (time == null) return;

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

  void _addPhoto() {
    final url = _photoController.text.trim();
    if (url.isEmpty) return;
    setState(() {
      _photoUrls.add(url);
      _photoController.clear();
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Выберите дату и время')));
      return;
    }
    if (_photoUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Добавьте хотя бы одно фото (URL) и нажмите иконку +'),
        ),
      );
      return;
    }
    final initial = widget.initialEvent;
    Navigator.pop(
      context,
      Event(
        id: initial?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        createdAt: initial?.createdAt ?? DateTime.now(),
        ownerId: widget.ownerId,
        organizerName: initial?.organizerName ?? 'Вы',
        title: _titleController.text.trim(),
        city: _cityController.text.trim(),
        category: _category,
        price: double.tryParse(_priceController.text.trim()) ?? 0,
        date: _selectedDate!,
        place: _placeController.text.trim(),
        description: _descriptionController.text.trim(),
        photos: List.from(_photoUrls),
        likes: initial?.likes ?? 0,
        going: initial?.going ?? 0,
        comments: initial?.comments ?? 0,
        isLiked: initial?.isLiked ?? false,
        isGoing: initial?.isGoing ?? false,
        isBookmarked: initial?.isBookmarked ?? false,
        hasTicket: initial?.hasTicket ?? false,
        isTicketUsed: initial?.isTicketUsed ?? false,
        isCreatedByMe: true,
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _cityController.dispose();
    _placeController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _photoController.dispose();
    super.dispose();
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
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'Город'),
              validator: (v) => v == null || v.isEmpty ? 'Введите город' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _placeController,
              decoration: const InputDecoration(labelText: 'Место'),
              validator: (v) => v == null || v.isEmpty ? 'Введите место' : null,
            ),
            const SizedBox(height: 12),
            // ignore: deprecated_member_use — см. комментарий у DropdownButtonFormField «Роль».
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Категория'),
              items: const [
                DropdownMenuItem(value: 'Музыка', child: Text('Музыка')),
                DropdownMenuItem(value: 'Бизнес', child: Text('Бизнес')),
                DropdownMenuItem(
                  value: 'Образование',
                  child: Text('Образование'),
                ),
                DropdownMenuItem(value: 'Спорт', child: Text('Спорт')),
              ],
              onChanged:
                  (value) => setState(() => _category = value ?? _category),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Цена (0 = бесплатно)',
              ),
              validator: (v) {
                final parsed = double.tryParse((v ?? '').trim());
                if (parsed == null || parsed < 0) {
                  return 'Введите корректную цену';
                }
                return null;
              },
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
                              child: RetryableNetworkImage(
                                url: url,
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
                child: Text(
                  widget.initialEvent == null
                      ? 'Добавить'
                      : 'Сохранить изменения',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
