import 'dart:io';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:instana_agent/instana_agent.dart';

import 'package:web_socket_channel/io.dart';
//import 'package:instana_agent/instana_agent.dart';


class StompSocket {

  static var _nextId = 0;

  late final String destination;
  late final String hostname;
  late final Function(Map<String, dynamic>) callback;

  late WebSocket _socket;

  StompSocket(this.destination, this.callback, {this.hostname = "ws://10.0.2.2:8080/socket"});

  //StompSocket(this.destination, this.callback, {this.hostname = "wss://echo.websocket.events"});
  //StompSocket(this.destination, this.callback, {this.hostname = "ws://localhost:8080/websocket"});

  Future<void> reportEventFailedConnect({required String name, required EventOptions options}) async{
    await InstanaAgent.reportEvent(
      name: 'reportEventFailedConnect',
      options: EventOptions()
        ..viewName = 'reportEventFailedConnect'
        ..startTime = DateTime.now().millisecondsSinceEpoch
        ..duration = 3 * 1000
      ,
    );
    print('WebsocketEvent Failed Connect');
  }


  Future<void> connect() async {
    _socket = await WebSocket.connect(hostname);
    _socket.listen((dynamic _updateReceived)
    {
      print('message $_updateReceived');
    },
      onDone: (){
        debugPrint('Websocket Disconnected');
        reportEventFailedConnect(name: 'FailedConnect_WebSocket', options: EventOptions());
      }
    );
    _socket.add(_buildConnectString());
    _socket.add(_buildSubscribeString());
    /*_socket.listen((event) {
      print('Event From WS: $event');
    },
      onDone: (){
      reportEventFailedConnect(name: 'WS Failed Connect', options: EventOptions());
      print('Failed Connect');
      }
    );*/
    /*_socket = IOWebSocketChannel.connect('ws://10.0.2.2:8080/socket') as WebSocket;
    _socket.listen((dynamic message) {
      debugPrint('message $message');
            },
        onDone: (){
        debugPrint('Websocket Disconnected');
        reportEventFailedConnect(name: 'FailedConnect_WebSocket', options: EventOptions());
            },
        onError: (error){
        debugPrint('Websocket Error');
        }
          );*/

  }

  void disconnect() {
    _socket.add(_buildDisconnectString());
    // actually we should close the socket after we received the response from the server...
    // so this is not perfect...
    //_socket.close();
  }


  void _updateReceived(dynamic data) {
    final lines = data.toString().split('\n');
    if (lines.length != 0) {
      final command = lines[0];

      if (command == "RECEIPT") {
        // typically this message comes after we send the command in the disconnect() method
        reportEventFailedConnect(name: 'WebsocketEventFailed', options: EventOptions());
        print('Disconnected');
        _socket.close();
      } else if (command == "CONNECTED") {
        print('Connected successfully to $destination @ $hostname');
      } else if (command == "MESSAGE") {
        final indexOfBody = lines.indexWhere((line) => line.length == 0) + 1;

        // we dont want the last character, since it is weird.
        final bodyLine = lines[indexOfBody].substring(0, lines[indexOfBody].length - 1);

        Map<String, dynamic> json = jsonDecode(bodyLine);
        callback(json);



      }
    }
  }

  String _buildConnectString() {
    return 'CONNECT\naccept-version:1.2\nhost:$hostname\n\n\x00';
  }

  String _buildSubscribeString() {
    // we increase the nextId so that other listener don't choose the same for a subscription
    // since this could lead to strange behavior
    _nextId++;
    var id = _nextId;
    return 'SUBSCRIBE\nid:$id\ndestination:$destination\nack:client\n\n\x00';
  }

  String _buildDisconnectString() {
    return 'DISCONNECT\nreceipt:77\n\n\x00';
  }
}


