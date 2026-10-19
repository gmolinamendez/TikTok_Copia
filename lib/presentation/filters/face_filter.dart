import 'dart:math';

import 'package:flutter/material.dart';
import 'package:toktok/domain/entities/face_frame.dart';


enum FaceFilter {
  none( 'Sin filtro', '🚫' ),
  glasses( 'Anteojos', '👓' ),
  mustache( 'Bigote', '🥸' ),
  glassesAndMustache( 'Anteojos y bigote', '🤓' ),
  partyHat( 'Cono de cumpleaños', '🥳' ),
  heartGlasses( 'Lentes de corazón', '😍' ),
  funnyHat( 'Sombrero chistoso', '🎩' );

  final String label;
  final String emoji;

  const FaceFilter( this.label, this.emoji );

  static FaceFilter fromId( String id ) =>
    FaceFilter.values.firstWhere( (filter) => filter.name == id, orElse: () => FaceFilter.none );
}


// Dibuja el filtro encima de la cara.
// `face` está en coordenadas 0..1 de la imagen; `size` es el tamaño del widget donde se muestra.
class FaceFilterPainter extends CustomPainter {

  final FaceFilter filter;
  final FaceFrame? face;

  FaceFilterPainter({ required this.filter, required this.face });

  @override
  void paint( Canvas canvas, Size size ) {
    final face = this.face;
    if ( face == null || filter == FaceFilter.none ) return;

    Offset toPixels( Offset p ) => Offset( p.dx * size.width, p.dy * size.height );

    final leftEye = toPixels( face.leftEye );
    final rightEye = toPixels( face.rightEye );
    final center = Offset.lerp( leftEye, rightEye, 0.5 )!;
    final angle = atan2( rightEye.dy - leftEye.dy, rightEye.dx - leftEye.dx );
    // `d` = distancia entre los ojos; todo el filtro se escala con esta medida
    final d = ( rightEye - leftEye ).distance;
    if ( d < 2 ) return;

    // Convierte un punto de la imagen a coordenadas "de la cara" (origen entre los ojos, sin inclinación)
    Offset toLocal( Offset p ) {
      final v = toPixels(p) - center;
      return Offset(
        v.dx * cos(-angle) - v.dy * sin(-angle),
        v.dx * sin(-angle) + v.dy * cos(-angle),
      );
    }

    final mustacheY = toLocal( Offset.lerp( face.nose, face.mouth, 0.55 )! ).dy;
    final headTop = min( -0.9 * d, toLocal( Offset( face.box.center.dx, face.box.top ) ).dy );

    canvas.save();
    canvas.translate( center.dx, center.dy );
    canvas.rotate( angle );

    switch ( filter ) {
      case FaceFilter.glasses:
        _drawGlasses( canvas, d );
        break;
      case FaceFilter.mustache:
        _drawMustache( canvas, d, mustacheY );
        break;
      case FaceFilter.glassesAndMustache:
        _drawGlasses( canvas, d );
        _drawMustache( canvas, d, mustacheY );
        break;
      case FaceFilter.partyHat:
        _drawPartyHat( canvas, d, headTop );
        break;
      case FaceFilter.heartGlasses:
        _drawHeartGlasses( canvas, d );
        break;
      case FaceFilter.funnyHat:
        _drawFunnyHat( canvas, d, headTop );
        break;
      case FaceFilter.none:
        break;
    }

    canvas.restore();
  }

  void _drawGlasses( Canvas canvas, double d ) {
    final radius = 0.42 * d;
    final frame = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.09 * d;
    final lens = Paint()..color = Colors.lightBlueAccent.withValues( alpha: 0.25 );

    for ( final x in [ -0.5 * d, 0.5 * d ] ) {
      canvas.drawCircle( Offset( x, 0 ), radius, lens );
      canvas.drawCircle( Offset( x, 0 ), radius, frame );
    }
    // Puente y patitas
    canvas.drawArc(
      Rect.fromCenter( center: Offset( 0, 0.02 * d ), width: 0.2 * d, height: 0.2 * d ),
      pi, pi, false, frame );
    canvas.drawLine( Offset( -0.92 * d, -0.05 * d ), Offset( -1.15 * d, -0.12 * d ), frame );
    canvas.drawLine( Offset( 0.92 * d, -0.05 * d ), Offset( 1.15 * d, -0.12 * d ), frame );
  }

  void _drawMustache( Canvas canvas, double d, double y ) {
    final paint = Paint()..color = const Color(0xFF3B2314);
    final w = 0.75 * d;

    for ( final side in [ -1.0, 1.0 ] ) {
      final path = Path()
        ..moveTo( 0, y - 0.08 * d )
        ..quadraticBezierTo( side * 0.45 * w, y - 0.32 * d, side * w, y + 0.05 * d )
        ..quadraticBezierTo( side * 1.15 * w, y - 0.12 * d, side * 1.05 * w, y - 0.22 * d )
        ..quadraticBezierTo( side * 1.25 * w, y + 0.2 * d, side * 0.55 * w, y + 0.12 * d )
        ..quadraticBezierTo( side * 0.2 * w, y + 0.08 * d, 0, y + 0.06 * d )
        ..close();
      canvas.drawPath( path, paint );
    }
  }

