import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';

import "package:intl/intl.dart";

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: Home());
  }
}

/// ホーム画面
class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Audio Record Test')), body: Recorder());
  }
}

/// レコーダー
class Recorder extends StatefulWidget {
  @override
  RecorderState createState() => RecorderState();
}

/// レコーダーステート
class RecorderState extends State<Recorder> {
  FlutterSound _flutterSound = new FlutterSound();
  StreamSubscription<PlayStatus> _playerSubscription;
  bool isRecording = false;
  bool isPlaying = false;
  String _uri;
  String _playerTxt = "";

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(_playerTxt),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            IconButton(
                onPressed: !isPlaying
                    ? (isRecording
                        ? onPressedRecordStopdButton
                        : onPressedRecordButton)
                    : null,
                icon:
                    Icon(isRecording ? Icons.stop : Icons.fiber_manual_record),
                color: Colors.red,
                iconSize: 128),
            IconButton(
                onPressed: _uri != null && !isRecording
                    ? (isPlaying
                        ? onPressedPlayStopButton
                        : onPressedPlayButton)
                    : null,
                icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
                color: Colors.green,
                iconSize: 128),
          ],
        )
      ],
    );
  }

  void onPressedRecordButton() async {
    final String path = await _flutterSound.startRecorder(null);
    _uri = path.replaceFirst('file:/', '');
    setState(() {
      _playerTxt = 'Recording...';
      isRecording = true;
    });
  }

  void onPressedRecordStopdButton() async {
    await _flutterSound.stopRecorder();
    setState(() {
      _playerTxt = '';
      isRecording = false;
    });
  }

  void onPressedPlayButton() async {
    await _flutterSound.startPlayer(_uri);

    _playerSubscription = _flutterSound.onPlayerStateChanged.listen((e) {
      if (e != null) {
        DateTime date =
            new DateTime.fromMillisecondsSinceEpoch(e.currentPosition.toInt());
        String txt = DateFormat('mm:ss:SS', 'en_US').format(date);
        setState(() {
          isPlaying = true;
          _playerTxt = txt.substring(0, 8);
        });
      } else {
        setState(() {
          isPlaying = false;
        });
      }
    });
  }

  void onPressedPlayStopButton() async {
    await _flutterSound.stopPlayer();
    if (_playerSubscription != null) {
      _playerSubscription.cancel();
      _playerSubscription = null;
    }
    setState(() {
      isPlaying = false;
    });
  }
}
