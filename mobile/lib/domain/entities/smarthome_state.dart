class SmartHomeState {
  final bool isMainLightOn;
  final double lightBrightness;
  final bool isAcOn;
  final double acTemp;
  final bool isDoorLocked;
  final bool isCctvActive;

  SmartHomeState({
    required this.isMainLightOn,
    required this.lightBrightness,
    required this.isAcOn,
    required this.acTemp,
    required this.isDoorLocked,
    required this.isCctvActive,
  });

  factory SmartHomeState.initial() {
    return SmartHomeState(
      isMainLightOn: true,
      lightBrightness: 0.8,
      isAcOn: true,
      acTemp: 22.0,
      isDoorLocked: true,
      isCctvActive: true,
    );
  }

  SmartHomeState copyWith({
    bool? isMainLightOn,
    double? lightBrightness,
    bool? isAcOn,
    double? acTemp,
    bool? isDoorLocked,
    bool? isCctvActive,
  }) {
    return SmartHomeState(
      isMainLightOn: isMainLightOn ?? this.isMainLightOn,
      lightBrightness: lightBrightness ?? this.lightBrightness,
      isAcOn: isAcOn ?? this.isAcOn,
      acTemp: acTemp ?? this.acTemp,
      isDoorLocked: isDoorLocked ?? this.isDoorLocked,
      isCctvActive: isCctvActive ?? this.isCctvActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isMainLightOn': isMainLightOn,
      'lightBrightness': lightBrightness,
      'isAcOn': isAcOn,
      'acTemp': acTemp,
      'isDoorLocked': isDoorLocked,
      'isCctvActive': isCctvActive,
    };
  }

  factory SmartHomeState.fromJson(Map<String, dynamic> json) {
    return SmartHomeState(
      isMainLightOn: json['isMainLightOn'] ?? true,
      lightBrightness: (json['lightBrightness'] ?? 0.8).toDouble(),
      isAcOn: json['isAcOn'] ?? true,
      acTemp: (json['acTemp'] ?? 22.0).toDouble(),
      isDoorLocked: json['isDoorLocked'] ?? true,
      isCctvActive: json['isCctvActive'] ?? true,
    );
  }
}
