import 'dart:convert';

class EncryptedSecretKey {
  final List<int> salt;
  final List<int> iv;
  final String protocol;
  final String kd;
  final int t;
  final List<int> encryptedKey;

  EncryptedSecretKey({
    required this.salt,
    required this.iv,
    required this.protocol,
    required this.kd,
    required this.t,
    required this.encryptedKey,
  });

  factory EncryptedSecretKey.fromJson(Map<String, dynamic> json) {
    return EncryptedSecretKey(
      salt: base64Decode(json['salt'] as String),
      iv: base64Decode(json['iv'] as String),
      protocol: json['protocol'] as String,
      kd: json['kd'] as String,
      t: json['t'] as int,
      encryptedKey: base64Decode(json['encryptedKey'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'salt': base64Encode(salt),
      'iv': base64Encode(iv),
      'protocol': protocol,
      'kd': kd,
      't': t,
      'encryptedKey': base64Encode(encryptedKey),
    };
  }

  @override
  String toString() => jsonEncode(toJson());
}
