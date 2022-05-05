import 'package:http/http.dart' as http;

var apiClient = APIClient(http.Client());

class APIClient extends http.BaseClient {
  final http.Client _inner;

  APIClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // if (DateTime.now().isAfter(attestationExpires)) {
    //   //Attestation is expired, renew, also set the expire time to rate limit.
    //   attestationExpires = DateTime.now().add(const Duration(seconds: 10));
    //   await attest();
    // }

    // Device? device = await Device.getFromDisk();
    // request.headers['accept-version'] = apiVersion.toString();
    // request.headers['identity'] = device?.token ?? "";
    // request.headers['attestation'] = attestation;

    return _inner.send(request);
  }
}
