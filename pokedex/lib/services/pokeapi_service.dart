import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pokemon.dart';

class PokeApiService {
  static const String _baseUrl = 'https://pokeapi.co/api/v2';

  Future<List<PokemonListItem>> fetchPokemonList({int offset = 0, int limit = 20}) async {
    final response = await http.get(Uri.parse('$_baseUrl/pokemon?offset=$offset&limit=$limit'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> results = data['results'];
      return results.map((json) => PokemonListItem.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load Pokemon list');
    }
  }

  Future<PokemonDetail> fetchPokemonDetail(String nameOrId) async {
    final pokemonUrl = Uri.parse('$_baseUrl/pokemon/$nameOrId');
    final speciesUrl = Uri.parse('$_baseUrl/pokemon-species/$nameOrId');

    final responses = await Future.wait([
      http.get(pokemonUrl),
      http.get(speciesUrl),
    ]);

    final pokemonResponse = responses[0];
    final speciesResponse = responses[1];

    if (pokemonResponse.statusCode == 200 && speciesResponse.statusCode == 200) {
      final Map<String, dynamic> pokemonData = json.decode(pokemonResponse.body);
      final Map<String, dynamic> speciesData = json.decode(speciesResponse.body);

      pokemonData['species']['name'] = speciesData['name'];   
      pokemonData['gender_rate'] = speciesData['gender_rate'];
      pokemonData['egg_groups'] = speciesData['egg_groups'];

      return PokemonDetail.fromJson(pokemonData);
    } else if (pokemonResponse.statusCode == 404 || speciesResponse.statusCode == 404) {
      throw Exception('Pokemon not found');
    } else {
      throw Exception('Failed to load Pokemon details. Statuses: ${pokemonResponse.statusCode}, ${speciesResponse.statusCode}');
    }
  }
}