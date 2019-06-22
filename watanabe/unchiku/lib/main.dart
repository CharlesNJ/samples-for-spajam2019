import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import 'package:path_provider/path_provider.dart';
import 'package:image_picker_saver/image_picker_saver.dart';

/// カメラ
CameraDescription rearCamera;

/// API Key
final String apiKey = 'gXZYooKHyfC5fITM9cyIqmOgo4Ngu_PJF3LwDmQC4tUw';

/// URL
final String url =
    'https://apiKey:$apiKey@gateway.watsonplatform.net/visual-recognition/api/v3/classify?version=2018-03-19';

final Map<int, String> nameMap = {
  1: "ラーメン",
  2: "カレーライス",
};

final Map<int, List<String>> unchikuMap = {
  1: ["ラーメンは美味しい", "メンマの素材は麻竹という竹ということは知っていましたか？"],
  2: ["カレーとライス", "カレー&ライス", "カレーのちライス", "キミにときめき恋かもねアワアワ ハングリー精神とめらんないクラクラ"],
};

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

  /// うんちくを表示しているか
  bool isDisplayUnchiku = false;

  /// 撮影した画像のパス
  String _filePath;

  /// ロード中かどうか
  bool isLooding = false;

  String targetName;

  List<String> unchiku;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(rearCamera, ResolutionPreset.low);
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
          height: MediaQuery.of(context).size.height * 0.435,
          width: MediaQuery.of(context).size.width,
          child: Padding(
            padding: EdgeInsets.fromLTRB(28, 12, 28, 12),
            child: Container(
              color: Colors.white,
              child: isLooding
                  ? CupertinoActivityIndicator()
                  : RichText(
                      text: TextSpan(
                        children: targetName != null
                            ? [
                                TextSpan(
                                  text: targetName + "\n",
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.lightBlue[300],
                                  ),
                                ),
                                TextSpan(
                                  text: (() {
                                    return unchiku
                                        .sublist(0, 3)
                                        .map((s) => "・$s")
                                        .join("\n");
                                  })(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.grey[700],
                                  ),
                                )
                              ]
                            : [
                                TextSpan(
                                  text: "写真を撮って会話の\nキッカケを作ろう!",
                                  style: TextStyle(
                                    fontSize: 28,
                                    color: Colors.grey[400],
                                  ),
                                )
                              ],
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
            ),
          ),
        ),
        Container(
          height: MediaQuery.of(context).size.height * 0.06,
          width: MediaQuery.of(context).size.width,
          child: takePictureButton(),
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
            heightFactor: 0.666666,
            child: _controller.value.isInitialized && !isDisplayUnchiku
                ? AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: Container(
                      decoration: BoxDecoration(),
                      child: CameraPreview(_controller),
                    ),
                  )
                : isDisplayUnchiku && _filePath != null
                    ? Image.asset(_filePath)
                    : Container(
                        height: MediaQuery.of(context).size.width,
                        width: MediaQuery.of(context).size.width,
                        child: Container(),
                      ),
          ),
        ),
      ),
      padding: EdgeInsets.all(12.0),
    );
  }

  Widget takePictureButton() {
    return FlatButton(
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
    );
  }

  void onTakePictureButtonPressed() {
    setState(() {
      isLooding = true;
    });
    takePicture().then((String filePath) async {
      if (mounted) {
        setState(() {
          isDisplayUnchiku = true;
          _filePath = filePath;
        });

        // String base64Image = base64Encode(File(_filePath).readAsBytesSync());
        // http.post(url, body: {
        //   'threshold': "0.6",
        //   'classifier_ids': 'DefaultCustomModel_1688366399',
        //   'images_file': base64Image,
        // }).then((response) {
        //   print('Response status: ${response.statusCode}');
        //   print('Response body: ${response.body}');
        // });

        // var request = new http.MultipartRequest("POST", Uri.parse(url));
        // request.fields["threshold"] = "0.6";
        // request.fields["classifier_ids"] = "DefaultCustomModel_1688366399";
        // contentType: new MediaType('application', 'x-tar'),

        Dio dio = Dio();
        FormData formData = new FormData.from({
          "threshold": "0.5",
          "classifier_ids": "DefaultCustomModel_1688366399",
          "images_file": new UploadFileInfo(new File(_filePath), "upload.jpg")
        });
        var response = await dio.post(url, data: formData);
        // print(response.data["images"][0]["classifiers"][0]["classes"]);
        // print(response.data['custom_classes']);
        final int targetId = response.data['custom_classes'];
        unchikuMap[targetId].shuffle();
        setState(() {
          targetName = nameMap[targetId];
          unchiku = unchikuMap[targetId];
          isLooding = false;
        });
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
