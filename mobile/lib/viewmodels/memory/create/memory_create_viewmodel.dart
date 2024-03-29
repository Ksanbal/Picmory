import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:picmory/main.dart';
import 'package:picmory/repositories/meory_repository.dart';

class MemoryCreateViewmodel extends ChangeNotifier {
  // Singleton instance
  static final MemoryCreateViewmodel _singleton = MemoryCreateViewmodel._internal();

  // Factory method to return the same instance
  factory MemoryCreateViewmodel() {
    return _singleton;
  }

  // Named constructor
  MemoryCreateViewmodel._internal();

  final MemoryRepository _memoryRepository = MemoryRepository();

  bool _createComplete = false;
  bool get createComplete => _createComplete;

  // QR 스캔 여부
  bool _isFromQR = false;
  bool get isFromQR => _isFromQR;

  /// QR로 가져온 사진 URL
  String? _crawledImageUrl;
  String? get crawledImageUrl => _crawledImageUrl;

  /// QR로 가져온 동영상 URL
  String? _crawledVideoUrl;
  String? get crawledVideoUrl => _crawledVideoUrl;

  /// QR로 가져온 동영상 URL
  String? _crawledBrand;
  String? get crawledBrand => _crawledBrand;

  // 선택한 사진
  XFile? _selectedImage;
  XFile? get selectedImage => _selectedImage;

  // 선택한 동영상
  XFile? _selectedVideo;
  XFile? get selectedVideo => _selectedVideo;

  /// 날짜
  DateTime date = DateTime.now();
  showDatePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 200,
        color: Colors.white,
        child: CupertinoDatePicker(
          initialDateTime: date,
          mode: CupertinoDatePickerMode.date,
          onDateTimeChanged: (value) {
            date = value;
            notifyListeners();
          },
        ),
      ),
    );
  }

  // 해시태그
  TextEditingController hashtagController = TextEditingController();
  List<String> hashtags = [];

  /// 소스 선택 페이지에서 가져온 데이터 처리
  getDataFromExtra(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;

      if (extra == null) return;

      if (extra['from'] == 'gallery') {
        _selectedImage = XFile(extra['image']);
        if (extra['video'] != null) _selectedVideo = XFile(extra['video']);
      } else if (extra['from'] == 'qr') {
        _isFromQR = true;
        _crawledImageUrl = extra['image'];
        _crawledVideoUrl = extra['video'];
        _crawledBrand = extra['brand'];
      }

      notifyListeners();
    });
  }

  hastagOnCSumbitted(String value) {
    if (!hashtags.contains(value)) {
      hashtags.add(value);
    }
    hashtagController.clear();

    notifyListeners();
  }

  removeFromHashtags(String value) {
    hashtags.remove(value);

    notifyListeners();
  }

  // 생성
  Future<void> createMemory(BuildContext context) async {
    if (_isFromQR) {
      if (_crawledImageUrl == null || _crawledVideoUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("QR에서 데이터를 가져오지 못했습니다."),
          ),
        );
        return;
      }
    } else {
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("사진을 선택해주세요."),
          ),
        );
        return;
      }
    }

    // QR에서 가져온 경우 이미지, 영상을 다운로드 받아서 갤러리에 저장, 저장된 파일을 업로드
    bool result = false;
    if (_isFromQR) {
      try {
        Dio dio = Dio();

        // 사진 다운로드
        final response = await dio.get(
          _crawledImageUrl!,
          options: Options(responseType: ResponseType.bytes),
        );

        // 갤러리에 사진 다운로드
        final photoResult = await ImageGallerySaver.saveImage(
          Uint8List.fromList(response.data),
          quality: 100,
          isReturnImagePathOfIOS: true,
        );

        // 영상 다운로드
        final tempVideoPath = await getTemporaryDirectory();
        final videoFilename = _crawledVideoUrl!.split("/").last.split("?").first;
        final savedVideoPath = "${tempVideoPath.path}/$videoFilename";
        await dio.download(
          _crawledVideoUrl!,
          savedVideoPath,
        );

        // 갤러리에 영상 다운로드
        await ImageGallerySaver.saveFile(
          savedVideoPath,
        );

        final tempPhotoPath = await getTemporaryDirectory();

        result = await _memoryRepository.create(
          userId: supabase.auth.currentUser!.id,
          photo: await File(
            '${tempPhotoPath.path}/${photoResult['filePath'].split("/").last}',
          ).writeAsBytes(response.data),
          photoName: photoResult['filePath'].split("/").last,
          video: File(savedVideoPath),
          videoName: videoFilename,
          date: date,
          brand: null,
        );
      } catch (e) {
        log(e.toString());
        return;
      }
    } else {
      result = await _memoryRepository.create(
        userId: supabase.auth.currentUser!.id,
        photo: File(_selectedImage!.path),
        photoName: _selectedImage!.name,
        video: _selectedVideo != null ? File(_selectedVideo!.path) : null,
        videoName: _selectedVideo?.name,
        date: date,
        brand: null,
      );
    }

    if (result) {
      // final homeViewmodel = Provider.of<HomeViewmodel>(context, listen: false);
      // homeViewmodel.clearDatas();
      // homeViewmodel.loadMemories();

      _createComplete = true;

      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("기억이 생성되었습니다 🎉"),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("생성에 실패했습니다 😢"),
        ),
      );
    }
  }
}
