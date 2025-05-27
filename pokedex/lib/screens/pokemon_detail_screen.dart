import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/pokemon.dart';
import '../services/pokeapi_service.dart';

class PokemonDetailScreen extends StatefulWidget {
  final String? pokemonName;
  final List<PokemonListItem>? pokemonList;
  final int? initialIndex;

  const PokemonDetailScreen({
    Key? key,
    this.pokemonName,
    this.pokemonList,
    this.initialIndex,
  }) : super(key: key);

  @override
  State<PokemonDetailScreen> createState() => _PokemonDetailScreenState();
}

class _PokemonDetailScreenState extends State<PokemonDetailScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final PokeApiService _pokeApiService = PokeApiService();
  PokemonDetail? _pokemonDetail;
  bool _isLoading = false;
  String? _errorMessage;

  Timer? _debounce;
  late TabController _tabController;

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

  Color _getBackgroundColorForType(String? type) {
    if (type == null) return Colors.grey[400]!;
    return _typeColors[type.toLowerCase()] ?? Colors.grey[400]!;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Assuming 2 tabs: About and Base Stats
    if (widget.pokemonList != null && widget.initialIndex != null && widget.initialIndex! < widget.pokemonList!.length) {
      // Load Pokemon detail from the list if passed
      final pokemonNameFromList = widget.pokemonList![widget.initialIndex!].name;
      _searchController.text = pokemonNameFromList.toCapitalized();
      _searchPokemon(pokemonNameFromList);
    } else if (widget.pokemonName != null) {
      // Fallback to loading by name if list/index not provided
      _searchController.text = widget.pokemonName!.toCapitalized();
      _searchPokemon(widget.pokemonName!);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _searchPokemon(String query) async {
    query = query.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _pokemonDetail = null;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _pokemonDetail = null;
    });

    try {
      final pokemon = await _pokeApiService.fetchPokemonDetail(query);
      if (_searchController.text.trim().toLowerCase() == query ||
          (widget.pokemonList != null && widget.initialIndex != null &&
           widget.pokemonList![widget.initialIndex!].name.toLowerCase() == query)) {
        setState(() {
          _pokemonDetail = pokemon;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (_searchController.text.trim().toLowerCase() == query ||
          (widget.pokemonList != null && widget.initialIndex != null &&
           widget.pokemonList![widget.initialIndex!].name.toLowerCase() == query)) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _onSearchChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchPokemon(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = _getBackgroundColorForType(
      _pokemonDetail?.types.isNotEmpty == true ? _pokemonDetail!.types.first : null,
    );

    final double screenHeight = MediaQuery.of(context).size.height;
    final double cardTopPosition = screenHeight * 0.4;
    final double imageCenterOffset = 100;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: cardTopPosition + imageCenterOffset,
            child: Container(
              color: backgroundColor,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.favorite_border, color: Colors.white, size: 28),
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_pokemonDetail != null) ...[
                        Text(
                          _pokemonDetail!.name.toCapitalized(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '#${_pokemonDetail!.id.toString().padLeft(3, '0')}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: _pokemonDetail!.types.map((type) => _buildTypeChip(type)).toList(),
                        ),
                      ],
                      if (_pokemonDetail == null && (widget.pokemonList == null || widget.initialIndex == null)) ...[
                        TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          onSubmitted: (_) => _searchPokemon(_searchController.text),
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Search Pokemon',
                            labelStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Colors.white),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: cardTopPosition,
            left: 0,
            right: 0,
            bottom: 0,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _errorMessage != null
                    ? Center(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : _pokemonDetail == null
                        ? Center(
                            child: (widget.pokemonList == null || widget.initialIndex == null)
                                ? const Text(
                                    'Start typing a Pokemon name or ID to search.',
                                    style: TextStyle(fontSize: 18, color: Colors.white),
                                    textAlign: TextAlign.center,
                                  )
                                : const Text(
                                    'Failed to load Pokemon details from list.',
                                    style: TextStyle(fontSize: 18, color: Colors.white),
                                    textAlign: TextAlign.center,
                                  ),
                          )
                        : Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(30),
                                topRight: Radius.circular(30),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.only(top: imageCenterOffset + 20, left: 16.0, right: 16.0),
                              child: Column(
                                children: [
                                  TabBar(
                                    controller: _tabController,
                                    labelColor: Colors.black,
                                    unselectedLabelColor: Colors.grey,
                                    indicatorColor: backgroundColor,
                                    indicatorSize: TabBarIndicatorSize.tab,
                                    tabs: const [
                                      Tab(text: 'About'),
                                      Tab(text: 'Base Stats'),
                                    ],
                                  ),
                                  Expanded(
                                    child: TabBarView(
                                      controller: _tabController,
                                      children: [
                                        _buildAboutTab(_pokemonDetail!),
                                        _buildBaseStatsTab(_pokemonDetail!),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
          ),

          if (_pokemonDetail != null)
            Positioned(
              top: cardTopPosition - imageCenterOffset,
              left: 0,
              right: 0,
              child: Center(
                child: Hero(
                  tag: _pokemonDetail!.name,
                  child: CachedNetworkImage(
                    imageUrl: _pokemonDetail!.imageUrl,
                    placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white),
                    errorWidget: (context, url, error) => const Icon(Icons.error, size: 100, color: Colors.white),
                    width: 500,
                    height: 200,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type.toCapitalized(),
        style: const TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }

  Widget _buildAboutTab(PokemonDetail pokemon) {
    String genderInfo;
    if (pokemon.gender == -1) {
      genderInfo = 'Genderless';
    } else {
      double malePercentage = (8 - pokemon.gender) / 8 * 100;
      double femalePercentage = (pokemon.gender) / 8 * 100;
      genderInfo = '${malePercentage.toStringAsFixed(0)}% ♂, ${femalePercentage.toStringAsFixed(0)}% ♀';
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAboutInfoRow('Species', pokemon.species.toCapitalized()),
            _buildAboutInfoRow('Height', '${pokemon.height} m'),
            _buildAboutInfoRow('Weight', '${pokemon.weight} kg'),
            _buildAboutInfoRow('Abilities', pokemon.abilities.map((e) => e.toTitleCase()).join(', ')),
            const SizedBox(height: 20),
            const Text(
              'Breeding',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const Divider(),
            _buildAboutInfoRow('Gender', genderInfo),
            _buildAboutInfoRow('Egg Groups', pokemon.eggGroups.map((e) => e.toCapitalized()).join(', ')),
            _buildAboutInfoRow('Egg Cycle', pokemon.eggGroups.isNotEmpty ? pokemon.eggGroups.first.toCapitalized() : 'Unknown'),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaseStatsTab(PokemonDetail pokemon) {
    int totalStats = pokemon.stats.fold(0, (sum, stat) => sum + stat.baseStat);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...pokemon.stats.map((stat) => _buildStatRow(stat)).toList(),
            const SizedBox(height: 10),
            _buildStatRow(Stat(name: 'Total', baseStat: totalStats), isTotal: true),
            const SizedBox(height: 20),
            const Text(
              'Type Effectiveness:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const Divider(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(Stat stat, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              isTotal ? stat.name : stat.name.replaceAll('-', ' ').toCapitalized(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: isTotal ? Colors.black : Colors.black54,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              stat.baseStat.toString(),
              style: TextStyle(
                fontSize: 16,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? Colors.black : Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: LinearProgressIndicator(
                value: stat.baseStat / 200,
                backgroundColor: Colors.grey[300],
                color: stat.baseStat > 70 ? Colors.green : (stat.baseStat > 40 ? Colors.orange : Colors.red),
                minHeight: 8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension StringCasingExtension on String {
  String toCapitalized() => length > 0
      ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}'
      : '';
  String toTitleCase() => replaceAll(RegExp(' +'), ' ')
      .split(' ')
      .map((str) => str.toCapitalized())
      .join(' ');
}