import 'package:defcomm/features/groups/data/models/group_status.dart';
import 'package:defcomm/features/groups/presentation/bloc/group_event.dart';
import 'package:defcomm/features/secure_comms/data/models/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../domain/entities/group_entity.dart';
import '../bloc/group_bloc.dart';

class AnimatedGroupListItem extends StatefulWidget {
  final GroupEntity group;
  final bool isPending;
  final int index; 

  const AnimatedGroupListItem({
    super.key,
    required this.group,
    required this.isPending,
    required this.index,
  });

  @override
  State<AnimatedGroupListItem> createState() => _AnimatedGroupListItemState();
}

class _AnimatedGroupListItemState extends State<AnimatedGroupListItem> {
  bool _isAnimated = false;

  static const Duration _animationDuration = Duration(milliseconds: 400);
  static const double _initialOffsetY = 30.0; 

  @override
  void initState() {
    super.initState();
    Future.delayed(
      Duration(milliseconds: 100 * widget.index),
      () {
        if (mounted) {
          setState(() {
            _isAnimated = true;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color gradientEndColor = Color(0xFF242C32);

    
  
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: AnimatedContainer(
        duration: _animationDuration,
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: widget.group.status == "joined" ? LinearGradient(
            colors: [
            
              const Color(0xFF004D40),
              gradientEndColor
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: const [0.0, 0.3], 
          ) : widget.group.status == "pending" ? LinearGradient(
            colors: [
            
              const Color(0xFF4B342A),
              gradientEndColor
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: const [0.0, 0.3], 
          ) : null,
          borderRadius: BorderRadius.circular(16),
          
        ),
        transform: Matrix4.translationValues(0, _isAnimated ? 0 : _initialOffsetY, 0),
        child: AnimatedOpacity(
          duration: _animationDuration,
          opacity: _isAnimated ? 1.0 : 0.0,
          child: Card(
            color: Colors.transparent,
            shadowColor: Colors.transparent,
            child: ListTile(
              title: Text(widget.group.groupName, style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),),
              subtitle: Text(widget.group.companyName, style: GoogleFonts.poppins(
                          color: Color(0xffC8C5C5),
                          fontSize: 14,
                          fontWeight: FontWeight.w400
                        ),),
              trailing: widget.isPending
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton( 
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          tooltip: 'Accept',
                          onPressed: () {
                            debugPrint("Id:  ${widget.group.id}");
                            debugPrint("groupId:  ${widget.group.groupId}");
                            debugPrint("group_name:  ${widget.group.groupName}");
                            context.read<GroupBloc>().add(AcceptGroupInvitation(widget.group.id));
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          tooltip: 'Decline',
                          onPressed: () {
                            context.read<GroupBloc>().add(DeclineGroupInvitation(widget.group.id));
                          },
                        ),
                      ],
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}