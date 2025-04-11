import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mountaineer/bloc/trail/trail_bloc.dart';
import 'package:flutter_map/flutter_map.dart';

class SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final MapController mapController;

  const SearchBar({super.key, required this.controller, required this.mapController});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      left: 10,
      right: 10,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Search location...',
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(12),
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => context.read<TrailBloc>().add(SearchLocation(controller.text, mapController)),
            ),
          ),
          onSubmitted: (query) => context.read<TrailBloc>().add(SearchLocation(query, mapController)),
        ),
      ),
    );
  }
}