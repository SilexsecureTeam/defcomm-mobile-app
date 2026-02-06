enum ShieldRevealMethod {
  tap,
  longPress,
  swipe;

  String get displayName {
    switch (this) {
      case ShieldRevealMethod.tap:
        return "Tap to reveal";
      case ShieldRevealMethod.longPress:
        return "Long press to reveal";
      case ShieldRevealMethod.swipe:
        return "Swipe to reveal";
    }
  }

  String get shortName {
    switch (this) {
      case ShieldRevealMethod.tap:
        return "Tap";
      case ShieldRevealMethod.longPress:
        return "Long Press";
      case ShieldRevealMethod.swipe:
        return "Swipe";
    }
  }
}