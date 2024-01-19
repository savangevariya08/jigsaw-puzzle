import 'dart:io';
import 'package:external_path/external_path.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MaterialApp(
    home: Demo(),
  ));
}

class Demo extends StatefulWidget {
  const Demo({super.key});

  @override
  State<Demo> createState() => _DemoState();
}

class _DemoState extends State<Demo> {
  List myimages = [];
  List myimages_1 = [];
  List l1 = [];
  bool temp = false;

  List<img.Image> splitImage(
      img.Image inputImage, int horizontalPieceCount, int verticalPieceCount) {
    img.Image image = inputImage;

    final pieceWidth = (image.width / horizontalPieceCount).round();
    final pieceHeight = (image.height / verticalPieceCount).round();
    final pieceList = List<img.Image>.empty(growable: true);

    for (var y = 0; y < image.height; y += pieceHeight) {
      for (var x = 0; x < image.width; x += pieceWidth) {
        pieceList.add(img.copyCrop(image,
            x: x, y: y, width: pieceWidth, height: pieceHeight));
      }
    }
    return pieceList;
  }

  Future<File> getImageFileFromAssets(String path) async {
    final byteData = await rootBundle.load('img/$path');
    var dire_path = await ExternalPath.getExternalStoragePublicDirectory(
            ExternalPath.DIRECTORY_DOWNLOADS) +
        "/splite";
    Directory dir = Directory(dire_path);
    if (!await dir.exists()) {
      dir.create();
    }

    final file = File('${(await getTemporaryDirectory()).path}/$path');

    await file.create(recursive: true);
    await file.writeAsBytes(byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    return file;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    get();
  }

  get() async {
    var status = await Permission.storage.status;
    if (status.isDenied) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
        Permission.storage,
      ].request();
    }
    getImageFileFromAssets("jubgle.jpg").then((value) {
      img.Image? imges = img.decodeJpg(value.readAsBytesSync());
      myimages = splitImage(imges!, 3, 3);
      myimages.shuffle();
      for (int i = 0; i < myimages.length; i++) {
        myimages_1.add((img.encodeJpg(myimages[i])));
      }
      l1 = List.filled(myimages.length, true);
      temp = true;

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    double tot_width = MediaQuery.of(context).size.width;
    double con_width = (tot_width - 20) / 3;
    print("tot:$tot_width");
    print("container:$con_width");
    return Scaffold(
        body: (temp)
            ? GridView.builder(
                itemCount: myimages_1.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10),
                itemBuilder: (context, index) {
                  //   Uint8List som = img.encodeJpg(myimages[index]);
                  return (l1[index])
                      ? Draggable(
                          onDragStarted: () {
                            l1 = List.filled(myimages.length, false);
                            l1[index] = true;
                            setState(() {});
                          },
                          onDragEnd: (details) {
                            l1 = List.filled(myimages.length, true);
                            setState(() {});
                          },
                          data: index,
                          child: Container(
                            decoration: BoxDecoration(
                                image: DecorationImage(fit: BoxFit.fill,
                                    image: MemoryImage(myimages_1[index]))),
                          ),
                          feedback: Container(
                            height: con_width,
                            width: con_width,
                            decoration: BoxDecoration(
                                image: DecorationImage(fit: BoxFit.fill,
                                    image: MemoryImage(myimages_1[index]))),
                          ))
                      : DragTarget(
                          onAccept: (data) {
                            print(index);
                            var c = myimages_1[data as int];
                            myimages_1[data as int] = myimages_1[index];
                            myimages_1[index] = c;
                            setState(() {});
                          },
                          builder: (context, candidateData, rejectedData) {
                            return Container(
                              height: con_width,
                              width: con_width,
                              decoration: BoxDecoration(
                                  image: DecorationImage(fit: BoxFit.fill,
                                      image: MemoryImage(myimages_1[index]))),
                            );
                          },
                        );
                },
              )
            : CircularProgressIndicator());
  }
}
