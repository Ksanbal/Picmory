import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:picmory/main.dart';
import 'package:picmory/models/memory/crawled_qr_model.dart';
import 'package:picmory/models/memory/memory_create_model.dart';
import 'package:picmory/models/memory/memory_list_model.dart';
import 'package:picmory/models/memory/memory_model.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

/// 기억 관련 서버 통신을 담당하는 클래스
class MemoryRepository {
  Future<String> _uploadFile(
    String path,
    String bucket,
    String filename,
    File file,
  ) async {
    final supabaseUrl = dotenv.get("SUPABASE_URL");

    final uri = await supabase.storage.from(bucket).upload(
          '$path/$filename',
          file,
        );

    return "$supabaseUrl/storage/v1/object/public/$uri";
  }

  /// 기억 생성
  /// - [userID] : 사용자 ID
  /// - [photo] : 사진
  /// - [video] : 영상
  /// - [hashTags] : 해시태그 목록
  /// - [date] : 날짜
  /// - [brand] : 브랜드
  Future<int?> create({
    required String userId,
    required List<File> photoList,
    required List<String> photoNameList,
    required List<File> videoList,
    required List<String> videoNameList,
    required DateTime date,
    required String? brand,
  }) async {
    /** 
     * TODO: 기억 생성 기능 작성
     * - [x] photo, video 업로드 & URI 획득
     * - [x] memory 생성
     * - [x] hashtags 목록에서 DB에 없는 해시태그는 생성
     * - [x] memory_hashtag 생성
     */
    final now = DateTime.now();
    final path = 'users/$userId/memories/${now.millisecondsSinceEpoch}';

    try {
      final futurePhotoUris = [];
      for (int i = 0; i < photoList.length; i++) {
        futurePhotoUris.add(
          _uploadFile(
            path,
            'picmory',
            photoNameList[i],
            photoList[i],
          ),
        );
      }

      final futureVideoUris = [];
      for (int i = 0; i < videoList.length; i++) {
        futureVideoUris.add(
          _uploadFile(
            path,
            'picmory',
            videoNameList[i],
            videoList[i],
          ),
        );
      }

      final newMemory = MemoryCreateModel(
        userId: userId,
        photoUri: null,
        videoUri: null,
        date: date,
        brand: brand,
      );

      final data = await supabase
          .from('memory')
          .insert(
            newMemory.toJson(),
          )
          .select('id');
      final newMemoryId = data.first['id'];

      final photoUris = [];
      for (final uri in futurePhotoUris) {
        photoUris.add(await uri);
      }

      final videoUris = [];
      for (final uri in futureVideoUris) {
        videoUris.add(await uri);
      }

      await supabase.from('upload').insert(
            photoUris
                .map((e) => {
                      "uri": e,
                      "memory_id": newMemoryId,
                      "is_photo": true,
                      "filename": photoNameList[photoUris.indexOf(e)],
                    })
                .toList(),
          );

      await supabase.from('upload').insert(
            videoUris
                .map((e) => {
                      "uri": e,
                      "memory_id": newMemoryId,
                      "is_photo": false,
                      "filename": photoNameList[videoUris.indexOf(e)],
                    })
                .toList(),
          );

      return newMemoryId;
    } catch (e) {
      log(e.toString(), name: 'MemoryRepository.create');
      return null;
    }
  }

