import 'package:flutter/material.dart';
import 'package:flutter_webrtc/rtc_video_view.dart';
import 'package:no_bug/_service/signalingService.dart';

import '_service/websocketService.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> videoUrls = List();
  List<RTCVideoRenderer> _remoteRenders = List();
  SignalingService _signalingService = SignalingService();

  _addVideoAddress() async {

//    _signalingService.send();
    RTCVideoRenderer renderer = RTCVideoRenderer();
    renderer.initialize();
    _signalingService.getStream = (stream) {

      print("you get strem!!!");
      setState(() {
        renderer.srcObject = _signalingService.remoteStreams[0];
        _remoteRenders.add(renderer);
      });
    };
    _signalingService.connect();
    // todo add video address
    // 弹出编辑视频地址列表，提供编辑功能，确认后，修改视频窗口个数
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return Center(
            child: ListView(
              children: _remoteRenders
                  .map((render) => Container(
                        margin: new EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        child: RTCVideoView(render),
                        decoration: new BoxDecoration(color: Colors.black54),
                      ))
                  .toList(),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addVideoAddress,
        tooltip: 'add',
        child: Icon(Icons.add),
      ),
    );
  }
}
