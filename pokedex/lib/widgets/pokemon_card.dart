import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../models/pokemon.dart';

class PokemonCard extends StatelessWidget {
  final PokemonListItem pokemon;
  final VoidCallback onTap;
  final Color cardColor; 

  const PokemonCard({Key? key, required this.pokemon, required this.onTap, required this.cardColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      color: cardColor, 
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Hero(
                tag: pokemon.name,
                child: CachedNetworkImage(
                  imageUrl: pokemon.imageUrl,
                  placeholder: (context, url) => const CircularProgressIndicator(color: Colors.white70),
                  errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
                  width: 80,
                  height: 80,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                pokemon.name.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 2.0,
                      color: Colors.black54,
                      offset: Offset(1.0, 1.0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}