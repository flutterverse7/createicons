import 'dart:io';
import 'dart:typed_data';
import 'package:createicons/res/constants/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image/image.dart' as img;

class ImageProcessing {
  static Future<XFile> uint8ListToXFile(img.Image finalImage) async {
    
    final directory = await getTemporaryDirectory();
    List<int> pngBytes = img.encodePng(finalImage);
    Uint8List imageBytes = Uint8List.fromList(pngBytes);
    
    final tempPath =
        '${directory.path}/output_image${DateTime.now().millisecondsSinceEpoch}.png';

    final file = File(tempPath);
    await file.writeAsBytes(imageBytes);

    return XFile(file.path);
  }

  static Future<XFile> processImage(
      String imagePath, int index, bool addlogo) async {
    final imageBytes =
        File(imagePath).readAsBytesSync(); 
    img.Image sourceImage = img.decodeImage(imageBytes)!;

    ByteData maskData = await rootBundle.load(livemasks[index]);
    Uint8List maskBytes = maskData.buffer.asUint8List();
    img.Image maskImage = img.decodeImage(maskBytes)!;
    img.Image resizedSourceImage = img.copyResize(sourceImage,
        width: maskImage.width, height: maskImage.height);

    img.Image mask = createMask(maskImage);

    img.Image finalImg = applyMask(resizedSourceImage, mask);
    img.Image finalImage = finalImg;
    if (addlogo) {
      ByteData maskData = await rootBundle.load('assets/shapes/logo.png');
      Uint8List maskBytes = maskData.buffer.asUint8List();
      img.Image maskImage = img.decodeImage(maskBytes)!;
      img.Image resizedMaskImage =
          img.copyResize(maskImage, width: 40, height: 50);
      finalImage = img.compositeImage(finalImg, resizedMaskImage, center: true);
    }
    return uint8ListToXFile(finalImage);
  }

  static img.Image createMask(img.Image image) {
    img.Image mask =
        img.copyResize(image, width: image.width, height: image.height);

   
    mask = img.gaussianBlur(mask, radius: 3);

    for (int y = 0; y < mask.height; y++) {
      for (int x = 0; x < mask.width; x++) {
        final pixelValue = mask.getPixel(x, y);
        if (pixelValue.r != 0 || pixelValue.g != 0 || pixelValue.b != 0) {
          mask.setPixel(x, y, img.ColorRgb8(255, 255, 255));
        } else {
          mask.setPixel(x, y, img.ColorRgb8(0, 0, 0));
        }
      }
    }
    return mask;
  }

  static img.Image applyMask(img.Image image, img.Image mask) {
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final maskPixel = mask.getPixel(x, y);
        if (maskPixel.r != 0 || maskPixel.g != 0 || maskPixel.b != 0) {
          image.setPixelRgba(x, y, 255, 255, 255, 0);
        }
      }
    }
    return image;
  }

  static Future<void> shareImage(BuildContext context) async {
    if (capturedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image and a shape.')),
      );
      return;
    }

    try {
      if (capturedImages.length == 1) {
       
        await Share.shareXFiles(
          capturedImages,
          text: 'Check out this shaped image!',
          subject: 'Shaped Image',
        );
      } else {
        
        await Share.shareXFiles(
          capturedImages,
          subject: 'Shaped Images', 
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing image: $e')),
      );
    }
  }
}