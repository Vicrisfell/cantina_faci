import 'package:flutter/material.dart';

import '../theme/cantina_colors.dart';

/// Toldo listrado vinho/branco com garfo, colher e alça em vinho.
class CantinaLogo extends StatelessWidget {
  const CantinaLogo({super.key, this.tamanho = 160});

  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: tamanho,
      height: tamanho * 0.9,
      child: const CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final aH = w * 0.30; // altura do toldo
    final topoEsq = w * 0.13;
    final topoDir = w * 0.87;

    for (var i = 0; i < 5; i++) {
      final f0 = i / 5;
      final f1 = (i + 1) / 5;
      final t0 = topoEsq + (topoDir - topoEsq) * f0;
      final t1 = topoEsq + (topoDir - topoEsq) * f1;
      final b0 = w * f0;
      final b1 = w * f1;
      final cor = i.isEven ? CantinaColors.vermelhoToldo : Colors.white;
      final paint = Paint()..color = cor;

      canvas.drawPath(
        Path()
          ..moveTo(t0, 0)
          ..lineTo(t1, 0)
          ..lineTo(b1, aH)
          ..lineTo(b0, aH)
          ..close(),
        paint,
      );
      // Franja arredondada na base do toldo
      final r = (b1 - b0) / 2;
      canvas.drawPath(
        Path()
          ..addArc(
            Rect.fromCircle(center: Offset((b0 + b1) / 2, aH), radius: r),
            0,
            3.14159265,
          )
          ..close(),
        paint,
      );
    }

    final corpo = Paint()
      ..color = CantinaColors.vinho
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.035
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.07, aH + w * 0.05)
        ..lineTo(w * 0.07, w * 0.55)
        ..quadraticBezierTo(w * 0.07, w * 0.84, w * 0.5, w * 0.84)
        ..quadraticBezierTo(w * 0.93, w * 0.84, w * 0.93, w * 0.55)
        ..lineTo(w * 0.93, aH + w * 0.05),
      corpo,
    );

    final fill = Paint()..color = CantinaColors.vinho;
    RRect rr(double x, double y, double ww, double hh) => RRect.fromRectAndRadius(
          Rect.fromLTWH(x * w, y * w, ww * w, hh * w),
          Radius.circular(w * 0.03),
        );
    // Garfo
    canvas.drawRRect(rr(0.30, 0.35, 0.035, 0.15), fill);
    canvas.drawRRect(rr(0.36, 0.35, 0.035, 0.15), fill);
    canvas.drawRRect(rr(0.42, 0.35, 0.035, 0.15), fill);
    canvas.drawRRect(rr(0.28, 0.44, 0.21, 0.06), fill);
    canvas.drawRRect(rr(0.365, 0.48, 0.045, 0.30), fill);
    // Colher
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(0.62 * w, 0.475 * w),
        width: 0.20 * w,
        height: 0.27 * w,
      ),
      fill,
    );
    canvas.drawRRect(rr(0.598, 0.60, 0.045, 0.18), fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
