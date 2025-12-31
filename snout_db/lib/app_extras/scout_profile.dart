class ScoutProfile {
  List<String> selectedUpgrades;

  String prefixEmoji;
  String suffixEmoji;

  ScoutProfile({
    this.selectedUpgrades = const [],
    this.prefixEmoji = '',
    this.suffixEmoji = '',
  });

  Map<String, dynamic> toJson() => {
    'selectedUpgrades': selectedUpgrades,
    'prefixEmoji': prefixEmoji,
    'suffixEmoji': suffixEmoji,
  };

  static ScoutProfile fromJson(Map<String, dynamic> json) {
    return ScoutProfile(
      selectedUpgrades: List<String>.from(
        json['selectedUpgrades'] as List<dynamic>,
      ),
      prefixEmoji: json['prefixEmoji'] as String? ?? '',
      suffixEmoji: json['suffixEmoji'] as String? ?? '',
    );
  }
}
