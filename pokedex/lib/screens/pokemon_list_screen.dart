import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../services/pokeapi_service.dart';
import '../widgets/pokemon_card.dart';
import 'pokemon_detail_screen.dart';

class PokemonListScreen extends StatefulWidget {
  const PokemonListScreen({Key? key}) : super(key: key);

  @override
  State<PokemonListScreen> createState() => _PokemonListScreenState();
}

class _PokemonListScreenState extends State<PokemonListScreen> {
  final PokeApiService _pokeApiService = PokeApiService();
  List<PokemonListItem> _pokemonList = [];
  bool _isLoading = false;
  int _offset = 0;
  final int _limit = 20;
  final ScrollController _scrollController = ScrollController();

  static const Map<String, Color> _typeColors = {
    'normal': Color(0xFFA8A77A),
    'fire': Color(0xFFEE8130),
    'water': Color(0xFF6390F0),
    'electric': Color(0xFFF7D02C),
    'grass': Color(0xFF7AC74C),
    'ice': Color(0xFF96D9D6),
    'fighting': Color(0xFFC22E28),
    'poison': Color(0xFFA33EA1),
    'ground': Color(0xFFE2BF65),
    'flying': Color(0xFFA98FF3),
    'psychic': Color(0xFFF95587),
    'bug': Color(0xFFA6B91A),
    'rock': Color(0xFFB6A136),
    'ghost': Color(0xFF735797),
    'dragon': Color(0xFF6F35FC),
    'steel': Color(0xFFB7B7CE),
    'dark': Color(0xFF705746),
    'fairy': Color(0xFFD685AD),
    'unknown': Color(0xFF68A090),
    'shadow': Color(0xFF493963),
  };

  Color _getCardColorForType(String? type) {
    if (type == null) return Colors.grey[200]!;
    return _typeColors[type.toLowerCase()] ?? Colors.grey[200]!;
  }

  @override
  void initState() {
    super.initState();
    _fetchPokemon();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !_isLoading) {
      _fetchPokemon();
    }
  }

  Future<void> _fetchPokemon() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final newPokemonItems = await _pokeApiService.fetchPokemonList(offset: _offset, limit: _limit);
      List<Future<PokemonListItem>> detailFetches = newPokemonItems.map((item) async {
        try {
          final detail = await _pokeApiService.fetchPokemonDetail(item.name);
          return PokemonListItem(
            name: item.name,
            url: item.url,
            primaryType: detail.types.isNotEmpty ? detail.types.first : null,
          );
        } catch (e) {
          return item; 
        }
      }).toList();

      List<PokemonListItem> itemsWithDetails = await Future.wait(detailFetches);

      setState(() {
        _pokemonList.addAll(itemsWithDetails);
        _offset += _limit;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading Pokemon: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokédex', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PokemonDetailScreen()),
              );
            },
          ),
        ],
      ),
      body: _pokemonList.isEmpty && _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 0.9,
              ),
              itemCount: _pokemonList.length + (_isLoading ? 2 : 0),
              itemBuilder: (context, index) {
                if (index < _pokemonList.length) {
                  final pokemon = _pokemonList[index];
                  return PokemonCard(
                    pokemon: pokemon,
                    cardColor: _getCardColorForType(pokemon.primaryType),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PokemonDetailScreen(
                            pokemonName: pokemon.name,
                          ),
                        ),
                      );
                    },
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
    );
  }
}