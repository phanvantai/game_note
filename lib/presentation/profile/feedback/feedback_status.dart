enum FeedbackStatus {
  notReceived, // 0: chưa tiếp nhận
  processing, // 1: đang xử lý
  done, // 2: đã xử lý
  denied, // 3: không xử lý
}

extension FeedbackStatusX on FeedbackStatus {
  bool get isNotReceived => this == FeedbackStatus.notReceived;
  bool get isProcessing => this == FeedbackStatus.processing;
  bool get isDone => this == FeedbackStatus.done;
  bool get isDenied => this == FeedbackStatus.denied;

  String get name {
    switch (this) {
      case FeedbackStatus.notReceived:
        return 'Chưa tiếp nhận';
      case FeedbackStatus.processing:
        return 'Đang xử lý';
      case FeedbackStatus.done:
        return 'Đã xử lý';
      case FeedbackStatus.denied:
        return 'Không xử lý';
    }
  }

  static FeedbackStatus fromInt(int value) {
    switch (value) {
      case 0:
        return FeedbackStatus.notReceived;
      case 1:
        return FeedbackStatus.processing;
      case 2:
        return FeedbackStatus.done;
      case 3:
        return FeedbackStatus.denied;
      default:
        return FeedbackStatus.notReceived;
    }
  }
}
