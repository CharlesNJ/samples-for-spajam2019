import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';

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
    return Recorder();
  }
}

/// レコーダー
class Recorder extends StatefulWidget {
  @override
  RecorderState createState() => RecorderState();
}

/// レコーダーステート
class RecorderState extends State<Recorder> {
  /// FlutterSound
  FlutterSound _flutterSound = new FlutterSound();

  /// StreamSubscription
  StreamSubscription<PlayStatus> _playerSubscription;

  /// 録音状態
  bool isRecording = false;

  /// 再生状態
  bool isPlaying = false;

  /// 保存先ディレクトリ
  Directory _dir;

  /// 選択ファイル
  String _currentUri;

  /// プレイヤーテキスト
  String _playerTxt = "";

  @override
  void initState() {
    super.initState();
    getApplicationDocumentsDirectory().then((Directory directory) {
      _dir = directory;
      _currentUri = directory.path + '/sound.m4a';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Audio Record Test'),
          actions: <Widget>[
            IconButton(icon: Icon(Icons.list), onPressed: _pushVoiceList),
          ],
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(_playerTxt),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // 録音(停止)ボタン
                IconButton(
                    onPressed: !isPlaying
                        ? (isRecording
                            ? onPressedRecordStopdButton
                            : onPressedRecordButton)
                        : null,
                    icon: Icon(
                        isRecording ? Icons.stop : Icons.fiber_manual_record),
                    color: Colors.red,
                    iconSize: 128),
                // 再生(停止)ボタン
                IconButton(
                    onPressed: _currentUri != null && !isRecording
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
        ));
  }

  /// 録音ボタン押下時
  void onPressedRecordButton() async {
    final String currentDate =
        DateFormat('yyyyMMddmmssSS').format(DateTime.now());
    _currentUri = _dir.path + '/' + currentDate + ".m4a";
    await _flutterSound.startRecorder(_currentUri);
    setState(() {
      _playerTxt = 'Recording...';
      isRecording = true;
    });
  }

  /// 録音停止ボタン押下時処理
  void onPressedRecordStopdButton() async {
    await _flutterSound.stopRecorder();
    setState(() {
      _playerTxt = '';
      isRecording = false;
    });
  }

  /// 再生ボタン押下時処理
  void onPressedPlayButton() async {
    await _flutterSound.startPlayer(_currentUri);

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

  /// 再生停止ボタン押下時処理
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

  void _pushVoiceList() {
    // 録音データの一覧
    Iterable<Widget> tiles = _dir
        .listSync()
        .takeWhile((entity) => entity is File)
        .map((entity) => entity as File)
        .map((file) => RecordListTile(
              file,
              onPressedPlay: (file) {
                setState(() {
                  _currentUri = file.path;
                  _playerTxt = file.path.split('/').last.split('.').first;
                });
                Navigator.of(context).pop();
              },
            ));

    final List<Widget> divided = ListTile.divideTiles(
      context: context,
      tiles: tiles,
    ).toList();

    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Voice List'),
        ),
        body: Center(child: ListView(children: divided)),
      );
    }));
  }
}

/// 録音データのタイル
class RecordListTile extends StatefulWidget {
  final File file;
  final void Function(File) onPressedPlay;

  RecordListTile(this.file, {this.onPressedPlay});

  @override
  RecordListTileState createState() =>
      RecordListTileState(file, onPressedPlay: onPressedPlay);
}

/// 録音データのタイルステート
class RecordListTileState extends State<RecordListTile> {
  /// ファイル
  File file;

  /// 再生ボタン押下時の処理
  void Function(File) onPressedPlay;

  /// 編集中か
  bool isEditing = false;

  /// ファイル名
  String fileName;

  /// 一時ファイル名
  String _tmpFileName;

  /// コンストラクタ
  RecordListTileState(this.file, {this.onPressedPlay}) {
    fileName = file.uri.path.split('/').last.split('.').first;
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(fileName),
      child: ListTile(
        title: Row(
          children: [
            // 再生ボタン
            IconButton(
              icon: Icon(Icons.play_arrow),
              iconSize: 32,
              color: Colors.grey,
              onPressed: () => onPressedPlay(file),
            ),
            // 編集ボタン
            IconButton(
              icon: Icon(Icons.edit),
              iconSize: 32,
              color: Colors.grey,
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
            ),
            // ファイル名
            isEditing
                ? Flexible(
                    child: Container(
                      child: TextField(
                        autofocus: true,
                        controller: TextEditingController(text: fileName),
                        onChanged: (s) {
                          _tmpFileName = s;
                        },
                        onEditingComplete: () {
                          setState(() {
                            file = file.renameSync(file.path.replaceAll(
                                fileName + ".m4a", _tmpFileName + ".m4a"));
                            fileName = _tmpFileName;
                            isEditing = false;
                          });
                        },
                      ),
                    ),
                  )
                : Text(fileName),
          ],
        ),
      ),
      background: Container(color: Colors.red),
      confirmDismiss: (direction) async {
        return file.existsSync();
      },
      onDismissed: (direction) {
        file.deleteSync();
      },
    );
  }
}
