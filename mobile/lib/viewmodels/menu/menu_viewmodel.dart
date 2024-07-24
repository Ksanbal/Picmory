import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:picmory/common/components/menu/user/confirm_withdraw_widget.dart';
import 'package:picmory/main.dart';
import 'package:picmory/repositories/auth_repository.dart';
import 'package:url_launcher/url_launcher_string.dart';

class MenuViewmodel extends ChangeNotifier {
  MenuViewmodel() {
    getUserInfo();
    getAppVersion();
  }

  final AuthRepository _authRepository = AuthRepository();

  /// 유저 정보
  String _userName = '';
  String get userName => _userName;

  String _provider = '';
  String get provider => _provider;

  /// 앱 버전
  String _appVersion = '';
  String get appVersion => _appVersion;

  /// 유저 정보 가져오기
  getUserInfo() async {
    final user = await supabase.auth.getUser();

    final appMetadata = user.user?.appMetadata;
    final userMetadata = user.user?.userMetadata;

    /// 로그인한 소셜로그인 정보에 따라서 분기
    if (appMetadata?['provider'] == 'google') {
      _provider = 'google';
      _userName = userMetadata?['full_name'] ?? '';
    } else if (appMetadata?['provider'] == 'apple') {
      _provider = 'apple';
      _userName = userMetadata?['email'].split('@')[0];
    }

    notifyListeners();
  }

  /// 앱 버전 가져오기
  getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';

    notifyListeners();
  }

  /// user 페이지로 이동
  routeToUser(BuildContext context) {
    context.push('/menu/user');
  }

  /// 로그아웃
  signout(BuildContext context) async {
    _authRepository.signOut().then(
      (value) {
        if (value) {
          context.go('/auth/signin');
        }
      },
    );
  }

  /// 공지사항 페이지로 이동
  showNotice() {
    launchUrlString('https://alive-stick-1e6.notion.site/28e60d33f7ba40aa8ede8133a79e140a?pvs=4');
  }

  /// 이용 약관 및 정책
  showTermsAndPolicy() {
    launchUrlString('https://alive-stick-1e6.notion.site/43b4e41791434542b03b1adb1ce38217?pvs=4');
  }

  /// 개인정보처리방침
  showPrivacyPolicy() {
    launchUrlString('https://alive-stick-1e6.notion.site/d348792bdd124bbf816ff2646b30f7a2?pvs=4');
  }

  /// 문의하기
  contactUs() {
    launchUrlString("""mailto:picmory.contact@gmail.com?body=
	1.  사용자명: $_userName
  2.  앱 버전 : $_appVersion
	3.	문의 유형:
	•	기능 관련 문의
	•	버그/오류 신고
	•	계정 문제
	•	기타
	4.	문의 내용:
	•	구체적인 문제 또는 질문을 상세히 작성해 주세요.
	•	필요 시 관련 스크린샷이나 파일을 첨부해 주세요.

다음 양식을 사용하여 문의해 주시면 
보다 빠른 서비스 개선을 도와드리겠습니다. 감사합니다.
""");
  }

  /// 오픈소스 라이센스
  routeToLicense(BuildContext context) {
    context.push('/menu/license');
  }

  /**
   * user
   */
  /// 회원탈퇴
  withdraw(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return const ConfirmWithdrawWidget();
      },
    );

    if (result == null || !result) return;

    // [ ] 회원탈퇴 (supabase 그지 같네...)
    await supabase.auth.signOut();

    context.go('/auth/signin');
  }

  /**
   * 개발자
   */
  /// 개발자 모드 활성화
  int versionTapCount = 0;
  activeDeveloperMode(BuildContext context) async {
    versionTapCount++;

    if (versionTapCount == 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('개발자 모드까지 2번'),
        ),
      );
    } else if (versionTapCount == 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('개발자 모드까지 1번'),
        ),
      );
    } else if (versionTapCount == 10) {
      await messaging.subscribeToTopic('developer');
      // 활성화 여부 snackbar 노출
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('개발자 모드가 활성화 되었습니다.'),
        ),
      );
    }
  }
}
