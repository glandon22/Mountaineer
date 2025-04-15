import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/home/home_bloc.dart';
import '../colors.dart';

class MountaineerAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const MountaineerAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.mossGreen,
      title: Text(title),
      actions: [
        BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) => IconButton(
            icon: Icon(
              state.isEditMode ? Icons.done : Icons.edit,
              color: AppColors.creamyOffWhite,
            ),
            tooltip: state.isEditMode ? 'Done' : 'Edit',
            onPressed: () => context.read<HomeBloc>().add(const ToggleEditMode()),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}