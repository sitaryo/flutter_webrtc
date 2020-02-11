import 'package:flutter/material.dart';
import 'package:flutter_webrtc/rtc_video_view.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:no_bug/_service/signalingService.dart';

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
  SignalingService _signalingService = SignalingService(
      'https://trello-attachments.s3.amazonaws.com/5c07d44ba2bfcc052dd8d358/5e3a5bc4f21dfc2561a09e33/2ea9405a5f24310584f735748e233922/%E5%8F%96%E5%BC%95%E5%B1%A5%E6%AD%B4.mp4');
  SignalingService _signalingService2 = SignalingService(
      'https://trello-attachments.s3.amazonaws.com/5c07d44ba2bfcc052dd8d358/5ce2ac248bd4f30de3b393ae/dc8bce49653e40e4ed5c0e747f76725a/RPReplay_Final1558359266.MP4');

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 2; ++i) {
      RTCVideoRenderer renderer = RTCVideoRenderer();
      renderer.initialize();
      _remoteRenders.add(renderer);
    }
  }

  _addVideoAddress() async {
    _signalingService.getStream = (stream) {
      print("you get stream 1");
      _remoteRenders[0].srcObject = stream;
    };
    _signalingService.connect();

    _signalingService2.getStream = (stream) {
      print("you get stream 2");
      _remoteRenders[1].srcObject = stream;
    };

    _signalingService2.connect();
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
                        width: MediaQuery.of(context).size.width / 2,
                        height: MediaQuery.of(context).size.height / 2,
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