  /// 목록 조회
  /// - [userId] : 사용자 ID
  /// - [albumId] : 앨범 ID
  /// - [hashtag] : 해시태그
  Future<List<MemoryListModel>> list({
    required String userId,
    required int? albumId,
    List<String> hashtags = const [],
  }) async {
    /**
     * TODO: 기억 목록 조회 기능 작성
     * - [x] albumId, hashtag가 모두 null이 아니면 에러
     * - [x] albumId, hashtag가 모두 null이면 전체 기억 목록 조회
     * - [ ] albumId가 null이 아니면 해당 앨범의 기억 목록 조회
     * - [ ] hashtag가 null이 아니면 해당 해시태그가 포함된 기억 목록 조회
     */
    if (albumId != null && hashtags.isNotEmpty) {
      throw Exception('albumId, hashtags 둘 중 하나만 입력해주세요');
    }

    final result = [];
    if (albumId == null && hashtags.isEmpty) {
      final items = await supabase
          .from('memory')
          .select(
            'id, date, upload(uri, is_photo)',
          )
          .eq('user_id', userId)
          .order('id', ascending: true);
      result.addAll(items);
    } else if (albumId != null) {
      final items = await supabase
          .from('memory_album')
          .select('id, album_id, memory(id, date, upload(uri, is_photo))')
          .eq('album_id', albumId)
          .order('id', ascending: false);

      return items.map((e) => MemoryListModel.fromJson(e['memory'])).toList();
    } else if (hashtags.isNotEmpty) {
      final items = await supabase
          .from('memory')
          .select(
            'id, created_at, photo_uri, video_uri, date, hashtag(name)',
          )
          .eq('user_id', userId);

      for (final item in items) {
        if (item['hashtag'].isEmpty) {
          continue;
        }

        for (final hashtag in item['hashtag']) {
          if (hashtags.contains(hashtag['name'])) {
            result.add(item);
            break;
          }
        }
      }
    }

    return result.map((e) => MemoryListModel.fromJson(e)).toList();
  }

  /// 좋아요한 목록 조회
  /// - [userId] : 사용자 ID
  Future<List<MemoryListModel>> listOnlyLike({
    required String userId,
    int page = 1,
    int pageCount = 5,
  }) async {
    final items = await supabase
        .from('memory_like')
        .select('id, memory(id, date, upload(uri, is_photo))')
        .eq('user_id', userId)
        .order('id', ascending: false)
        .range((page - 1) * pageCount, page * pageCount);

    return items.map((e) => MemoryListModel.fromJson(e['memory'])).toList();
  }

  /// 단일 조회
  /// - [userId] : 사용자 ID
  /// - [memoryId] : 기억 ID
  Future<MemoryModel?> retrieve({
    required String userId,
    required int memoryId,
  }) async {
    /**
     * TODO: 기억 단일 조회 기능 작성
     * - [x] memoryID로 기억 조회
     * - [ ] memory_hashtag에서 memoryID로 해시태그 목록 조회
     */
    final items = await supabase
        .from('memory')
        .select(
          'id, brand, date, memory_like(id), upload(uri, is_photo)',
        )
        .eq('user_id', userId)
        .eq('id', memoryId);

    if (items.isNotEmpty) {
      final item = items.first;
      item['is_liked'] = item['memory_like'].isNotEmpty;
      return MemoryModel.fromJson(item);
    }

    return null;
  }

  /// 수정
  /// - [userId] : 사용자 ID
  /// - [memoryId] : 기억 ID
  /// - [photo] : 사진
  /// - [video] : 영상
  /// - [hashTags] : 해시태그 목록
  /// - [date] : 날짜
  edit({
    required String userId,
    required int memoryId,
    // required XFile? photo,
    // required XFile? video,
    // required List<String> hashtags,
    required DateTime date,
  }) async {
    /**
     * TODO: 기억 수정 기능 작성
     * - [x] memory 수정
     */

    try {
      await supabase
          .from('memory')
          .update({
            'date': date.toString(),
          })
          .eq('user_id', userId)
          .eq('id', memoryId);

      return true;
    } catch (e) {
      log(e.toString(), name: 'MemoryRepository.edit');
    }

    return false;
  }

  /// 삭제
  /// - [userId] : 사용자 ID
  /// - [memoryId] : 기억 ID
  Future<String?> delete({
    required String userId,
    required int memoryId,
  }) async {
    /**
     * TODO: 기억 삭제 기능 작성
     * - [x] memoryID로 기억 조회
     * - [x] memory 삭제
     * - [x] photo, video 삭제
     */
    final items = await supabase
        .from('memory')
        .select(
          'photo_uri, video_uri',
        )
        .eq('user_id', userId)
        .eq('id', memoryId);
    if (items.isEmpty) {
      return '기억을 찾을 수 없어요';
    }

    try {
      await supabase.from('memory').delete().eq('id', memoryId);

      final item = items.first;
      final photoUri = item['photo_uri'];
      final videoUri = item['video_uri'];

      final List<String> removeList = [];
      removeList.add('users/${photoUri.split('users/').last}');

      if (videoUri != null) {
        removeList.add('users/${videoUri.split('users/').last}');
      }

      await supabase.storage.from('picmory').remove(removeList);

      return null;
    } catch (error) {
      log(error.toString(), name: 'MemoryRepository.delete');
      return '기억을 삭제할 수 없어요';
    }
  }

