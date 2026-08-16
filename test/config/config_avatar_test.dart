import 'package:family_tree_app/config/config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('avatar path relatif dikonversi menjadi URL storage', () {
    final url = Config.getAvatarUrl(avatar: '/avatars/member.jpg');

    expect(url, isNotNull);
    expect(url, contains('/avatars/member.jpg'));
  });

  test('avatar URL langsung tidak diubah', () {
    const url = 'https://cdn.example.com/avatar.jpg';

    expect(Config.getAvatarUrl(avatarUrl: url), url);
  });

  test('avatar map memakai kandidat URL yang tersedia', () {
    final url = Config.getAvatarUrl(avatar: {'path': 'avatars/member.jpg'});

    expect(url, contains('/avatars/member.jpg'));
  });

  test('avatar kosong menghasilkan null', () {
    expect(Config.getAvatarUrl(avatar: ''), isNull);
    expect(Config.getAvatarUrl(), isNull);
  });
}
