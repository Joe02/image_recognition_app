import 'dart:io';

import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_recognition/pages/language_selection.dart';
import 'package:image_recognition/widgets/image_labeler_options.dart';
import 'package:image_recognition/widgets/image_recognition_response_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:translator/translator.dart';

class ImageRecognition extends StatefulWidget {
  final String mode;

  ImageRecognition(this.mode);

  @override
  ImageRecognitionState createState() => ImageRecognitionState();
}

class ImageRecognitionState extends State<ImageRecognition> {
  var picker = ImagePicker();
  final textLabeler = FirebaseVision.instance.textRecognizer();
  var imageFile;
  File _image;
  var containsFile = false;
  List<String> labelOptions = [];
  bool _loading = false;

  var noImageWarning = "No image selected";
  var noLabelsWarning = "No labels found";

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  SharedPreferences prefs;

  @override
  void initState() {
    super.initState();
    getImage();
    initPrefs();
  }

  initPrefs() async {
    prefs = await _prefs;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("Change language"),
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => LanguageSelection()));
                },
                child: Icon(Icons.translate),
              ),
            )
          ],
        ),
        key: _scaffoldKey,
        body: containsFile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ImageLabelerExhibition(
                    _image,
                    recognizeElementsOnImage,
                    recognizeElementsOnImageGCLOUD,
                  ),
                  _loading == true
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            CircularProgressIndicator(),
                          ],
                        )
                      : buildResponseOptionsList()
                ],
              )
            : Center(child: Text(noImageWarning)),
      ),
    );
  }

  buildResponseOptionsList() {
    return ImageRecognitionResponseList(labelOptions);
  }

  Future getImage() async {
    //Gets image from ImagePicker.camera
    final pickedFile = await picker.getImage(
      source:
          widget.mode == "Camera" ? ImageSource.camera : ImageSource.gallery,
    );
    final File file = File(pickedFile.path);

    //Sets the image to a File variable.
    setState(() {
      _image = file;
      containsFile = true;
    });
  }

  Future recognizeElementsOnImage() async {
    setState(() {
      _loading = true;
    });
    ImageLabeler recognizeImage = FirebaseVision.instance
        .imageLabeler(ImageLabelerOptions(confidenceThreshold: 0.7));

    final List<ImageLabel> recognizedLabels = await recognizeImage
        .processImage(FirebaseVisionImage.fromFilePath(_image.path));

    if (recognizedLabels.isEmpty) {
      _scaffoldKey.currentState
          .showSnackBar(new SnackBar(content: Text(noLabelsWarning)));
    } else {
      labelOptions.clear();
    }
    for (ImageLabel label in recognizedLabels) {
      //Display the most related recognized word.
//        _scaffoldKey.currentState
//            .showSnackBar(new SnackBar(content: Text(label.text)));
      final translator = GoogleTranslator();
      if (prefs.getString("Language") == "English") {
        await translator
            .translate(label.text, from: 'en', to: 'en')
            .then((value) => labelOptions.add(value.text));
      } else {
        await translator
            .translate(label.text, from: 'en', to: 'pt')
            .then((value) => labelOptions.add(value.text));
      }
    }
    setState(() {
      labelOptions = labelOptions;
      _loading = false;
    });
  }

  Future recognizeElementsOnImageGCLOUD() async {
    setState(() {
      _loading = true;
    });
    ImageLabeler recognizeImage = FirebaseVision.instance
        .cloudImageLabeler(CloudImageLabelerOptions(confidenceThreshold: 0.7));

    final List<ImageLabel> recognizedLabels = await recognizeImage
        .processImage(FirebaseVisionImage.fromFilePath(_image.path));

    if (recognizedLabels.isEmpty) {
      _scaffoldKey.currentState
          .showSnackBar(new SnackBar(content: Text(noLabelsWarning)));
    } else {
      labelOptions.clear();
      for (ImageLabel label in recognizedLabels) {
        final translator = GoogleTranslator();
        if (prefs.getString("Language") == "English") {
          var translation = await translator
              .translate(label.text, from: 'en', to: 'en')
              .then((value) => labelOptions.add(value.text));
        } else {
          var translation = await translator
              .translate(label.text, from: 'en', to: 'pt')
              .then((value) => labelOptions.add(value.text));
        }
      }
    }
    setState(() {
      labelOptions = labelOptions;
      _loading = false;
    });
  }
}
