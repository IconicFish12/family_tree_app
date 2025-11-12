import 'package:flutter/material.dart';

/// Custom back button yang disabled kalau tidak ada halaman sebelumnya
class CustomBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;
  final double? size;

  const CustomBackButton({
    super.key,
    this.onPressed,
    this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    return IconButton(
      icon: Icon(
        Icons.arrow_back,
        size: size,
        color: canPop ? (color ?? Colors.black) : Colors.grey[400],
      ),
      onPressed: canPop
          ? (onPressed ?? () => Navigator.of(context).pop())
          : null,
      tooltip: canPop ? 'Kembali' : 'Tidak ada halaman sebelumnya',
    );
  }
}
