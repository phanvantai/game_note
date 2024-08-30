part of 'third_party_bloc.dart';

abstract class ThirdPartyEvent extends Equatable {
  const ThirdPartyEvent();
}

class ThirdPartySignInGoogle extends ThirdPartyEvent {
  const ThirdPartySignInGoogle();
  @override
  List<Object?> get props => [];
}

class ThirdPartySignInApple extends ThirdPartyEvent {
  const ThirdPartySignInApple();
  @override
  List<Object?> get props => [];
}
