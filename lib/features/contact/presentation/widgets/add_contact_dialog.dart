import 'package:defcomm/features/app_navigation/presentation/pages/home_navr.dart';
import 'package:defcomm/features/contact/presentation/bloc/contact_bloc.dart';
import 'package:defcomm/features/contact/presentation/bloc/contact_event.dart';
import 'package:defcomm/features/contact/presentation/bloc/contact_state.dart';
import 'package:defcomm/features/messaging/presentation/pages/messaging_screen.dart';
import 'package:defcomm/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

Future<void> showAddContactDialog({
  required BuildContext context,
  required String memberId,
  required String displayName,
}) {
  final noteController = TextEditingController();

  return showDialog(
    context: context,
    builder: (dialogCtx) {
      return BlocProvider(
        create: (_) => serviceLocator<ContactBloc>(),
        child: BlocConsumer<ContactBloc, ContactState>(
          listener: (cContext, state) {
            if (state is ContactSuccess) {
              Navigator.pushAndRemoveUntil(
                context, 
                MaterialPageRoute(
                  builder: (context) => const HomeNavr(initialIndex: 1),
                ),
                (route) => false, 
              );

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }

            if (state is ContactFailure) {
              ScaffoldMessenger.of(dialogCtx).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (cContext, state) {
            final isLoading = state is ContactLoading;

            return AlertDialog(
              title: Text(
                "Add Contact",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Add $displayName to contacts?",
                    style: GoogleFonts.poppins(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: const InputDecoration(
                      labelText: "Optional note",
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(dialogCtx),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          cContext.read<ContactBloc>().add(
                            AddContactEvent(
                              contactId: memberId,
                              note: noteController.text.trim().isEmpty
                                  ? null
                                  : noteController.text.trim(),
                            ),
                          );
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Add"),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}
