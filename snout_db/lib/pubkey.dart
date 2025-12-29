import 'package:collection/collection.dart';

// Wrapper class to handle public keys
class Pubkey {
  List<int> bytes;

  Pubkey(this.bytes);

  @override
  int get hashCode => const ListEquality().hash(bytes);

  @override
  bool operator ==(Object other) {
    return other is Pubkey && const ListEquality().equals(bytes, other.bytes);
  }

  // Short fingerprint for easier identification
  String fingerprint() => toString().substring(0, 3);

  @override
  String toString () => bytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
}
