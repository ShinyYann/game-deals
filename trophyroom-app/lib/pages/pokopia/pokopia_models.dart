/// Pokopia data models
class PokopiaEvent {
  final int id;
  final String title;
  final int term;
  final String type;
  final String cover;
  final String startDatetime;
  final String url;
  PokopiaEvent({required this.id, required this.title, required this.term, required this.type, required this.cover, required this.startDatetime, required this.url});
  factory PokopiaEvent.fromJson(Map<String, dynamic> j) => PokopiaEvent(
    id: j['id'] ?? 0, title: j['title'] ?? '', term: j['term'] ?? 0,
    type: j['type'] ?? 'body', cover: j['cover'] ?? '',
    startDatetime: j['start_datetime'] ?? '', url: j['url'] ?? '',
  );
}

class PokopiaNews {
  final int id; final String title; final String cover; final String startDatetime; final String url;
  PokopiaNews({required this.id, required this.title, required this.cover, required this.startDatetime, required this.url});
  factory PokopiaNews.fromJson(Map<String, dynamic> j) => PokopiaNews(
    id: j['id'] ?? 0, title: j['title'] ?? '',
    cover: j['cover'] ?? '', startDatetime: j['start_datetime'] ?? '', url: j['url'] ?? '',
  );
}

class PokopiaPokemon {
  final int id; final String name; final String fullName; final String habitat;
  final String time; final String weather; final String ability; final String pokopiaId;
  PokopiaPokemon({required this.id, required this.name, required this.fullName, required this.habitat,
    required this.time, required this.weather, required this.ability, required this.pokopiaId});
  factory PokopiaPokemon.fromJson(Map<String, dynamic> j) => PokopiaPokemon(
    id: j['id'] ?? 0, name: j['name'] ?? '', fullName: j['full_name'] ?? '',
    habitat: j['habitat'] ?? '', time: j['time'] ?? '', weather: j['weather'] ?? '',
    ability: j['ability'] ?? '', pokopiaId: j['pokopia_id'] ?? '',
  );
  String get spriteUrl => 'https://media.52poke.com/pokemon/0${id.toString().padLeft(3, '0')}.png?q=80';
}

class PokopiaHabitat {
  final int id; final String name; final String requirements; final List<String> pokemon;
  PokopiaHabitat({required this.id, required this.name, required this.requirements, required this.pokemon});
  factory PokopiaHabitat.fromJson(Map<String, dynamic> j) => PokopiaHabitat(
    id: j['id'] ?? 0, name: j['name'] ?? '', requirements: j['requirements'] ?? '',
    pokemon: (j['pokemon'] as List?)?.cast<String>() ?? [],
  );
}

class PokopiaGuide {
  final String title; final String link; final String cover; final String source;
  PokopiaGuide({required this.title, required this.link, required this.cover, required this.source});
  factory PokopiaGuide.fromJson(Map<String, dynamic> j) => PokopiaGuide(
    title: j['title'] ?? '', link: j['link'] ?? '',
    cover: j['cover'] ?? '', source: j['source'] ?? '',
  );
}

class PokopiaCharacter {
  final String name; final String role;
  PokopiaCharacter({required this.name, required this.role});
  factory PokopiaCharacter.fromJson(Map<String, dynamic> j) => PokopiaCharacter(
    name: j['name'] ?? '', role: j['role'] ?? '',
  );
}

class PokopiaTown {
  final String name; final String sub; final String desc;
  PokopiaTown({required this.name, required this.sub, required this.desc});
  factory PokopiaTown.fromJson(Map<String, dynamic> j) => PokopiaTown(
    name: j['name'] ?? '', sub: j['sub'] ?? '', desc: j['desc'] ?? '',
  );
}

class PokopiaSummary {
  final String lastUpdated; final Map<String, int> counts;
  PokopiaSummary({required this.lastUpdated, required this.counts});
  factory PokopiaSummary.fromJson(Map<String, dynamic> j) => PokopiaSummary(
    lastUpdated: j['last_updated'] ?? '',
    counts: Map.from(j['counts'] ?? {}).map((k, v) => MapEntry(k, v as int)),
  );
}
