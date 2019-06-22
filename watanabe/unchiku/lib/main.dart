import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'package:path_provider/path_provider.dart';
import 'package:image_picker_saver/image_picker_saver.dart';
import 'package:http/http.dart' as http;

CameraDescription rearCamera;

Future<void> main() async {
  print(await availableCameras());
  rearCamera = (await availableCameras()).lastWhere(
      (desc) => desc.lensDirection == CameraLensDirection.back,
      orElse: () => null);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: Home(),
    );
  }
}

/// ホーム画面
class Home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange[200],
      body: HomeBody(),
    );
  }
}

class HomeBody extends StatefulWidget {
  @override
  _HomeBodyState createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  CameraController _controller;
  bool isDisplayUnchiku = false;
  String _filePath;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(rearCamera, ResolutionPreset.high);
    _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    // 使い終わったらカメラを解放
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        _caramePreview(),
        Container(
          height: MediaQuery.of(context).size.height * 0.06,
          width: MediaQuery.of(context).size.width,
          child: FlatButton(
            color: Colors.cyan[50],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: isDisplayUnchiku
                  ? <Widget>[
                      Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        "新たなうんちくを取得",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ]
                  : <Widget>[
                      Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.camera_enhance,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        "うんちくを取得",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
            ),
            onPressed: isDisplayUnchiku
                ? onNewTakePictureButtonPressed
                : onTakePictureButtonPressed,
          ),
        )
      ],
    );
  }

  Widget _caramePreview() {
    return Container(
      color: Colors.orange[300],
      child: Transform.scale(
        scale: 0.95,
        child: ClipRect(
          child: Align(
              alignment: Alignment.center,
              heightFactor: 0.5,
              child: _controller.value.isInitialized && !isDisplayUnchiku
                  ? AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: CameraPreview(_controller),
                    )
                  : isDisplayUnchiku && _filePath != null
                      ? Image.asset(_filePath)
                      : Container()),
        ),
      ),
      padding: EdgeInsets.all(12.0),
    );
  }

  void onTakePictureButtonPressed() {
    takePicture().then((String filePath) {
      if (mounted) {
        setState(() {
          isDisplayUnchiku = true;
          _filePath = filePath;
        });
        // if (_filePath != null) print('Picture saved to $_filePath');
      }
    });
  }

  void onNewTakePictureButtonPressed() {
    setState(() {
      isDisplayUnchiku = false;
    });
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

// 画像撮影・保存処理
  Future<String> takePicture() async {
    if (!_controller.value.isInitialized) {
      return null;
    }

    Directory dir;
    if (Platform.isAndroid) {
      dir = await getExternalStorageDirectory(); // 外部ストレージに保存
    } else if (Platform.isIOS) {
      dir = await getTemporaryDirectory(); // 一時ディレクトリに保存
    } else {
      return null;
    }

    final String dirPath = '${dir.path}/Pictures/flutter_test';
    await Directory(dirPath).create(recursive: true);
    String filePath = '$dirPath/${timestamp()}.jpg';

    if (_controller.value.isTakingPicture) {
      return null;
    }

    await _controller.takePicture(filePath);

    // filePathに保存されたデータをiOSならPhotoLibrary領域にコピーする
    if (Platform.isIOS) {
      String tmpPath = filePath;
      var savedFile = File.fromUri(Uri.file(tmpPath));
      filePath = await ImagePickerSaver.saveFile(
          fileData: savedFile.readAsBytesSync());
    }

    return filePath;
  }
}