  /// 앨범에 추가
  /// - [userId] : 사용자 Id
  /// - [memoryId] : 기억 Id
  /// - [albumId] : 앨범 Id
  Future<bool> addToAlbum({
    required String userId,
    required int memoryId,
    required List<int> albumIds,
  }) async {
    /**
     * TODO: 앨범에 기억 추가 기능 작성
     * - [x] memory_album 생성
     */
    try {
      await supabase.from('memory_album').insert(
            albumIds
                .map((albumId) => {
                      'memory_id': memoryId,
                      'album_id': albumId,
                    })
                .toList(),
          );

      return true;
    } catch (e) {
      log(e.toString(), name: 'MemoryRepository.addToAlbum');
      return false;
    }
  }

  /// 앨범에서 삭제
  /// - [userId] : 사용자 Id
  /// - [memoryId] : 기억 Id
  /// - [albumId] : 앨범 Id
  deleteFromAlbum({
    required String userId,
    required int memoryId,
    required int albumId,
  }) async {
    /**
     * TODO: 앨범에서 기억 삭제 기능 작성
     * - [ ] memoryId & albumId로 memory_album 조회
     * - [ ] memory_album 삭제
     */
    try {
      await supabase
          .from('memory_album')
          .delete()
          .eq('album_id', albumId)
          .eq('memory_id', memoryId);

      return true;
    } catch (e) {
      log(e.toString(), name: 'MemoryRepository.deleteFromAlbum');
      return false;
    }
  }

  /// QR로 스캔한 URL 크롤링 API
  /// - [url] : URL
  Future<CrawledQrModel?> crawlUrl(String url) async {
    /**
     * TODO: 크롤링 API 호출 기능 작성
     */
    try {
      await remoteConfig.fetchAndActivate();
      final host = remoteConfig.getString('api_host');

      dynamic res;
      if (host.isEmpty) {
        res = await supabase.functions.invoke(
          'qr-crawler',
          body: {
            'url': url,
          },
        );
      } else {
        try {
          Dio dio = Dio();
          res = await dio.get(
            '$host/api/qr-crawler?url=$url',
          );
        } catch (error) {
          return null;
        }
      }

      return CrawledQrModel.fromJson(res.data);
    } on FunctionException catch (e) {
      log('${e.status.toString()} ${e.reasonPhrase}', name: 'MemoryRepository.crawlUrl');
      return null;
    }
  }

  /// 해시태그 목록 조회
  Future<List<String>> getHashtags({
    required String userId,
  }) async {
    final items = await supabase
        .from('memory')
        .select(
          'id, hashtag(name)',
        )
        .eq('user_id', userId);

    List<String> hashtags = [];
    for (final item in items) {
      if (item['hashtag'].isEmpty) {
        continue;
      }

      for (final hashtag in item['hashtag']) {
        if (!hashtags.contains(hashtag['name'])) {
          hashtags.add(hashtag['name']);
        }
      }
    }

    return hashtags;
  }

  /// 좋아요 상태 변경
  /// - [userID] : 사용자 ID
  /// - [memoryID] : 기억 ID
  Future<bool> changeLikeStatus({
    required String userId,
    required int memoryId,
    required bool isLiked,
  }) async {
    try {
      if (isLiked) {
        await supabase.from('memory_like').delete().eq('user_id', userId).eq('memory_id', memoryId);
      } else {
        await supabase.from('memory_like').insert({
          'user_id': userId,
          'memory_id': memoryId,
        });
      }
    } catch (e) {
      log(e.toString(), name: 'MemoryRepository.changeLikeStatus');
      return false;
    }

    return true;
  }
}
