class PokemonListItem {
  final String name;
  final String url;
  final String? primaryType; 

  PokemonListItem({required this.name, required this.url, this.primaryType});

  factory PokemonListItem.fromJson(Map<String, dynamic> json) {
    return PokemonListItem(
      name: json['name'],
      url: json['url'],
    );
  }

  String get imageUrl {
    final id = url.split('/').reversed.skip(1).first;
    return 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png';
  }
}

class PokemonDetail {
  final int id;
  final String name;
  final String imageUrl;
  final List<String> types;
  final List<String> abilities;
  final List<Stat> stats;
  final double height;
  final double weight;
  final String species;
  final int gender;
  final List<String> eggGroups;

  PokemonDetail({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.types,
    required this.abilities,
    required this.stats,
    required this.height,
    required this.weight,
    required this.species,
    required this.gender,
    required this.eggGroups
  });

  factory PokemonDetail.fromJson(Map<String, dynamic> json) {
    final List<String> types =
        (json['types'] as List).map((type) => type['type']['name'].toString()).toList();

    final List<String> abilities = (json['abilities'] as List)
        .map((ability) => ability['ability']['name'].toString())
        .toList();

    final List<Stat> stats =
        (json['stats'] as List).map((stat) => Stat.fromJson(stat)).toList();

    final double height = (json['height'] as int) / 10.0;
    final double weight = (json['weight'] as int) / 10.0; 
    final List<String> eggGroups = (json['egg_groups'] as List)
        .map((group) => group['name'].toString())
        .toList();

    return PokemonDetail(
      id: json['id'],
      name: json['name'],
      imageUrl: json['sprites']['front_default'] ?? '',
      types: types,
      abilities: abilities,
      stats: stats,
      height: height,
      weight: weight,
      species: json['species']['name'] ?? 'Unknown', 
      gender: json['gender_rate'] ?? -1, 
      eggGroups: eggGroups,
    );
  }
}

class Stat {
  final String name;
  final int baseStat;

  Stat({required this.name, required this.baseStat});

  factory Stat.fromJson(Map<String, dynamic> json) {
    return Stat(
      name: json['stat']['name'],
      baseStat: json['base_stat'],
    );
  }
}