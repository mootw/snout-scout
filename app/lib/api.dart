import 'package:app/providers/loading_status_service.dart';
import 'package:http/http.dart' as http;

final apiClient = APIClient(http.Client());

class APIClient extends http.BaseClient {
  final http.Client _inner;

  APIClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = _inner.send(request);
    loadingService.addFuture(response);
    return await response;
  }
}
