import 'dart:async'; // Import for Timer
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../services/pokeapi_service.dart';

class PokemonDetailScreen extends StatefulWidget {
  final String? pokemonName; // Optional: for direct navigation from list

  const PokemonDetailScreen({Key? key, this.pokemonName}) : super(key: key);

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  final PokeApiService _pokeApiService = PokeApiService();
  PokemonDetail? _pokemonDetail;
  bool _isLoading = false;
  String? _errorMessage;

  Timer? _debounce; // <--- Add this for debouncing

  @override
  void initState() {
    super.initState();
    if (widget.pokemonName != null) {
      _searchController.text = widget.pokemonName!;
      _searchPokemon(_searchController.text); // Pass initial text
    }
  }

  @override
  void dispose() {
    _debounce?.cancel(); // <--- Cancel the timer when the widget is disposed
    _searchController.dispose();
    super.dispose();
  }

  // Modified search function to accept the query string
  Future<void> _searchPokemon(String query) async {
    query = query.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _pokemonDetail = null;
        _errorMessage = null; // Clear error message when search is empty
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _pokemonDetail = null; // Clear previous details
    });

    try {
      final pokemon = await _pokeApiService.fetchPokemonDetail(query);
      // Only update if the search query hasn't changed while waiting for response
      if (_searchController.text.trim().toLowerCase() == query) {
        setState(() {
          _pokemonDetail = pokemon;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (_searchController.text.trim().toLowerCase() == query) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  // This method will be called on every change in the TextField
  void _onSearchChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () { // 500ms debounce
      _searchPokemon(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokemon Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Pokemon by Name or ID',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton( // Add a clear button
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged(''); // Trigger clear search
                        },
                      )
                    : null, // No clear button if text is empty
              ),
              onChanged: _onSearchChanged, // <--- Call _onSearchChanged on text input
              onSubmitted: (_) => _searchPokemon(_searchController.text), // Still allow hitting enter
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 16),
                        ),
                      )
                    : _pokemonDetail == null
                        ? Center(
                            child: _searchController.text.isEmpty // Show different message if search box is empty
                                ? const Text(
                                    'Start typing a Pokemon name or ID to search.',
                                    style: TextStyle(fontSize: 16, color: Colors.grey),
                                  )
                                : const Text( // Show if no results for typed text
                                    'No Pokemon found with that name/ID.',
                                    style: TextStyle(fontSize: 16, color: Colors.orange),
                                  ),
                          )
                        : Expanded(
                            child: SingleChildScrollView(
                              child: _buildPokemonDetailCard(_pokemonDetail!),
                            ),
                          ),
          ],
        ),
      ),
    );
  }

  Widget _buildPokemonDetailCard(PokemonDetail pokemon) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Hero(
                tag: pokemon.name,
                child: CachedNetworkImage(
                  imageUrl: pokemon.imageUrl,
                  placeholder: (context, url) => const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error, size: 80),
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                '#${pokemon.id} ${pokemon.name.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
            ),
            const SizedBox(height: 15),
            _buildInfoRow('Types:', pokemon.types.join(', ')),
            _buildInfoRow('Abilities:', pokemon.abilities.join(', ')),
            const SizedBox(height: 15),
            const Text(
              'Base Stats:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.indigo),
            ),
            const SizedBox(height: 10),
            ...pokemon.stats.map((stat) => _buildStatRow(stat)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(Stat stat) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '${stat.name.replaceAll('-', ' ').toCapitalized()}:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: stat.baseStat / 200, // Max stat value is around 200 for better visual
              backgroundColor: Colors.grey[300],
              color: Colors.green,
              minHeight: 10,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            stat.baseStat.toString(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// Extension to capitalize the first letter of each word
extension StringCasingExtension on String {
  String toCapitalized() => length > 0
      ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}'
      : '';
  String toTitleCase() => replaceAll(RegExp(' +'), ' ')
      .split(' ')
      .map((str) => str.toCapitalized())
      .join(' ');
}