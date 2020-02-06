import 'dart:convert';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:no_bug/_service/WebSocketService.dart';

enum SignalingState {
  CallStateNew,
  CallStateRinging,
  CallStateInvite,
  CallStateConnected,
  CallStateBye,
  ConnectionOpen,
  ConnectionClosed,
  ConnectionError,
}

typedef void GetStream(MediaStream stream);

class SignalingService {
  var _sessionId;
  var _remoteCandidates;
  RTCPeerConnection _peerConnection;

  GetStream getStream;

  List<MediaStream> remoteStreams;
  static WebSocketService _webSocketService = new WebSocketService('http://192.168.0.106:9090/scoket.io');

  Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'url': 'stun:stun.l.google.com:19302'},
      /*
       * turn server configuration example.
      {
        'url': 'turn:123.45.67.89:3478',
        'username': 'change_to_real_user',
        'credential': 'change_to_real_secret'
      },
       */
    ]
  };

  final Map<String, dynamic> _config = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  final Map<String, dynamic> _constraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };



  close() {
    _peerConnection.close();
  }

  _createPC() async {
    //    1
    _peerConnection = await _createPeerConnection();
    // create sdp offer
    //    2
    _createOffer(_peerConnection, 'https://trello-attachments.s3.amazonaws.com/5c07d44ba2bfcc052dd8d358/5e3a5bc4f21dfc2561a09e33/2ea9405a5f24310584f735748e233922/%E5%8F%96%E5%BC%95%E5%B1%A5%E6%AD%B4.mp4');
  }

  /// create pc 重要！
  _createPeerConnection() async {
    RTCPeerConnection pc = await createPeerConnection(_iceServers, _config);

    pc.onIceCandidate = (candidate) {
      _send('onIceCandidate', {
        'sdpMLineIndex': candidate.sdpMlineIndex,
        'sdpMid': candidate.sdpMid,
        'candidate': candidate.candidate,
      });
    };

    pc.onIceConnectionState = (state) {};

    pc.onAddStream = (stream) {
      // 获取视频流
      remoteStreams.add(stream);
      this.getStream(stream);
    };

    pc.onRemoveStream = (stream) {
      remoteStreams.removeWhere((it) {
        return (it.id == stream.id);
      });
    };

    return pc;
  }

  _createOffer(RTCPeerConnection pc, String media) async {
    try {
      RTCSessionDescription s = await pc.createOffer(_constraints);
      pc.setLocalDescription(s);
      _send('start', {
        'sdpOffer': s.sdp,
        'videoUrl': media,
      });
    } catch (e) {
      print(e.toString());
    }
  }

  _send(event, data) {
    _webSocketService.send(event, data);
  }

  send(){
    _webSocketService.send2("hello",{"name":"hello world"});
  }

  _createAnswer(String id, RTCPeerConnection pc, media) async {
    try {
      RTCSessionDescription s = await pc.createAnswer(_constraints);
      pc.setLocalDescription(s);
      _send('answer', {
        'to': id,
        'description': {'sdp': s.sdp, 'type': s.type},
        'session_id': this._sessionId,
      });
    } catch (e) {
      print(e.toString());
    }
  }

  void connect() async {
    // add listener
    _webSocketService.onConnect = (data) {
      print('onOpen');
      this._createPC();
    };

    _webSocketService.onDisconnect = (data) {
      print('Closed by server [$data]!');
    };

    _webSocketService.onStartResponse = (data) {
      // 3
      _peerConnection.setRemoteDescription(
          new RTCSessionDescription(data['sdpAnswer'], 'answer'));
    };

    _webSocketService.onOffer = (data) async {
      var id = data['from'];
      var description = data['description'];
      var media = data['media'];
      var sessionId = data['session_id'];
      this._sessionId = sessionId;

      var pc = await _createPeerConnection();
      _peerConnection = pc;
      await pc.setRemoteDescription(
          new RTCSessionDescription(description['sdp'], description['type']));
      await _createAnswer(id, pc, media);
      if (this._remoteCandidates.length > 0) {
        _remoteCandidates.forEach((candidate) async {
          await pc.addCandidate(candidate);
        });
        _remoteCandidates.clear();
      }
    };

    _webSocketService.onAnswer = (data) async {
      var description = data['description'];

      var pc = _peerConnection;
      if (pc != null) {
        await pc.setRemoteDescription(
            new RTCSessionDescription(description['sdp'], description['type']));
      }
    };

    _webSocketService.onIceCandidate = (data) async {
      //4
      var pc = _peerConnection;
      RTCIceCandidate candidate = new RTCIceCandidate(data['candidate'],
          data['sdpMid'], data['sdpMLineIndex']);
      if (pc != null) {
        await pc.addCandidate(candidate);
      } else {
        _remoteCandidates.add(candidate);
      }
    };

    _webSocketService.onBye = (data) {
      var sessionId = data['session_id'];
      print('bye: ' + sessionId);

      if (_peerConnection != null) {
        _peerConnection.close();
      }

      this._sessionId = null;
    };

    _webSocketService.onKeepalive = (data) {
      print('keepalive response!');
    };

    _webSocketService.onLeave = (data) {
      if (_peerConnection != null) {
        _peerConnection.close();
      }
    };
    // end of add listener

    var url = _webSocketService.url;
    print('connect to $url');
    _webSocketService.connect();
  }
}
