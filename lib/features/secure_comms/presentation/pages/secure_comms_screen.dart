import 'package:defcomm/core/theme/app_colors.dart';
import 'package:defcomm/features/home/presentation/widgets/secure_comms_widget.dart';
import 'package:defcomm/features/secure_comms/data/models/inviter.dart';
import 'package:defcomm/features/secure_comms/data/models/notification_model.dart';
import 'package:defcomm/features/secure_comms/data/models/otp_details_model.dart';
import 'package:defcomm/features/secure_comms/presentation/widgets/comms_action_grid.dart';
import 'package:defcomm/features/secure_comms/presentation/widgets/invitation_details_content.dart';
import 'package:defcomm/features/secure_comms/presentation/widgets/notification_card.dart';
import 'package:defcomm/features/secure_comms/presentation/widgets/otp_verification_content.dart';
import 'package:defcomm/features/secure_comms/presentation/widgets/secure_comm_state.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SecureCommsScreen extends StatefulWidget {
  const SecureCommsScreen({super.key});

  @override
  State<SecureCommsScreen> createState() => _SecureCommsScreenState();
}

class _SecureCommsScreenState extends State<SecureCommsScreen> {
  int? _expandedIndex;

   var _currentView = SecureCommsView.showingList;

   

  final List<AppNotification> _initialNotifications  = [
    AppNotification(
      title: "Invitation to Join Defcomm",
      subtitle: "Opera Passage station reserved successfully.",
      type: NotificationType.success,
      // The inviter data is included directly here
      inviter: Inviter(
        name: "Silex secure lab",
        email: "adxxx@xxxxxxxx.ng",
        imageUrl:
            "images/female_soldier.jpg", 
      ),
    ),

    AppNotification(
      title: "Meeting Invitation",
      subtitle:
          "You are invited to join a meeting. If the meeting details below",
      type: NotificationType.warning,
    ),
    AppNotification(
      title: "Charger is under maintenance",
      subtitle: "Please select another charger.",
      type: NotificationType.error,
    ),
  ];


  final AppNotification _otpNotification = AppNotification(
    title: "Otp verification Code",
    subtitle: "Opera Passage station reserved successfully.",
    type: NotificationType.success,
    otpDetails: OtpDetails(qrCodeData: "https://google.com"), 
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.dashboardBackgroundColor,
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(left: 16, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCustomAppBar(context),
                  const SizedBox(height: 32),

                  const SizedBox(height: 12),
                  SecureCommsWidget(
                    showAllButton: false,
                    showNameText: true,
                    showBar: false,
                    activeIconUrl: "images/Messaging.png",
                  ),

                  const SizedBox(height: 32),

ListView.builder(
  key: const ValueKey('list'), 
  itemCount: _initialNotifications.length, 
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemBuilder: (context, index) {
    
    final notification = _initialNotifications[index];
    final bool isThisCardExpanded = _expandedIndex == index;
    final bool isAnyCardExpanded = _expandedIndex != null;

    final cardGroup = Padding(
      key: ValueKey(notification.title),
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            NotificationCard(
              notification: notification,
              isExpanded: isThisCardExpanded,
              onTap: () {
                if (notification.inviter != null) {
                  setState(() {
                    if (isThisCardExpanded) {
                      _expandedIndex = null;
                    } else {
                      _expandedIndex = index;
                    }
                  });
                }
              },
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) {
                return SizeTransition(
                  sizeFactor: animation,
                  child: child,
                );
              },
              child: isThisCardExpanded
                  ? Column(
                      key: ValueKey('details_${notification.title}'),
                      children: [
                        const SizedBox(height: 2.0),
                        InvitationDetailsContent(
                          inviter: notification.inviter!,
                          onConfirm: () {
                            setState(() {
                              _currentView = SecureCommsView.showingOtpVerification;
                            });
                          },
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) {
        return SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1.0,
          child: child,
        );
      },
      child: (!isAnyCardExpanded || isThisCardExpanded)
          ? cardGroup
          : const SizedBox.shrink(),
    );
  },
)
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildCurrentView() {
  //   if (_currentView == SecureCommsView.showingList) {
  //     // This is your existing ListView.builder
  //     return ListView.builder(
  //       key: const ValueKey('list'), // Important for AnimatedSwitcher
  //       // ... your existing ListView.builder code ...
  //       // Make sure to use the _initialNotifications list
  //       // and update the onConfirm callback... (see step 5)
  //     );
  //   } else {
  //     // This is the new OTP verification view
  //     return Column(
  //       key: const ValueKey('otp'), // Important for AnimatedSwitcher
  //       children: [
  //         NotificationCard(
  //           notification: _otpNotification,
  //           isExpanded: true, // Always expanded in this view
  //           onTap: () {}, // No action needed on tap
  //         ),
  //         const SizedBox(height: 2),
  //         OtpVerificationContent(otpDetails: _otpNotification.otpDetails!),
  //       ],
  //     );
  //   }
  // }


  Widget _buildCustomAppBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.apps, color: Colors.white, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Col Adamu j',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  'Class OPS',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ],
        ),
        const CircleAvatar(
          radius: 20,
          backgroundImage: AssetImage('images/profile_img.png'),
        ),
      ],
    );
  }
}
