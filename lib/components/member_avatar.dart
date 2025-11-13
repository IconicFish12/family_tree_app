import 'package:family_tree_app/config/config.dart';
import 'package:flutter/material.dart';

/// Widget untuk menampilkan foto member dengan fallback
/// Bisa handle asset lokal maupun network image
class MemberAvatar extends StatelessWidget {
  final String? photoUrl;
  final String emoji;
  final double size;
  final double? borderRadius;
  final bool isAsset; // true jika photoUrl adalah asset path

  const MemberAvatar({
    super.key,
    this.photoUrl,
    this.emoji = '👤',
    this.size = 50,
    this.borderRadius,
    this.isAsset = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? size / 6;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Config.background,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: photoUrl != null && photoUrl!.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: isAsset
                  ? Image.asset(
                      photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            emoji,
                            style: TextStyle(fontSize: size * 0.55),
                          ),
                        );
                      },
                    )
                  : Image.network(
                      photoUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: SizedBox(
                            width: size * 0.3,
                            height: size * 0.3,
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            emoji,
                            style: TextStyle(fontSize: size * 0.55),
                          ),
                        );
                      },
                    ),
            )
          : Center(
              child: Text(emoji, style: TextStyle(fontSize: size * 0.55)),
            ),
    );
  }
}

/// Widget untuk menampilkan foto member dengan akses tambahan
class MemberPhotoViewer extends StatelessWidget {
  final String? photoUrl;
  final String emoji;
  final String memberName;
  final bool isAsset;

  const MemberPhotoViewer({
    super.key,
    this.photoUrl,
    this.emoji = '👤',
    required this.memberName,
    this.isAsset = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(memberName)),
      body: Center(
        child: photoUrl != null && photoUrl!.isNotEmpty
            ? isAsset
                  ? Image.asset(
                      photoUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 100)),
                            const SizedBox(height: 20),
                            const Text('Foto tidak bisa dimuat'),
                          ],
                        );
                      },
                    )
                  : Image.network(
                      photoUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 100)),
                            const SizedBox(height: 20),
                            const Text('Foto tidak bisa dimuat'),
                          ],
                        );
                      },
                    )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 100)),
                  const SizedBox(height: 20),
                  const Text('Belum ada foto'),
                ],
              ),
      ),
    );
  }
}
