import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:ftpserverfinder/services/site_reachability.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FTP Finder',
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(title: 'BDIX FTP Finder'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  List<String> reachable = [];
  List<String> servers = [];

  @override
  void initState() {
    super.initState();
    fetchServers();
  }

  Future<void> fetchServers() async {
    final url = 'https://github.com/k4kumar/ftpserverfinder/blob/master/assets/server_list.txt'; // Update with your URL

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          servers = response.body.split('\n').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
          checkServers();
        });
      } else {
        print('Failed to load servers list');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> checkServers() async {
    List<String> reachable = [];

    for (String server in servers) {
      bool isReachable = await isServerReachable(server);
      if (isReachable) {
        reachable.add(server);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        child: Stack(
          children: [
            Image.network(
              "https://github.com/RitickSaha/glassmophism/blob/master/example/assets/bg.png?raw=true",
              fit: BoxFit.cover,
              height: double.infinity,
              width: double.infinity,
              scale: 1,
            ),
            SafeArea(
              child: Center(
                child: GlassmorphicContainer(
                    width: 350,
                    height: 750,
                    borderRadius: 20,
                    blur: 20,
                    alignment: Alignment.topCenter,
                    border: 2,
                    linearGradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFffffff).withOpacity(0.1),
                          Color(0xFFFFFFFF).withOpacity(0.05),
                        ],
                        stops: [
                          0.1,
                          1,
                        ]),
                    borderGradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFffffff).withOpacity(0.5),
                        Color((0xFFFFFFFF)).withOpacity(0.5),
                      ],
                    ),
                    child: Wrap(
                      children: [
                        const Text("Finding FTP Server...Please wait patiently.", style: TextStyle(color: Colors.white, fontSize: 20),),
                        ListView.builder(
                          itemCount: reachable.length,
                          itemBuilder: (context, index) {
                            return Card(
                              elevation: 10,
                              child: Text(reachable[index]),
                            );
                          },
                        ),
                      ],
                    )


                    //const Text("Finding FTP Server...", style: TextStyle(color: Colors.white, fontSize: 20),)
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
