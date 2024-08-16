import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:html/parser.dart';

import 'constants.dart';
import 'endpoint_manager.dart';
import 'models/wan_info.dart';

final class NetlinkResponse<T> {
  const NetlinkResponse({
    required this.statusCode,
    this.data,
  });

  final int statusCode;
  final T? data;
}

class NetlinkClient {
  final EndpointManager urls = EndpointManager(baseUrl);
  final Dio _client = Dio(
    BaseOptions(
      baseUrl: baseUrl.toString(),
      followRedirects: true,
      maxRedirects: 5,
      responseType: ResponseType.plain,
      receiveDataWhenStatusError: true,
      validateStatus: (status) => true,
      contentType: Headers.formUrlEncodedContentType,
    ),
  );
  bool? _isLoggedIn;

  bool get isLoggedIn {
    if (_isLoggedIn == null) {
      throw Exception('Please run initialize() first.');
    }

    return _isLoggedIn!;
  }

  Future<void> initialize() async {
    _isLoggedIn = await isSessionActive();
  }

  Future<bool> login({
    required String username,
    required String password,
  }) async {
    if (isLoggedIn) {
      return true;
    }

    if (username.isEmpty || password.isEmpty) {
      throw Exception('Username and password cannot be empty');
    }

    final code = await _fetchCode();

    final response = await _execute<String>(
      urls.login,
      method: 'POST',
      data: {
        'username1': username,
        'psd1': password,
        'username': username,
        'psd': password,
        'verification_code': code,
        'sec_lang': 0,
        'loginSelinit': '',
        'ismobile': '',
        // This is not even required AFAIK
        'csrftoken': 'bb4e5661d5c3706d31b41ec30e31608e',
      },
    );

    if (response.statusCode != 200 || response.data == null) {
      throw Exception('Failed to login');
    }

    if (response.data!
        .contains('ERROR:You have entered wrong username or password thrice')) {
      throw Exception(
        'You have entered wrong username or password thrice; Please try again after 15 minutes',
      );
    }

    return _isLoggedIn = response.statusCode == 200;
  }

  Future<bool> logout() async {
    final response = await _execute<String>(
      urls.logout,
    );

    _isLoggedIn = !(response.statusCode == 200);
    return response.statusCode == 200;
  }

  Future<List<WanInfo>> getWanInfo() async {
    final response = await _execute<String>(urls.netConnectInfo);

    if (response.statusCode != 200 || response.data == null) {
      throw Exception('Failed to fetch WAN status');
    }

    final document = parse(response.data);
    final scriptTags = document.getElementsByTagName('script');

    final linksScript = scriptTags.map((script) => script.innerHtml).firstWhere(
          (innerHtml) => innerHtml.contains('var links = new Array();'),
          orElse: () => '',
        );

    if (linksScript.isEmpty) {
      throw Exception('WAN links script not found');
    }

    final wanInfoList = <WanInfo>[];
    final regex = RegExp(r'"([^"]+)"|(\d+)(?=\))');

    for (final line in LineSplitter.split(linksScript)) {
      if (!line.contains('new it_nr')) {
        continue;
      }

      final matches =
          regex.allMatches(line).map((m) => m.group(1) ?? m.group(2)!).toList();

      if (matches.isEmpty) continue;

      matches.removeAt(0);

      final wanInfoMap = <String, String>{};
      for (var i = 0; i < matches.length; i += 2) {
        wanInfoMap[matches[i]] = matches[i + 1];
      }

      wanInfoList.add(
        WanInfo(
          interface: wanInfoMap['servName'] ?? '',
          vlanId: int.parse(wanInfoMap['vlanId'] ?? '0'),
          protocol: wanInfoMap['protocol'] ?? '',
          igmpStatus: wanInfoMap['igmpEnbl'] == '1',
          state: wanInfoMap['strStatus'] == 'up',
          ipAddress: wanInfoMap['ipAddr'] ?? '',
          subnetMask: wanInfoMap['netmask'] ?? '',
          macAddress: wanInfoMap['MacAddr'] ?? '',
        ),
      );
    }

    return wanInfoList;
  }

  Future<bool> isSessionActive() async {
    final response = await _execute<String>(
      urls.commonJsFile,
    );

    if (response.statusCode == 404) {
      return _isLoggedIn = true;
    }

    return _isLoggedIn =
        response.statusCode >= 200 && response.statusCode < 400;
  }

  Future<String> _fetchCode({bool logoutIfActive = false}) async {
    final response = await _execute<String>(
      urls.commonJsFile,
    );

    if (response.statusCode == 404) {
      if (!logoutIfActive) {
        throw Exception('Please logout first before proceeding.');
      }

      await logout();
    }

    if (response.statusCode != 200 || response.data == null) {
      throw Exception('Failed to fetch code');
    }

    final document = parse(response.data);
    final scriptTags = document.getElementsByTagName('script');

    final createCodeScript =
        scriptTags.map((script) => script.innerHtml).firstWhere(
              (innerHtml) => innerHtml.contains('function CreateCode()'),
              orElse: () => '',
            );

    // Not a good practice but hey, it works
    return LineSplitter.split(createCodeScript)
        .where(
          (line) => line
              .trim()
              .startsWith("document.getElementById('check_code').value"),
        )
        .first
        .split('=')
        .last
        .trim()
        .replaceAll("'", '')
        .replaceAll(';', '');
  }

  Future<NetlinkResponse<T>> _execute<T>(
    Uri uri, {
    String method = 'GET',
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _client.requestUri(
        uri,
        data: data,
        options: Options(method: method),
      );

      if (response.statusCode == null) {
        return NetlinkResponse<T>(
          statusCode: -1,
        );
      }

      return NetlinkResponse<T>(
        statusCode: response.statusCode!,
        data: response.data,
      );
    } catch (e) {
      return NetlinkResponse<T>(
        statusCode: 500,
      );
    }
  }
}
