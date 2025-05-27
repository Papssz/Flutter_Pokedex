// lib/screens/pokemon_list_screen.dart
import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../services/pokeapi_service.dart';
import 'pokemon_detail_screen.dart';

class PokemonListScreen extends StatefulWidget {
  const PokemonListScreen({Key? key}) : super(key: key);

  @override
  State<PokemonListScreen> createState() => _PokemonListScreenState();
}

class _PokemonListScreenState extends State<PokemonListScreen> {
  final PokeApiService _pokeApiService = PokeApiService();
  final List<PokemonListItem> _pokemonList = [];
  List<PokemonListItem> _displayList = [];
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  int _offset = 0;
  final int _limit = 20;

  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  Timer? _debounce;

  String? _selectedTypeFilter;

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
    'dark': Color(0xFF705746),
    'psychic': Color(0xFFF95587),
    'bug': Color(0xFFA6B91A),
    'rock': Color(0xFFB6A136),
    'ghost': Color(0xFF735797),
    'dragon': Color(0xFF6F35FC),
    'steel': Color(0xFFB7B7CE),
    'fairy': Color(0xFFD685AD),
    'unknown': Color(0xFF68A090),
    'shadow': Color(0xFF493963),
  };

  Color _getBackgroundColorForType(String? type) {
    if (type == null) return Colors.grey[400]!;
    return _typeColors[type.toLowerCase()] ?? Colors.grey[400]!;
  }

  @override
  void initState() {
    super.initState();
    _fetchPokemon();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (!_isSearching && _scrollController.position.pixels == _scrollController.position.maxScrollExtent && !_isLoading) {
      _fetchPokemon();
    }
  }

  Future<void> _fetchPokemon() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final newPokemon = await _pokeApiService.fetchPokemonList(offset: _offset, limit: _limit);
      setState(() {
        _pokemonList.addAll(newPokemon);
        _applyFilters();
        _offset += _limit;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching Pokemon: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load Pokémon: ${e.toString()}')),
      );
    }
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _applyFilters();
      } else {
        FocusScope.of(context).requestFocus(FocusNode());
      }
    });
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<PokemonListItem> filteredList = List.from(_pokemonList);

    if (_isSearching && _searchController.text.isNotEmpty) {
      final lowerCaseQuery = _searchController.text.toLowerCase();
      filteredList = filteredList.where((pokemon) {
        return pokemon.name.toLowerCase().contains(lowerCaseQuery);
      }).toList();
    }

    if (_selectedTypeFilter != null) {
      filteredList = filteredList.where((pokemon) {
        return pokemon.primaryType?.toLowerCase() == _selectedTypeFilter!.toLowerCase();
      }).toList();
    }

    setState(() {
      _displayList = filteredList;
    });

    if (_displayList.length == 1 && (_searchController.text.isNotEmpty || _selectedTypeFilter != null)) {
      final PokemonListItem singlePokemon = _displayList.first;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PokemonDetailScreen(
            pokemonList: _pokemonList,
            initialIndex: _pokemonList.indexOf(singlePokemon),
          ),
        ),
      ).then((_) {
        setState(() {
          _isSearching = false;
          _searchController.clear();
          _selectedTypeFilter = null;
          _displayList = List.from(_pokemonList);
        });
      });
    }
  }

  void _showTypeFilterDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Filter by Type',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _typeColors.keys.length,
                  itemBuilder: (context, index) {
                    String type = _typeColors.keys.elementAt(index);
                    Color typeColor = _typeColors[type]!;
                    bool isSelected = _selectedTypeFilter == type;

                    return ChoiceChip(
                      label: Text(type.toCapitalized()),
                      selected: isSelected,
                      selectedColor: typeColor,
                      backgroundColor: typeColor.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (bool selected) {
                        setState(() {
                          _selectedTypeFilter = selected ? type : null;
                          _applyFilters();
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (_selectedTypeFilter != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedTypeFilter = null;
                      _applyFilters();
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Clear Filter'),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Image.asset(
          'assets/Pokédex_logo.png',
          height: 40,
          fit: BoxFit.contain,
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.grey,
            ),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _selectedTypeFilter != null ? Theme.of(context).primaryColor : Colors.grey,
            ),
            onPressed: _showTypeFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.black, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Search Pokemon by name or ID...',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                ),
              ),
            ),
          Expanded(
            child: _displayList.isEmpty && !_isLoading && (_searchController.text.isNotEmpty || _selectedTypeFilter != null)
                ? Center(
                    child: Text(
                      'No Pokémon found for "${_searchController.text}${_selectedTypeFilter != null ? ' (Type: ${_selectedTypeFilter!.toCapitalized()})' : ''}"',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: _displayList.length + (_isLoading && !_isSearching && _selectedTypeFilter == null ? 2 : 0),
                    itemBuilder: (context, index) {
                      if (index < _displayList.length) {
                        final pokemon = _displayList[index];
                        return _buildPokemonListItem(pokemon, index);
                      } else if (_isLoading && !_isSearching && _selectedTypeFilter == null) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return const SizedBox.shrink();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPokemonListItem(PokemonListItem pokemon, int index) {
    final Color cardColor = _getBackgroundColorForType(pokemon.primaryType);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PokemonDetailScreen(
              pokemonList: _pokemonList,
              initialIndex: _pokemonList.indexOf(pokemon),
            ),
          ),
        );
      },
      child: Card(
        color: cardColor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 10,
              right: 10,
              child: Opacity(
                opacity: 0.2,
                child: Image.asset(
                  'assets/pokeball.png',
                  width: 70,
                  height: 70,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    pokemon.name.toCapitalized(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (pokemon.primaryType != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        pokemon.primaryType!.toCapitalized(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Positioned(
              right: -5,
              bottom: -5,
              child: Hero(
                tag: pokemon.name,
                child: CachedNetworkImage(
                  imageUrl: pokemon.imageUrl,
                  placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
                  width: 90,
                  height: 90,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}