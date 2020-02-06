import 'package:adhara_socket_io/adhara_socket_io.dart';

/// socket 监听接口
typedef void OnDisconnect(dynamic msg);
typedef void OnConnect(dynamic msg);
typedef void StartResponse(dynamic msg);
typedef void Offer(dynamic msg);
typedef void Answer(dynamic msg);
typedef void IceCandidate(dynamic msg);
typedef void Leave(dynamic msg);
typedef void Bye(dynamic msg);
typedef void Keepalive(dynamic msg);

class WebSocketService {
  SocketIO _client;

  String url;

  OnConnect onConnect;
  OnDisconnect onDisconnect;
  StartResponse onStartResponse;
  Offer onOffer;
  Answer onAnswer;
  IceCandidate onIceCandidate;
  Leave onLeave;
  Bye onBye;
  Keepalive onKeepalive;

  WebSocketService(this.url);

  connect() async {
    try {
      if (_client != null) {
        print('aready connect to $url , '
            'if you want to connect to other url , '
            'plz try disconnect and reconnect again.');
        return;
      }
      _client = await SocketIOManager().createInstance(SocketOptions(
        //Socket IO server URI
          url,
          nameSpace: "/",
          //Query params - can be used for authentication
//          query: {
//            "auth": "--SOME AUTH STRING---",
//            "info": "new connection from adhara-socketio",
//            "timestamp": DateTime.now().toString()
//          },
          //Enable or disable platform channel logging
          enableLogging: true,
          transports: [Transports.WEB_SOCKET/*, Transports.POLLING*/] //Enable required transport
      ));
      _client?.onConnect((data){
        print('connected');
        this.onConnect(data);
      });

      _addEventListener();

      _client?.onDisconnect((data) => this.onDisconnect(data));

      _client.connect();
    } catch (error) {
      print(error);
    }
  }

  /// 添加事件监听
  _addEventListener() {
    _client?.on('startResponse', (data) => this.onStartResponse(data));
    _client?.on('offer', (data) => this.onOffer(data));
    _client?.on('answer', (data) => this.onAnswer(data));
    _client?.on('iceCandidate', (data) => this.onIceCandidate(data));
    _client?.on('leave', (data) => this.onLeave(data));
    _client?.on('bye', (data) => this.onBye(data));
    _client?.on('keepalive', (data) => this.onKeepalive(data));
  }

  /// 发送信息
  send(eventName, data) {
    if (_client != null) {
      _client.emit(eventName, [data]);
      print('send msg {eventName: \'$eventName\', data : $data}');
    }
  }
  send2(event,data) async {
   await _client.emit("hello", [data]);
    print("send msg $event $data");
  }

  /// 关闭 socket
  close() {
    SocketIOManager().clearInstance(_client);
    print('close socket io');
  }
}
