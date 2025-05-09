import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';

class PredictDiseaseScreen extends StatefulWidget {
  const PredictDiseaseScreen({super.key});

  @override
  _PredictDiseaseScreenState createState() => _PredictDiseaseScreenState();
}

class _PredictDiseaseScreenState extends State<PredictDiseaseScreen> {
  File? _image;

  // To pick image from gallery
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  // To send image for prediction
  Future<void> sendImageForPrediction() async {
    if (_image == null) return;

    var uri = Uri.parse('http://192.168.1.146:8000/predict/');
    var request = http.MultipartRequest('POST', uri);

    var multipartFile = await http.MultipartFile.fromPath(
      'sample_image',
      _image!.path,
      contentType: MediaType('application', 'octet-stream'),
    ); // Set the correct media type for the image
    request.files.add(multipartFile);

    // Send the request and get the streamed response
    var streamedResponse = await request.send();

    // Convert streamedResponse to a normal response
    var response = await http.Response.fromStream(streamedResponse);

    // Decode the JSON response body
    var data = jsonDecode(response.body);
    print(data);

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("Prediction Success");
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Prediction Result'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Prediction: ${data['prediction']}'),
                Text(
                    'Confidence Level: ${data['confidence_level'].toStringAsFixed(2)}'),
                Text('Time Taken: ${data['time_taken']}'),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                child: Text('Close'),
              ),
            ],
          );
        },
      );

      // Handle the response
    } else {
      print("Prediction Failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Predict Disease'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: pickImage,
              child: Text("Pick Image"),
            ),
            if (_image != null) ...[
              Image.file(_image!),
              ElevatedButton(
                onPressed: sendImageForPrediction,
                child: Text("Send Image for Prediction"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
