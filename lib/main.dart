import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:ftpserverfinder/services/site_reachability.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';


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

  RxList<String> reachable = <String>[].obs;
  RxList<String> unreachable = <String>[].obs;
  RxList<String> allSites = <String>[].obs;
  RxDouble progress = 0.0.obs;
  RxBool isStarted = false.obs;
  RxBool isLoaded = false.obs;
  RxBool isCompleted = false.obs;
  List<String> servers = [];

  @override
  void initState() {
    super.initState();
    fetchServers();
  }

  Future<void> storeServers(List<String> servers) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove("server_list");
    await prefs.setStringList('server_list', servers);
  }

  Future<void> storeCheckedServers(RxList<String> reachableList, unreachableList) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove("reachable_list");
    prefs.remove("unreachable_list");
    String reachableString = jsonEncode(reachableList.toList());
    String unreachableString = jsonEncode(unreachableList.toList());

    await prefs.setString('reachable_list', reachableString);
    await prefs.setString('unreachable_list', unreachableString);
  }

  Future<void> clearServers() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
  }

  Future<List<String>> getStoredServers() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('server_list') ?? [];
  }

  Future<void> getReachableServers() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('reachable_list');
    if (jsonString != null) {
      List<dynamic> jsonList = jsonDecode(jsonString);
      reachable.value = jsonList.map((item) => item.toString()).toList();
    }
  }

  Future<void> getUnreachableServers() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('unreachable_list');
    if (jsonString != null) {
      List<dynamic> jsonList = jsonDecode(jsonString);
      unreachable.value = jsonList.map((item) => item.toString()).toList();
    }
  }

  Future<void> fetchServers() async {
    final url = 'https://raw.githubusercontent.com/k4kumar/ftpserverfinder/master/assets/server_list.txt'; // Update with your URL

    servers = await getStoredServers();
    print("this are the stored servers $servers");
    await getReachableServers();
    print("this are the stored reachable servers $reachable");
    await getUnreachableServers();
    print("this are the stored unreachable servers $unreachable");
    if(reachable.isNotEmpty) {
      isLoaded.value = true;
      allSites.addAll(reachable);
      allSites.addAll(unreachable);
    }
    if(servers.isEmpty){
        clearServers();
        try {
          final response = await http.get(Uri.parse(url));
          print("this is the response ${response.body}");
          if (response.statusCode == 200) {
            setState(() {
              servers = response.body
                  .split(',')
                  .map((line) => line.trim().replaceAll("'", "").replaceAll("\n", ""))
                  .where((line) => line.isNotEmpty)
                  .toList();

              storeServers(servers);
              //log("this is the servers $servers");

            });
          } else {
            print('Failed to load servers list');
          }
        } catch (e) {
          print('Error: $e');
        }
      }
  }


  Future<void> checkServers() async {
    print("This is the servers $servers");
    print("Inside check server ${servers.length}");
    int i = 0;
    for (String server in servers) {
      if(isStarted.value == false){
        break;
      }
      bool isReachable = await isServerReachable(server);
      i = i + 1;
      print(i);
      progress.value = i * 100 / servers.length;
      if (isReachable) {
        reachable.add(server);
        allSites.add(server);
      }else{
        unreachable.add(server);
      }
    }
    allSites.addAll(unreachable);
    isCompleted.value = true;
    storeCheckedServers(reachable, unreachable);
    print("check service completed");
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
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Obx(()=> reachable.isEmpty? FittedBox(child: const Text("Finding FTP Server...Please wait patiently.", style: TextStyle(color: Colors.white, fontSize: 20),))
                              : FittedBox(child: Text("${reachable.length} servers found"),),
                          ),
                          Obx(() => LinearProgressIndicator(
                            value: progress.value/100,
                            backgroundColor: Colors.grey[300],
                            color: Colors.blue,
                            minHeight: 10,
                          )),
                          Obx(()=> Text("${progress.value.toPrecision(2)}% completed.")
                          ),
                          Obx(()=>ElevatedButton(
                                onPressed: () async {
                                  reinitialize();
                                  if(isStarted.value){
                                    isStarted.value = false; //used for stopping the process
                                  }else{
                                    isStarted.value = true;
                                    await checkServers();
                                    isStarted.value = false;
                                  }
                                },
                                child: Text(isStarted.value? "Stop" : "Start Test")
                            ),
                          ),
                          Obx(()=> (reachable.isEmpty && (isStarted.value || isLoaded.value))?
                          const LinearProgressIndicator() :
                          Flexible(
                            child: ListView.builder(
                              itemCount: allSites.length,
                              itemBuilder: (context, index) {
                                final site = allSites[index];
                                final isReachable = index < reachable.length; // Determine if the site is reachable

                                return Card(
                                  elevation: 10,
                                  child: InkWell(
                                    onTap: () async {
                                      await launchUrl(Uri.parse(site));
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Container(
                                              child: Text(
                                                site,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: isReachable ? Colors.blue : Colors.grey, // Different color based on reachability
                                                  decoration: TextDecoration.underline,
                                                ),
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            isReachable ? Icons.check_circle : Icons.not_interested,
                                            color: isReachable ? Colors.green : Colors.red,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },

                          ),
                          ),
                          ),
                        ],
                      ),
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

  Future<void> reinitialize() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.clear();
    allSites.clear();
    unreachable.clear();
    reachable.clear();
  }
}
