import 'dart:math';
import 'dart:ui';


// Posición de una cara en un instante del video (o en una foto).
// Todas las coordenadas van de 0 a 1, relativas al ancho/alto de la imagen,
// así sirven sin importar el tamaño en el que se muestre.
class FaceFrame {

  final int timeMs;
  final Offset leftEye;
  final Offset rightEye;
  final Offset nose;
  final Offset mouth;
  final Rect box;

  const FaceFrame({
    this.timeMs = 0,
    required this.leftEye,
    required this.rightEye,
    required this.nose,
    required this.mouth,
    required this.box,
  });

  Offset get eyesCenter => Offset.lerp( leftEye, rightEye, 0.5 )!;

  // Inclinación de la cabeza (en radianes) según la línea de los ojos
  double get roll => atan2( rightEye.dy - leftEye.dy, rightEye.dx - leftEye.dx );

  FaceFrame mirrored() => FaceFrame(
    timeMs: timeMs,
    // Al reflejar, el ojo izquierdo pasa a la derecha
    leftEye: Offset( 1 - rightEye.dx, rightEye.dy ),
    rightEye: Offset( 1 - leftEye.dx, leftEye.dy ),
    nose: Offset( 1 - nose.dx, nose.dy ),
    mouth: Offset( 1 - mouth.dx, mouth.dy ),
    box: Rect.fromLTRB( 1 - box.right, box.top, 1 - box.left, box.bottom ),
  );

  FaceFrame withTime( int newTimeMs ) => FaceFrame(
    timeMs: newTimeMs,
    leftEye: leftEye,
    rightEye: rightEye,
    nose: nose,
    mouth: mouth,
    box: box,
  );

  // Formato compacto para guardarlo en Firestore
  Map<String, dynamic> toJson() => {
    't': timeMs,
    'p': [
      leftEye.dx, leftEye.dy, rightEye.dx, rightEye.dy,
      nose.dx, nose.dy, mouth.dx, mouth.dy,
      box.left, box.top, box.right, box.bottom,
    ].map( (v) => double.parse( v.toStringAsFixed(4) ) ).toList(),
  };

  factory FaceFrame.fromJson( Map<String, dynamic> json ) {
    final p = ( json['p'] as List ).map( (v) => (v as num).toDouble() ).toList();
    return FaceFrame(
      timeMs: json['t'] ?? 0,
      leftEye: Offset( p[0], p[1] ),
      rightEye: Offset( p[2], p[3] ),
      nose: Offset( p[4], p[5] ),
      mouth: Offset( p[6], p[7] ),
      box: Rect.fromLTRB( p[8], p[9], p[10], p[11] ),
    );
  }

  // Busca la cara más cercana al tiempo actual del video
  static FaceFrame? atTime( List<FaceFrame> track, int timeMs ) {
    if ( track.isEmpty ) return null;

    FaceFrame closest = track.first;
    for ( final frame in track ) {
      if ( (frame.timeMs - timeMs).abs() < (closest.timeMs - timeMs).abs() ) closest = frame;
    }
    // Si la cara más cercana está a más de 1 s, es que en ese momento no había cara
    return (closest.timeMs - timeMs).abs() <= 1000 ? closest : null;
  }

}
