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
  1: "パン",
  2: "パスタ",
  3: "ラーメン",
};

final Map<int, List<String>> unchikuMap = {
  1: [
    "パンの消費量世界第1位は、トルコ。1人あたりの年間消費量は168kgです（2014）。日本はトルコの10分の1。",
    "キリスト教の布教によって伝来したもので、ポルトガル語「páo（ぱお）」に由来する。",
    "『パンの耳』は、『顔の端っこにある耳』があるのと同じで、パンの端っこにあるから。",
  ],
  2: [
    "日本に広まるきっかけとなったのはキユーピーの缶詰商品（1959）",
    "「ボロネーゼ(タリアテッレ（平打ち麺）)」=イタリア語 「ボロネーズ」=フランス語 「ミートソース(スパゲティ)」=日本語",
  ],
  3: [
    "ラーメン「系統」：スープ（出汁）の違い。魚介系、濃厚魚介系など。",
    "2016年におけるラーメンの外食費用の第一位は山形県。",
    "インスタントラーメン消費量１位は青森県の９２２７ｇ。",
    "第二次世界大戦後の日本各地の闇市で人気を博した。",
    "明治初期の頃は「南京そば」、明治中期ごろは「支那そば」「柳麺（りゅうめん）」「老麺（らーめん）」、戦後「中華」へと変化していった。",
  ],
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
            padding: EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Container(
                color: Colors.white,
                child: isLooding
                    ? CupertinoActivityIndicator()
                    : ListView(children: discription())),
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

  List<Widget> discription() {
    if (targetName == null) {
      return [
        Container(
          width: MediaQuery.of(context).size.width,
          child: Text(
            "写真を撮って会話の\nキッカケを作ろう!",
            style: TextStyle(
              fontSize: 28,
              color: Colors.grey[400],
            ),
          ),
        )
      ];
    }
    List<Widget> children = [];
    if (targetName != null) {
      children.add(Container(
        alignment: Alignment.center,
        width: MediaQuery.of(context).size.width,
        child: Text(
          targetName,
          softWrap: true,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.lightBlue[300],
          ),
        ),
      ));
    }

    if (unchiku != null) {
      var u = unchiku.length > 5 ? unchiku.sublist(0, 5) : unchiku;
      children.addAll(u.map(
        (s) => Container(
              width: MediaQuery.of(context).size.width,
              child: Padding(
                padding: EdgeInsets.fromLTRB(0, 6, 0, 6),
                child: Text(
                  "　$s",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ),
      ));
    }
    children = ListTile.divideTiles(
      context: context,
      tiles: children,
    ).toList();

    return children;
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
                  "新たな話題を取得",
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
                  "話題を取得",
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

        Dio dio = Dio();
        FormData formData = new FormData.from({
          "threshold": "0.7",
          "classifier_ids": "DefaultCustomModel_1131339425",
          "images_file": new UploadFileInfo(new File(_filePath), "upload.jpg")
        });
        var response = await dio.post(url, data: formData);
        print(response.data["images"][0]["classifiers"][0]["classes"][0]);
        String target =
            response.data["images"][0]["classifiers"][0]["classes"][0]["class"];
        int targetId = target == "pan" ? 1 : target == "pasta" ? 2 : 3;
        print(response.data['custom_classes']);
        // final int targetId = response.data['custom_classes'];
        if (unchikuMap[targetId] != null) {
          unchikuMap[targetId].shuffle();
          setState(() {
            targetName = nameMap[targetId];
            unchiku = unchikuMap[targetId];
            isLooding = false;
          });
        }
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
