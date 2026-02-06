import 'package:defcomm/core/di/service_initilaizer.dart';
import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/features/linked_devices/presenation/blocs/linked_devices_bloc.dart';
import 'package:defcomm/features/linked_devices/presenation/blocs/linked_devices_event.dart';
import 'package:defcomm/features/linked_devices/presenation/blocs/linked_devices_state.dart';
import 'package:defcomm/features/linked_devices/presenation/widgets/linked_device_tile.dart';
import 'package:defcomm/features/qr/domain/usecases/approve_qr_device.dart';
import 'package:defcomm/features/qr/domain/usecases/get_qr_status.dart';
import 'package:defcomm/features/qr/presentation/bloc/qr_approval_bloc.dart';
import 'package:defcomm/features/qr/presentation/pages/qr_scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class LinkedDevicesPage extends StatefulWidget {
  const LinkedDevicesPage({super.key});

  @override
  State<LinkedDevicesPage> createState() => _LinkedDevicesPageState();
}

class _LinkedDevicesPageState extends State<LinkedDevicesPage> {
  @override
  void initState() {
    super.initState();
    context.read<LinkedDevicesBloc>().add(LoadLinkedDevices());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.tertiaryGreen,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.dashboardBackgroundColor,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16),
                  child: _buildCustomAppBar(context, "name", "role"),
                ),

                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth > 600
                          ? 600.0
                          : double.infinity;

                      return Center(
                        child: SizedBox(
                          width: maxWidth,
                          child: Column(
                            children: [
                              // List
                              Expanded(
                                child:
                                    BlocBuilder<
                                      LinkedDevicesBloc,
                                      LinkedDevicesState
                                    >(
                                      builder: (context, state) {
                                        if (state is LinkedDevicesLoading) {
                                          return const Center(
                                            child: CircularProgressIndicator(),
                                          );
                                        }

                                        if (state is LinkedDevicesEmpty) {
                                          return const Center(
                                            child: Text(
                                              'No linked devices',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                          );
                                        }

                                        if (state is LinkedDevicesLoaded) {
                                          return ListView.separated(
                                            padding: const EdgeInsets.all(16),
                                            itemCount: state.devices.length,
                                            separatorBuilder: (_, __) =>
                                                const SizedBox(height: 12),
                                            itemBuilder: (context, index) {
                                              final device =
                                                  state.devices[index];
                                              return LinkedDeviceTile(
                                                device: device,
                                              );
                                            },
                                          );
                                        }

                                        if (state is LinkedDevicesError) {
                                          return Center(
                                            child: Text(state.message),
                                          );
                                        }

                                        return const SizedBox.shrink();
                                      },
                                    ),
                              ),

                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.qr_code),
                                    label: const Text('Link a device'),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => BlocProvider(
                                            create: (_) => QrApprovalBloc(
                                              serviceLocator<GetQrStatus>(),
                                              serviceLocator<ApproveQrDevice>(),
                                            ),
                                            child: const QrScanScreen(),
                                          ),
                                        ),
                                      ).then((_) {
                                        if (context.mounted) {
                                          context.read<LinkedDevicesBloc>().add(
                                            LoadLinkedDevices(),
                                          );
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildCustomAppBar(BuildContext context, String name, String role) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;

  return Row(
    children: [
      IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      const SizedBox(width: 12),
      Text(
        "Linked Devices",
        style: GoogleFonts.poppins(
          color: Colors.white70,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      const Spacer(),
    ],
  );
}
