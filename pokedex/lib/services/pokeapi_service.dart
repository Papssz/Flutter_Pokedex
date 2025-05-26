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
    final response = await http.get(Uri.parse('$_baseUrl/pokemon/$nameOrId'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return PokemonDetail.fromJson(data);
    } else if (response.statusCode == 404) {
      throw Exception('Pokemon not found');
    } else {
      throw Exception('Failed to load Pokemon details');
    }
  }
}