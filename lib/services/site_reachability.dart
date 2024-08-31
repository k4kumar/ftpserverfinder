import 'package:http/http.dart' as http;

Future<bool> isServerReachable(String url) async {
  try {
    //final response = await http.head(Uri.parse(url));
    final response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 2));
    print("The site $url is ${response.statusCode == 200} reachable");
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}
