import 'package:defcomm/core/error/failures.dart';
import 'package:defcomm/features/groups/domain/entities/group_entity.dart';
import 'package:defcomm/features/groups/domain/usecases/accept_invitation.dart';
import 'package:defcomm/features/groups/domain/usecases/decline_invitation.dart';
import 'package:defcomm/features/groups/domain/usecases/get_group.dart';
import 'package:defcomm/features/groups/domain/usecases/get_pending_groups.dart';
import 'package:defcomm/features/groups/presentation/bloc/group_event.dart';
import 'package:defcomm/features/groups/presentation/bloc/group_state.dart';
import 'package:defcomm/features/messaging/domain/usecases/get_cached_groups.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';





class GroupBloc extends Bloc<GroupEvent, GroupState> {
  final GetJoinedGroups getJoinedGroups;
  final GetPendingGroups getPendingGroups;
  final AcceptInvitation acceptInvitation;
  final DeclineInvitation declineInvitation; 

  final GetCachedGroups getCachedGroups; 

  GroupBloc({
    required this.getJoinedGroups,
    required this.getPendingGroups,
    required this.acceptInvitation,
    required this.declineInvitation, 

    required this.getCachedGroups,


  }) : super(GroupInitial()) {
    on<FetchAllGroups>(_onFetchAllGroups);
    on<AcceptGroupInvitation>(_onAccept);
    on<DeclineGroupInvitation>(_onDecline); 
  }

  Future<void> _onFetchAllGroups(FetchAllGroups event, Emitter<GroupState> emit) async {
    // emit(GroupLoading());
    final cachedResult = await getCachedGroups();

    List<GroupEntity> cachedJoined = [];
    
    cachedResult.fold(
      (failure) {},
      (groups) {
        if (groups.isNotEmpty) {
          cachedJoined = groups;
          emit(GroupLoaded(
            joinedGroups: cachedJoined,
            pendingGroups: [], 
          ));
        }
      }
    );

    if (cachedJoined.isEmpty) {
        emit(GroupLoading());
    }

    final results = await Future.wait([
      getJoinedGroups(),
      getPendingGroups(),
    ]);

    final joinedResult = results[0];
    final pendingResult = results[1];

    Failure? potentialFailure;
    joinedResult.fold((failure) => potentialFailure = failure, (_) {});
    if (potentialFailure != null) {
      emit(GroupFailure("Failed to load your groups. Please try again."));
      return;
    }
    
    pendingResult.fold((failure) => potentialFailure = failure, (_) {});
    if (potentialFailure != null) {
      emit(GroupFailure("Failed to load pending invitations. Please try again."));
      return;
    }

    emit(GroupLoaded(
      joinedGroups: joinedResult.getOrElse((_) => []),
      pendingGroups: pendingResult.getOrElse((_) => []),
    ));
  }
  
  Future<void> _onAccept(AcceptGroupInvitation event, Emitter<GroupState> emit) async {
    final result = await acceptInvitation(event.groupId);
    debugPrint("group bloc groupid ${event.groupId}");

    result.fold(
      (failure) => emit(GroupFailure("Failed to accept invitation.")),
      (_) {
        emit(GroupActionSuccess("Invitation Accepted!"));
        add(FetchAllGroups());
      },
    );
  }

  Future<void> _onDecline(DeclineGroupInvitation event, Emitter<GroupState> emit) async {
    final result = await declineInvitation(event.groupId);

    result.fold(
      (failure) => emit(GroupFailure("Failed to decline invitation.")),
      (_) {
        emit(GroupActionSuccess("Invitation Declined"));
        add(FetchAllGroups()); 
      },
    );
  }
}