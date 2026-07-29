import 'package:eventa/src/features/profile/domain/entities/user_profile.dart';

const double kInterestsWeight = 0.40;
const double kPlacesWeight = 0.35;
const double kZodiacWeight = 0.25;

const List<Map<String, Object>> placesQuizQuestions = [
  {
    'id': 'q1_evening',
    'text': 'Идеальный вечер — это...',
    'options': [
      'уютное кафе с разговором',
      'шумный бар с музыкой',
      'прогулка на свежем воздухе',
      'дом/спокойствие',
    ],
  },
  {
    'id': 'q2_food',
    'text': 'Кухня, которую выбираешь чаще всего',
    'options': [
      'азиатская',
      'европейская',
      'кавказская/грузинская',
      'фастфуд/стритфуд',
    ],
  },
  {
    'id': 'q3_pace',
    'text': 'На первой встрече предпочитаешь',
    'options': [
      'долгий неспешный ужин',
      'короткий кофе, посмотреть друг на друга',
      'активность (каток, квест, прогулка)',
      'что-то с элементом сюрприза',
    ],
  },
  {
    'id': 'q4_weekend',
    'text': 'Идеальные выходные',
    'options': ['поездка за город', 'городской маршрут', 'домашний отдых', 'спонтанный план'],
  },
  {
    'id': 'q5_music',
    'text': 'Фон для встречи',
    'options': ['джаз/лоуфай', 'поп-хиты', 'рок/альтернатива', 'тишина'],
  },
  {
    'id': 'q6_budget',
    'text': 'Бюджет первого свидания',
    'options': ['экономно', 'средний чек', 'люблю красиво', 'как получится'],
  },
  {
    'id': 'q7_timing',
    'text': 'Когда комфортнее знакомиться',
    'options': ['утром', 'днем', 'вечером', 'ночью'],
  },
  {
    'id': 'q8_style',
    'text': 'Стиль общения на старте',
    'options': ['много юмора', 'спокойно и глубоко', 'легко и быстро', 'зависит от человека'],
  },
];

String calculateZodiacSign(DateTime birthDate) {
  final day = birthDate.day;
  final month = birthDate.month;
  if ((month == 3 && day >= 21) || (month == 4 && day <= 19)) return 'aries';
  if ((month == 4 && day >= 20) || (month == 5 && day <= 20)) return 'taurus';
  if ((month == 5 && day >= 21) || (month == 6 && day <= 20)) return 'gemini';
  if ((month == 6 && day >= 21) || (month == 7 && day <= 22)) return 'cancer';
  if ((month == 7 && day >= 23) || (month == 8 && day <= 22)) return 'leo';
  if ((month == 8 && day >= 23) || (month == 9 && day <= 22)) return 'virgo';
  if ((month == 9 && day >= 23) || (month == 10 && day <= 22)) return 'libra';
  if ((month == 10 && day >= 23) || (month == 11 && day <= 21)) return 'scorpio';
  if ((month == 11 && day >= 22) || (month == 12 && day <= 21)) {
    return 'sagittarius';
  }
  if ((month == 12 && day >= 22) || (month == 1 && day <= 19)) {
    return 'capricorn';
  }
  if ((month == 1 && day >= 20) || (month == 2 && day <= 18)) {
    return 'aquarius';
  }
  return 'pisces';
}

int calculateAge(DateTime birthDate, {DateTime? now}) {
  final current = now ?? DateTime.now();
  var age = current.year - birthDate.year;
  final hadBirthday =
      current.month > birthDate.month ||
      (current.month == birthDate.month && current.day >= birthDate.day);
  if (!hadBirthday) age -= 1;
  return age;
}

double placesQuizScore(Map<String, String> a, Map<String, String> b) {
  final commonQuestions = a.keys.toSet().intersection(b.keys.toSet());
  if (commonQuestions.isEmpty) return 0.0;
  final matches = commonQuestions.where((q) => a[q] == b[q]).length;
  return matches / commonQuestions.length;
}

const Map<String, Set<String>> _zodiacElements = {
  'aries': {'fire'},
  'leo': {'fire'},
  'sagittarius': {'fire'},
  'taurus': {'earth'},
  'virgo': {'earth'},
  'capricorn': {'earth'},
  'gemini': {'air'},
  'libra': {'air'},
  'aquarius': {'air'},
  'cancer': {'water'},
  'scorpio': {'water'},
  'pisces': {'water'},
};

double zodiacScore(String? signA, String? signB) {
  if (signA == null || signB == null) return 0.5;
  if (signA == signB) return 0.75;
  final elementA = _zodiacElements[signA];
  final elementB = _zodiacElements[signB];
  if (elementA == null || elementB == null) return 0.5;
  if (elementA.first == elementB.first) return 0.8;
  final isFireAir =
      (elementA.first == 'fire' && elementB.first == 'air') ||
      (elementA.first == 'air' && elementB.first == 'fire');
  final isEarthWater =
      (elementA.first == 'earth' && elementB.first == 'water') ||
      (elementA.first == 'water' && elementB.first == 'earth');
  if (isFireAir || isEarthWater) return 0.7;
  return 0.4;
}

double jaccardScore(List<String> a, List<String> b) {
  if (a.isEmpty || b.isEmpty) return 0.0;
  final setA = a.map((e) => e.toLowerCase()).toSet();
  final setB = b.map((e) => e.toLowerCase()).toSet();
  final intersection = setA.intersection(setB).length;
  final union = setA.union(setB).length;
  if (union == 0) return 0.0;
  return intersection / union;
}

double datingCompatibilityScore(UserProfile a, UserProfile b) {
  final interests = jaccardScore(a.interests, b.interests);
  final places = placesQuizScore(a.placesQuizAnswers, b.placesQuizAnswers);
  final zodiac = zodiacScore(a.zodiacSign, b.zodiacSign);
  return interests * kInterestsWeight +
      places * kPlacesWeight +
      zodiac * kZodiacWeight;
}

String zodiacRuLabel(String? sign) {
  switch (sign) {
    case 'aries':
      return 'Овен';
    case 'taurus':
      return 'Телец';
    case 'gemini':
      return 'Близнецы';
    case 'cancer':
      return 'Рак';
    case 'leo':
      return 'Лев';
    case 'virgo':
      return 'Дева';
    case 'libra':
      return 'Весы';
    case 'scorpio':
      return 'Скорпион';
    case 'sagittarius':
      return 'Стрелец';
    case 'capricorn':
      return 'Козерог';
    case 'aquarius':
      return 'Водолей';
    case 'pisces':
      return 'Рыбы';
    default:
      return '—';
  }
}
