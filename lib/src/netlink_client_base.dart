import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:html/parser.dart';

import 'constants.dart';
import 'endpoint_manager.dart';

class NetlinkClient {
  final EndpointManager endpointManager = EndpointManager(baseUrl);
  final Dio _client = Dio(
    BaseOptions(
      baseUrl: baseUrl.toString(),
      followRedirects: true,
      responseType: ResponseType.plain,
      receiveDataWhenStatusError: true,
      validateStatus: (status) => true,
      contentType: Headers.formUrlEncodedContentType,
    ),
  );

  Future<bool> login(String username, String password) async {
    final code = await fetchCode();

    final response = await _client.postUri<String>(
      endpointManager.login,
      data: {
        'username1': username,
        'psd1': password,
        'username': username,
        'psd': password,
        'verification_code': code,
        'sec_lang': 0,
        'loginSelinit': '',
        'ismobile': '',
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

    return response.statusCode == 200;
  }

  Future<bool> logout() async {
    final response = await _client.postUri<String>(
      endpointManager.logout,
    );

    return response.statusCode == 200;
  }

  Future<bool> isLoggedIn() async {
    final response = await _client.getUri<String>(
      endpointManager.commonJsFile,
    );

    return response.statusCode == 404;
  }

  Future<String> fetchCode() async {
    final response = await _client.getUri<String>(
      endpointManager.commonJsFile,
    );

    if (response.statusCode == 404) {
      throw Exception('Please logout first before proceeding.');
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

    // Extract the value by parsing the JavaScript code
    final lines = LineSplitter.split(createCodeScript);

    return lines
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
}
