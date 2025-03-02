import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:friendstrackerapp/models/invites.dart';

class InvitesNotifier extends Notifier<Invites?>{
  @override
  Invites? build() {
    return null;
  }
  void setInvites(Invites invites){
    state = invites;
  }
}
final invitesNotifierProvider = NotifierProvider<InvitesNotifier, Invites?>(()  {
  return InvitesNotifier();
});