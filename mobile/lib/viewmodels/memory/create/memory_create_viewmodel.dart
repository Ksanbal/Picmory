import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:picmory/common/tokens/colors_token.dart';
import 'package:picmory/common/utils/show_loading.dart';
import 'package:picmory/events/memory/create_event.dart';
import 'package:picmory/main.dart';
import 'package:picmory/repositories/api/memories_repository.dart';

class MemoryCreateViewmodel extends ChangeNotifier {
  final MemoriesRepository _memoriesRepository = MemoriesRepository();

  bool _createComplete = false;
  bool get createComplete => _createComplete;

  PageController pageController = PageController(
    viewportFraction: 0.9,
  );

  // QR 스캔 여부
  bool _isFromQR = false;
  bool get isFromQR => _isFromQR;

  /// QR로 가져온 사진 URL
  List<String> _crawledImageUrls = [];
  List<String> get crawledImageUrls => _crawledImageUrls;

  /// QR로 가져온 브랜드
  String? _crawledBrand;
  String? get crawledBrand => _crawledBrand;

  // 선택한 사진
  List<XFile> _galleryImages = [];
  List<XFile> get galleryImages => _galleryImages;

  // 선택한 동영상
  List<XFile> _galleryVideos = [];
  List<XFile> get galleryVideos => _galleryVideos;

  /// 날짜
  DateTime date = DateTime.now();
  showDatePicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => Container(
        height: 200,
        color: ColorsToken.white,
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

  /// 호출 여부
  bool _isCalled = false;

  /// 소스 선택 페이지에서 가져온 데이터 처리
  getDataFromExtra(BuildContext context) {
    if (_isCalled) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;

      if (extra == null) return;
      final from = extra['from'];

      if (from == 'gallery') {
        _galleryImages = extra['image'].map<XFile>((e) => e as XFile).toList();
        _galleryVideos = extra['video'].map<XFile>((e) => e as XFile).toList();
      } else if (from == 'qr') {
        _isFromQR = true;
        _crawledImageUrls = extra['image'];

        for (var i = 0; i < extra['video'].length; i++) {
          final url = extra['video'][i];

          final tempVideoPath = await getTemporaryDirectory();
          final savedVideoPath = "${tempVideoPath.path}/video_$i.mp4";

          await Dio().download(
            url,
            savedVideoPath,
          );
          _galleryVideos.add(XFile(savedVideoPath));
        }

        _crawledBrand = extra['brand'];
      }

      _isCalled = true;
      notifyListeners();
    });
  }

  /// 영상 선택 호출
  void selectVideo() async {
    final video = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (video != null) {
      _galleryVideos.add(video);
      notifyListeners();
      pageController.animateToPage(
        _galleryImages.length + _galleryVideos.length + _crawledImageUrls.length - 1,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  // 생성
  Future<void> createMemory(BuildContext context) async {
    try {
      // 로딩 표시
      showLoading(context);

      if (_isFromQR) {
        if (_crawledImageUrls.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("QR에서 데이터를 가져오지 못했습니다."),
            ),
          );
          return;
        }
      } else {
        if (_galleryImages.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("사진을 선택해주세요."),
            ),
          );
          return;
        }
      }

      // QR에서 가져온 경우 이미지, 영상을 다운로드 받아서 갤러리에 저장, 저장된 파일을 업로드
      final List<File> downloadedImageFiles = [];
      if (_isFromQR) {
        try {
          Dio dio = Dio();

          // 사진 다운로드
          for (final url in _crawledImageUrls) {
            final response = await dio.get(
              url,
              options: Options(responseType: ResponseType.bytes),
            );

            // 갤러리에 사진 다운로드
            final photoResult = await ImageGallerySaver.saveImage(
              Uint8List.fromList(response.data),
              quality: 100,
              isReturnImagePathOfIOS: true,
            );

            final tempPhotoPath = await getTemporaryDirectory();
            final imageFile = await File(
              '${tempPhotoPath.path}/${photoResult['filePath'].split("/").last}',
            ).writeAsBytes(response.data);

            downloadedImageFiles.add(imageFile);
          }

          // 영상 다운로드
          for (final file in _galleryVideos) {
            // 갤러리에 영상 다운로드
            await ImageGallerySaver.saveFile(
              file.path,
            );
          }
        } catch (e) {
          log(e.toString());
          return;
        }
      }

      // 사진 & 영상 업로드 실행
      final List<Future<String?>> uploadFutures = [
        ...downloadedImageFiles.map((e) => uploadFile(XFile(e.path))),
        ..._galleryImages.map(uploadFile),
        ..._galleryVideos.map(uploadFile),
      ];

      final results = await Future.wait(uploadFutures);

      List<String> fileKeys = [];
      for (final result in results) {
        // 하나라도 오류가 있으면 오류 메세지 출력
        if (result == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("사진이나 영상이 업로드 되지 않았어요 😢"),
            ),
          );

          return;
        }

        fileKeys.add(result);
      }

      final result = await _memoriesRepository.create(
        fileKeys: fileKeys,
        date: date,
        brandName: _crawledBrand ?? '',
      );

      if (result.data == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("생성에 실패했습니다 😢"),
          ),
        );

        return;
      }

      final newMemoryId = result.data!.id;

      analytics.logEvent(name: 'create memory', parameters: {
        'from': _isFromQR ? 'qr' : 'gallery',
        'brand': _crawledBrand ?? '',
      });

      _createComplete = true;

      context.pushReplacement('/memory/$newMemoryId');

      // 메모리 생성 이벤트 발행
      eventBus.fire(MemoryCreateEvent(newMemoryId));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("기억이 생성되었습니다 🎉"),
        ),
      );
    } catch (e) {
      log(e.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("오류가 발생했습니다 😵"),
        ),
      );
    } finally {
      // 로딩 종료
      removeLoading();
    }
  }

  Future<String?> uploadFile(XFile file) async {
    // 업로드 url 요청
    final uploadUrl = await _memoriesRepository.createUploadUrl(
      filename: file.path.split('/').last,
    );
    if (uploadUrl.success == false || uploadUrl.data == null) return null;

    // 업로드
    final uploadResult = await _memoriesRepository.upload(
      url: uploadUrl.data!.url,
      file: file,
    );

    return uploadResult.success ? uploadUrl.data!.key : null;
  }
}
