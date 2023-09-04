//import 'dart:html';

import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:websocket/StompSocket.dart';
import 'package:instana_agent/instana_agent.dart';
//import 'dart:io';
import 'dart:io' as io;
import 'package:http/http.dart';
import 'package:http/io_client.dart';



//import 'package:websocket/StompSocket.dart';
import 'package:websocket/UserModel.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class _InstrumentedHttpClient extends BaseClient{
  _InstrumentedHttpClient(this._inner);

  final Client _inner;

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    // TODO: implement send
    final Marker marker = await InstanaAgent.startCapture(url: request.url.toString(), method: request.method);

    StreamedResponse response;
    try {
      response = await _inner.send(request);
      marker
        ..responseStatusCode = response.statusCode
        ..responseSizeBody = response.contentLength
        ..backendTracingID = BackendTracingIDParser.fromHeadersMap(
            response.headers);
    } finally {
      await marker.finish();
    }
    return response;
    //throw UnimplementedError();
  }

  /*@override
  Future<StreamedResponse>  //send(BaseClient request) async{
    final Marker marker = await InstanaAgent.startCapture(url: request.url.toString(), method: request.method);

        StreamedResponse response;
        try{
          response = await _inner.send(request);
          marker
            ..responseStatusCode = response.statusCode
            ..responseSizeBody = response.contentLength
            ..backendTracingID = BackendTracingIDParser.fromHeadersMap(response.headers);
        } finally{
          await marker.finish();
        }

  }*/
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late StompSocket stompSocket;

  List<UserModel> users = [];

  Future<void> httpRequest() async {
    final _InstrumentedHttpClient httpClient = _InstrumentedHttpClient(Client());
    final Request request = Request("GET", Uri.parse("http://10.0.2.2:8080/socket"));
    httpClient.send(request);
  }

  @override
  void initState(){
    super.initState();
    //InstanaAgent.setup(key: 'xdKlDTKnSRGr8bYUjAV_TQ', reportingUrl: 'https://instana-server:446/eum/mobile');
    //InstanaAgent.setView('Home');
    //InstanaAgent.startCapture(url: 'http://172.16.2.3/socket', method: 'GET').then((marker) => marker
    //  ..responseStatusCode = 200
    //  ..responseSizeBody = 1000
    //  ..responseSizeBodyDecoded = 2400
    //  ..finish());
    //InstanaAgent.getSessionID();
    //setupInstana();
    //InstanaAgent.setView('Home');
    //InstanaAgent.setCollectionEnabled(true);
    //InstanaAgent.getSessionID();
    /*InstanaAgent.startCapture(url: 'http://10.0.2.2:8080/socket', method: 'GET').then((marker) => marker
      ..responseStatusCode = 200
      ..responseSizeBody = 1000
      ..responseSizeBodyDecoded = 2400
      ..finish());*/

    //reportEvent(name: 'WebsocketEvent', options: EventOptions());
    //InstanaAgent.setup(key: 'xdKlDTKnSRGr8bYUjAV_TQ', reportingUrl: 'https://instana-server:446/eum/mobile');
    InstanaAgent.setup(key: '0fOhzqC2T3ifjWin7coLwg', reportingUrl: 'https://eum-orange-saas.instana.io/mobile');
    InstanaAgent.setView('Home');
    reportEvent(name: 'WebsocketEvent_Start', options: EventOptions());
    setupStomp();
  }

  static Future<void> setMeta_Connected({required String key, required String value}) async{
    await InstanaAgent.setMeta(key: 'WebsocketConnected', value: 'Websocket Connection  has been established');
  }

  Future<void> reportEvent({required String name, required EventOptions options}) async{
    await InstanaAgent.reportEvent(
        name: 'WebsocketEvent',
        options: EventOptions()
        ..viewName = 'WebsocketEventView'
        ..startTime = DateTime.now().millisecondsSinceEpoch
        ..duration = 3 * 1000
        ,
    );
    print('WebsocketEvent dijalankan');
  }

  Future<void> reportEventDisconnect({required String name, required EventOptions options}) async{
    await InstanaAgent.reportEvent(
      name: 'WebsocketEventDisconnect',
      options: EventOptions()
        ..viewName = 'WebsocketEventDisconnect'
        ..startTime = DateTime.now().millisecondsSinceEpoch
        ..duration = 3 * 1000
      ,
    );
    print('WebsocketEvent Disconnect');
  }


  Future<void> setupInstana() async{
    await InstanaAgent.setup(key: 'xdKlDTKnSRGr8bYUjAV_TQ', reportingUrl: 'https://instana-server:446/eum/mobile');
  }

  

  void setupStomp(){
    stompSocket = StompSocket('listener/users', updateFromSocket);
    stompSocket.connect();
  }

  void updateFromSocket(Map<String, dynamic> json) {
    setState(() {
      users.add(UserModel.fromJson(json));
    });

  }

  @override
  void dispose(){
    super.dispose();
    stompSocket.disconnect();
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
        body: ListView.separated(
            itemBuilder: (context, index) => ListTile(title: Text(users[index].toString()), subtitle: Text(DateTime.now().toIso8601String()),),
            separatorBuilder: (context, index) => const Divider(),
            itemCount: users.length
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              left: 30,
              bottom: 20,
              child: FloatingActionButton(
                heroTag: 'back',
                onPressed: (){
                  setMeta_Connected(key: 'WebsocketConnected', value: 'Websocket Connection  has been established');
                  reportEvent(name: 'Connecting_WebSocket', options: EventOptions());
                  setupStomp();
                  print("Connecting");
                },

              ),
            ),
            Positioned(
                right: 30,
                bottom: 20,
                child: FloatingActionButton(
                  heroTag: 'next',
                  onPressed: (){
                    reportEventDisconnect(name: 'Disconnecting_WebSocket', options: EventOptions());
                    //dispose();
                    //SystemNavigator.pop();
                    print("Closing app");
                  },
                )
            )
          ],
        ),

      /*bottomSheet: Container(
        alignment: Alignment.bottomLeft,
        padding: EdgeInsets.all(32),
        child: ElevatedButton(
          child: Text('Connect'),
          onPressed: () async {
            print("Connecting");
            //stompSocket.disconnect();
            //SystemNavigator.pop();
            setupStomp();
            print("I COME!!");
            },
        ),
      ),
      bottomNavigationBar: Container(
        alignment: Alignment.bottomRight,
        padding: EdgeInsets.all(32),
        child: ElevatedButton(
          child: Text('Disconnect'),
          onPressed: () async{
            print('Disconnect Pressed');
            dispose();
            SystemNavigator.pop();
            print("I Quit Blyat");
          },
        ),

      ),*/
    );
  }
}

