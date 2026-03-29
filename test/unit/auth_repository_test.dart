import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:dating_app/features/auth/data/auth_repository.dart';
import 'package:dating_app/core/storage/auth_storage.dart';
import 'package:dating_app/core/errors/app_exception.dart';

@GenerateMocks([Dio, AuthStorage])
import 'auth_repository_test.mocks.dart';

void main() {
  late MockDio mockDio;
  late MockAuthStorage mockStorage;
  late AuthRepository repo;

  setUp(() {
    mockDio = MockDio();
    mockStorage = MockAuthStorage();
    repo = AuthRepository(mockDio, mockStorage);
  });

  group('AuthRepository - login', () {
    test('成功登录，保存 token 并返回 UserProfile', () async {
      when(mockDio.post('/api/auth/login', data: anyNamed('data')))
          .thenAnswer((_) async => Response(
                data: {'token': 'test_jwt_token', 'id': '123', 'email': 'a@b.com', 'name': '测试', 'gender': 'male', 'lookingFor': 'everyone', 'avatarUrls': [], 'tags': []},
                statusCode: 200,
                requestOptions: RequestOptions(path: '/api/auth/login'),
              ));
      when(mockStorage.saveToken(any)).thenAnswer((_) async {});

      final profile = await repo.login(email: 'a@b.com', password: '123456');
      expect(profile.email, 'a@b.com');
      verify(mockStorage.saveToken('test_jwt_token')).called(1);
    });

    // 边界测试：空邮箱
    test('响应中缺少 token 抛出 AppException', () async {
      when(mockDio.post('/api/auth/login', data: anyNamed('data')))
          .thenAnswer((_) async => Response(
                data: {'message': '密码错误'},
                statusCode: 200,
                requestOptions: RequestOptions(path: '/api/auth/login'),
              ));

      expect(() => repo.login(email: 'a@b.com', password: 'wrong'),
          throwsA(isA<AppException>()));
    });

    // 边界测试：401
    test('401 响应抛出 unauthorized 异常', () async {
      when(mockDio.post('/api/auth/login', data: anyNamed('data'))).thenThrow(
        DioException(
          response: Response(statusCode: 401, requestOptions: RequestOptions(path: '')),
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.badResponse,
        ),
      );
      expect(() => repo.login(email: 'a@b.com', password: '123'),
          throwsA(predicate((e) => e is AppException && e.type == AppExceptionType.unauthorized)));
    });

    // 边界测试：网络超时
    test('连接超时抛出 network 异常', () async {
      when(mockDio.post('/api/auth/login', data: anyNamed('data'))).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''),
          type: DioExceptionType.connectionTimeout,
        ),
      );
      expect(() => repo.login(email: 'a@b.com', password: '123'),
          throwsA(predicate((e) => e is AppException && e.type == AppExceptionType.network)));
    });
  });

  group('AuthRepository - register 边界测试', () {
    test('响应格式不是 Map 抛出异常', () async {
      when(mockDio.post('/api/auth/register', data: anyNamed('data')))
          .thenAnswer((_) async => Response(
                data: 'plain string response',
                statusCode: 200,
                requestOptions: RequestOptions(path: ''),
              ));
      expect(
        () => repo.register(name: '张三', email: 'a@b.com', password: '123456', birthDate: '2000-01-01', gender: 'male'),
        throwsA(isA<AppException>()),
      );
    });
  });
}