  void _drawPartyHat( Canvas canvas, double d, double headTop ) {
    final baseY = headTop + 0.15 * d;
    final halfBase = 0.6 * d;
    final tip = Offset( 0, baseY - 1.7 * d );

    final cone = Path()
      ..moveTo( -halfBase, baseY )
      ..lineTo( tip.dx, tip.dy )
      ..lineTo( halfBase, baseY )
      ..close();

    canvas.drawPath( cone, Paint()..color = const Color(0xFFFF4FA3) );

    // Rayas de colores dentro del cono
    canvas.save();
    canvas.clipPath( cone );
    final stripe = Paint()
      ..color = const Color(0xFFFFE14D)
      ..strokeWidth = 0.14 * d;
    for ( var i = -3; i <= 3; i++ ) {
      final x = i * 0.45 * d;
      canvas.drawLine( Offset( x - d, baseY ), Offset( x + d, tip.dy ), stripe );
    }
    canvas.restore();

    // Bolitas de colores en el cono
    final dots = [ Colors.cyanAccent, Colors.white, Colors.greenAccent ];
    for ( var i = 0; i < 3; i++ ) {
      canvas.drawCircle(
        Offset( (i - 1) * 0.25 * d, baseY - ( 0.35 + i * 0.35 ) * d ),
        0.07 * d,
        Paint()..color = dots[i],
      );
    }

    // Pompón y borde
    canvas.drawCircle( tip, 0.18 * d, Paint()..color = Colors.white );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter( center: Offset( 0, baseY ), width: 2.1 * halfBase, height: 0.16 * d ),
        Radius.circular( 0.08 * d ),
      ),
      Paint()..color = Colors.white,
    );
  }

  void _drawHeartGlasses( Canvas canvas, double d ) {
    final fill = Paint()..color = const Color(0xFFE5153B).withValues( alpha: 0.9 );
    final border = Paint()
      ..color = const Color(0xFF8A0020)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.06 * d;

    for ( final x in [ -0.5 * d, 0.5 * d ] ) {
      final heart = _heartPath( Offset( x, 0.02 * d ), 0.95 * d );
      canvas.drawPath( heart, fill );
      canvas.drawPath( heart, border );
    }
    canvas.drawLine( Offset( -0.08 * d, -0.12 * d ), Offset( 0.08 * d, -0.12 * d ), border );
    canvas.drawLine( Offset( -0.95 * d, -0.15 * d ), Offset( -1.15 * d, -0.2 * d ), border );
    canvas.drawLine( Offset( 0.95 * d, -0.15 * d ), Offset( 1.15 * d, -0.2 * d ), border );
  }

  Path _heartPath( Offset center, double width ) {
    final w = width / 2;
    final top = center.dy - 0.32 * width;
    final bottom = center.dy + 0.42 * width;
    return Path()
      ..moveTo( center.dx, bottom )
      ..cubicTo( center.dx - 1.1 * w, center.dy + 0.05 * width, center.dx - 0.95 * w, top - 0.1 * width, center.dx, top + 0.18 * width )
      ..cubicTo( center.dx + 0.95 * w, top - 0.1 * width, center.dx + 1.1 * w, center.dy + 0.05 * width, center.dx, bottom )
      ..close();
  }

  void _drawFunnyHat( Canvas canvas, double d, double headTop ) {
    final brimY = headTop + 0.1 * d;
    final crownHeight = 1.4 * d;
    final crownWidth = 1.25 * d;

    // Copa (un poco ladeada para que se vea chistosa)
    canvas.save();
    canvas.translate( 0, brimY );
    canvas.rotate( -0.12 );

    final crown = RRect.fromRectAndCorners(
      Rect.fromLTWH( -crownWidth / 2, -crownHeight, crownWidth, crownHeight ),
      topLeft: Radius.circular( 0.15 * d ),
      topRight: Radius.circular( 0.15 * d ),
    );
    canvas.drawRRect( crown, Paint()..color = const Color(0xFF6A1B9A) );

    // Rayas verdes
    final stripe = Paint()..color = const Color(0xFF76FF03);
    for ( var i = 0; i < 3; i++ ) {
      canvas.drawRect(
        Rect.fromLTWH( -crownWidth / 2, -crownHeight + ( 0.2 + i * 0.4 ) * d, crownWidth, 0.14 * d ),
        stripe,
      );
    }

    // Ala
    canvas.drawOval(
      Rect.fromCenter( center: Offset.zero, width: 2.1 * d, height: 0.38 * d ),
      Paint()..color = const Color(0xFF4A148C),
    );

    // Flor
    final flowerCenter = Offset( crownWidth / 2 - 0.05 * d, -0.35 * d );
    for ( var i = 0; i < 6; i++ ) {
      final a = i * pi / 3;
      canvas.drawCircle(
        flowerCenter + Offset( cos(a), sin(a) ) * 0.16 * d,
        0.12 * d,
        Paint()..color = const Color(0xFFFFEB3B),
      );
    }
    canvas.drawCircle( flowerCenter, 0.1 * d, Paint()..color = const Color(0xFFFF6F00) );

    canvas.restore();
  }

  @override
  bool shouldRepaint( FaceFilterPainter oldDelegate ) =>
    oldDelegate.filter != filter || oldDelegate.face != face;
}


// Lista horizontal para escoger filtro
class FilterSelector extends StatelessWidget {

  final FaceFilter selected;
  final ValueChanged<FaceFilter> onSelected;

  const FilterSelector({ super.key, required this.selected, required this.onSelected });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 92,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric( horizontal: 12 ),
        children: FaceFilter.values.map( (filter) {
          final isSelected = filter == selected;
          return GestureDetector(
            onTap: () => onSelected( filter ),
            child: Container(
              width: 76,
              margin: const EdgeInsets.symmetric( horizontal: 4 ),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
                border: Border.all( color: isSelected ? Colors.white : Colors.transparent, width: 2 ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text( filter.emoji, style: const TextStyle( fontSize: 26 ) ),
                  const SizedBox( height: 4 ),
                  Text(
                    filter.label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: const TextStyle( fontSize: 10, color: Colors.white ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
