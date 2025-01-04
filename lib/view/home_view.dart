import 'dart:io';
import 'package:createicons/res/image%20processing/image_processing.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import '../res/constants/constants.dart';

class MultiMaskCamera extends StatefulWidget {
  const MultiMaskCamera({super.key});

  @override
  _MultiMaskCameraState createState() => _MultiMaskCameraState();
}

class _MultiMaskCameraState extends State<MultiMaskCamera> {
  late CameraController _cameraController;
  late Future<void> _initializeControllerFuture;

  bool _isProcessing = false;
  bool _isCaptured = false;
  int _selectedMaskIndex = 0;
  bool addLogo = false;
  late XFile capturedImage;
  FlashMode _currentFlashMode = FlashMode.off;
  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.high,
    );

    setState(() {
      _initializeControllerFuture = _cameraController.initialize();
    });
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      // Ensure the camera controller is initialized
      await _initializeControllerFuture;

      setState(() {
        _isProcessing = true;
      });
      // Capture the picture
      final image = await _cameraController.takePicture();

      // Perform image processing asynchronously
      final processedImage = await ImageProcessing.processImage(
          image.path, _selectedMaskIndex, addLogo);

      // Update the state after processing is complete
      setState(() {
        _isProcessing = false;
        capturedImage = processedImage;
        _isCaptured = true;
      });
    } catch (e) {
      print(e);
    }
  }

  // Future<void> _takePicture() async {
  //   try {
  //     await _initializeControllerFuture;
  //     final image = await _cameraController.takePicture();
  //     setState(() {
  //       _isProcessing = true;
  //     });

  Future<void> _toggleFlash() async {
    if (!_cameraController.value.isInitialized) {
      return;
    }

    FlashMode nextFlashMode;
    switch (_currentFlashMode) {
      case FlashMode.off:
        nextFlashMode = FlashMode.torch;
        break;
      case FlashMode.torch:
        nextFlashMode = FlashMode.off;
        break;
      default:
        nextFlashMode = FlashMode.off;
    }

    try {
      await _cameraController.setFlashMode(nextFlashMode);
      setState(() {
        _currentFlashMode = nextFlashMode;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error toggling flash: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(
                          height: 10,
                        ),
                        SafeArea(
                          child: ListTile(
                            title: const Text('Add Logo'),
                            trailing: Switch.adaptive(
                                value: addLogo,
                                onChanged: (v) {
                                  setState(() {
                                    addLogo = v;
                                  });
                                }),
                          ),
                        ),
                        const SizedBox(
                          height: 50,
                        ),
                        Container(
                          height: MediaQuery.sizeOf(context).width,
                          width: double.infinity,
                          color: Colors.white,
                          child: Stack(
                            children: [
                              SizedBox.expand(
                                child: CameraPreview(_cameraController),
                              ),
                              Positioned.fill(
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Image.asset(
                                    livemasks[_selectedMaskIndex],
                                    width: MediaQuery.of(context).size.width,
                                    height: MediaQuery.of(context).size.width,
                                    fit: BoxFit.fitWidth,
                                  ),
                                ),
                              ),
                              addLogo
                                  ? Align(
                                      alignment: Alignment.center,
                                      child: Image.asset(
                                        'assets/shapes/logo.png',
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.fitWidth,
                                      ),
                                    )
                                  : const SizedBox.shrink()
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 100,
                          child: Center(
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: masks.length,
                              itemBuilder: (context, index) {
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedMaskIndex = index;
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: _selectedMaskIndex == index
                                            ? Colors.blue
                                            : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: Image.asset(
                                      masks[index],
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        captureandFlashButton(),
                        const SizedBox(
                          height: 10,
                        ),
                        SizedBox(
                          height: 130,
                          child: Center(
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: capturedImages.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Image.file(
                                      File(capturedImages[index].path),
                                      width: 80,
                                      fit: BoxFit.cover,
              
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Visibility(
                          visible: capturedImages.isNotEmpty,
                          child: GestureDetector(
                            onTap: () {
                              ImageProcessing.shareImage(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Text(
                                'Share',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                      ],
                    ),
                  ),
                  _isProcessing
                      ? Container(
                          width: MediaQuery.sizeOf(context).width,
                          height: MediaQuery.sizeOf(context).height,
                          color: Colors.black.withOpacity(.5),
                          child: Center(
                            child: Container(
                              color: Colors.white,
                              height: 80,
                              width: 80,
                              child: const Padding(
                                padding: EdgeInsets.all(20.0),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                  _isCaptured
                      ? Container(
                          width: MediaQuery.sizeOf(context).width,
                          height: MediaQuery.sizeOf(context).height,
                          color: Colors.black.withOpacity(.8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Center(
                                child: SizedBox(
                                  width: MediaQuery.sizeOf(context).width,
                                  height: MediaQuery.sizeOf(context).width,
                                  child: Image.file(
                                    File(capturedImage.path),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0, vertical: 10),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isCaptured = false;
                                        });
                                      },
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.red,
                                      ),
                                    ),
                                    GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _isCaptured = false;
                                            capturedImages.add(capturedImage);
                                          });
                                        },
                                        child: const Icon(
                                          Icons.done,
                                          color: Colors.white,
                                        ))
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink()
                ],
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }

  Row captureandFlashButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _takePicture,
          child: Container(
            decoration: BoxDecoration(
                color: Colors.blue, borderRadius: BorderRadius.circular(70)),
            height: 70,
            width: 70,
            child: const Icon(
              Icons.camera,
              size: 50,
            ),
          ),
        ),
        const SizedBox(
          width: 20,
        ),
        GestureDetector(
          onTap: _toggleFlash,
          child: Container(
            decoration: BoxDecoration(
              color: _currentFlashMode == FlashMode.torch
                  ? Colors.yellow
                  : Colors.blue,
              borderRadius: BorderRadius.circular(50),
            ),
            height: 70,
            width: 70,
            child: const Icon(
              Icons.flash_on,
              size: 45,
            ),
          ),
        ),
      ],
    );
  }
}
