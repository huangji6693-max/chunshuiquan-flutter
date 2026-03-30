import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:chunshuiquan_flutter/features/auth/data/auth_repository.dart';
import 'package:chunshuiquan_flutter/core/storage/token_manager.dart';
import 'package:chunshuiquan_flutter/core/errors/app_exception.dart';

@GenerateMocks([Dio, TokenManager])
import 'auth_repository_test.mocks.dart';

void main() {
  late MockDio mockDio;
  late MockTokenManager mockTm;
  late AuthRepository repo;

  setUp(() {
    mockDio = MockDio();
    mockTm = MockTokenManager();
    repo = AuthRepository(mockDio, mockTm);
  });

  group('AuthRepository - login', () {
    test('成功登录，保存 token 并返回 UserProfile', () async {
      when(mockDio.post('/api/auth/login', data: anyNamed('data')))
          .thenAnswer((_) async => Response(
                data: {
                  'token': 'access_jwt',
                  'refreshToken': 'refresh_jwt',
                  'id': '00000000-0000-0000-0000-000000000001',
                  'email': 'a@b.com',
                  'name': '测试',
                  'gender': 'male',
                  'lookingFor': 'everyone',
                  'avatarUrls': [],
                  'tags': [],
                },
                statusCode: 200,
                requestOptions: RequestOptions(path: '/api/auth/login'),
              ));
      when(mockTm.saveTokens(
              accessToken: anyNamed('accessToken'),
              refreshToken: anyNamed('refreshToken')))
          .thenAnswer((_) async {});

      final profile = await repo.login(email: 'a@b.com', password: '123456');
      expect(profile.email, 'a@b.com');
      verify(mockTm.saveTokens(
              accessToken: 'access_jwt', refreshToken: 'refresh_jwt'))
          .called(1);
    });

    // 边界测试：响应中缺少 token
    test('响应中缺少 token 抛出 AppException', () async {
      when(mockDio.post('/api/auth/login', data: anyNamed('data')))
          .thenAnswer((_) async => Response(
                data: {'error': '密码错误'},
                statusCode: 200,
                requestOptions: RequestOptions(path: '/api/auth/login'),
              ));
      expect(
          () => repo.login(email: 'a@b.com', password: 'wrong'),
          throwsA(isA<AppException>()));
    });

    // 边界测试：401
    test('401 响应抛出 unauthorized 异常', () async {
      when(mockDio.post('/api/auth/login', data: anyNamed('data'))).thenThrow(
        DioException(
          response: Response(
              statusCode: 401,
              requestOptions: RequestOptions(path: '')),
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
        ),
      );
      expect(
          () => repo.login(email: 'a@b.com', password: '123'),
          throwsA(predicate((e) =>
              e is AppException &&
              e.type == AppExceptionType.unauthorized)));
    });

    // 边界测试：网络超时
    test('连接超时抛出 network 异常', () async {
      when(mockDio.post('/api/auth/login', data: anyNamed('data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(
          () => repo.login(email: 'a@b.com', password: '123'),
          throwsA(predicate((e) =>
              e is AppException && e.type == AppExceptionType.network)));
    });

    // 边界测试：响应不是 Map
    test('响应格式不是 Map 抛出 server 异常', () async {
      when(mockDio.post('/api/auth/login', data: anyNamed('data')))
          .thenAnswer((_) async => Response(
                data: 'plain string',
                statusCode: 200,
                requestOptions: RequestOptions(path: ''),
              ));
      expect(
          () => repo.login(email: 'a@b.com', password: '123'),
          throwsA(isA<AppException>()));
    });
  });
}
