import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme.dart';

class MapCursorControl extends StatefulWidget {
  final MapController mapController;
  final double initialZoom;
  final VoidCallback? onRecenter;
  final Color? color;

  const MapCursorControl({
    super.key,
    required this.mapController,
    this.initialZoom = 13,
    this.onRecenter,
    this.color,
  });

  @override
  State<MapCursorControl> createState() => _MapCursorControlState();
}

class _MapCursorControlState extends State<MapCursorControl> {
  double _zoom = 13;
  bool _dragging = false;
  Offset? _dragStart;
  LatLng? _centerStart;

  static const double _maxDrag = 40;

  @override
  void initState() {
    super.initState();
    _zoom = widget.initialZoom;
  }

  Offset _clamp(Offset delta) {
    final distance = sqrt(delta.dx * delta.dx + delta.dy * delta.dy);
    if (distance <= _maxDrag) return delta;
    final factor = _maxDrag / distance;
    return Offset(delta.dx * factor, delta.dy * factor);
  }

  void _handlePanStart(DragStartDetails details) {
    _dragStart = details.localPosition;
    _centerStart = widget.mapController.camera.center;
    setState(() => _dragging = true);
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_dragStart == null || _centerStart == null) return;

    final delta = details.localPosition - _dragStart!;
    final clamped = _clamp(delta);

    final normalizedX = clamped.dx / _maxDrag;
    final normalizedY = clamped.dy / _maxDrag;

    final currentCenter = widget.mapController.camera.center;
    final latDelta = normalizedY * 0.015;
    final lngDelta = normalizedX * 0.015;

    final newCenter = LatLng(
      currentCenter.latitude - latDelta,
      currentCenter.longitude + lngDelta,
    );

    widget.mapController.move(newCenter, _zoom);
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() => _dragging = false);
    _dragStart = null;
    _centerStart = null;
  }

  void _zoomIn() {
    setState(() => _zoom = min(_zoom + 1, 18));
    final center = widget.mapController.camera.center;
    widget.mapController.move(center, _zoom);
  }

  void _zoomOut() {
    setState(() => _zoom = max(_zoom - 1, 3));
    final center = widget.mapController.camera.center;
    widget.mapController.move(center, _zoom);
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? SirexeTheme.accent;
    final size = 110.0;
    final thumbSize = 44.0;

    return Positioned(
      right: 16,
      bottom: 24,
      child: Column(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: SirexeTheme.surface.withOpacity(0.92),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.45), width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: GestureDetector(
              onPanStart: _handlePanStart,
              onPanUpdate: _handlePanUpdate,
              onPanEnd: _handlePanEnd,
              behavior: HitTestBehavior.translucent,
              child: CustomPaint(
                size: Size(size, size),
                painter: _CursorPainter(
                  dragging: _dragging,
                  color: color,
                  thumbSize: thumbSize,
                  maxDrag: _maxDrag,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _CursorButton(
            icon: Icons.add,
            onTap: _zoomIn,
            color: color,
          ),
          const SizedBox(height: 8),
          _CursorButton(
            icon: Icons.remove,
            onTap: _zoomOut,
            color: color,
          ),
          if (widget.onRecenter != null) ...[
            const SizedBox(height: 8),
            _CursorButton(
              icon: Icons.my_location,
              onTap: widget.onRecenter!,
              color: color,
            ),
          ],
        ],
      ),
    );
  }
}

class _CursorPainter extends CustomPainter {
  final bool dragging;
  final Color color;
  final double thumbSize;
  final double maxDrag;

  _CursorPainter({
    required this.dragging,
    required this.color,
    required this.thumbSize,
    required this.maxDrag,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final ringPaint = Paint()
      ..color = color.withOpacity(dragging ? 0.55 : 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final trackPaint = Paint()
      ..color = color.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, size.width / 2 - 6, ringPaint);
    canvas.drawLine(
      Offset(center.dx - 8, center.dy),
      Offset(center.dx + 8, center.dy),
      trackPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 8),
      Offset(center.dx, center.dy + 8),
      trackPaint,
    );

    final thumbOffset = dragging ? Offset.zero : Offset.zero;
    final thumbCenter = center + thumbOffset;
    final thumbRect = Rect.fromCenter(
      center: thumbCenter,
      width: thumbSize,
      height: thumbSize,
    );
    final thumbPaint = Paint()
      ..color = dragging ? color.withOpacity(0.35) : color.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    final thumbBorder = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    canvas.drawRRect(
      RRect.fromRectAndRadius(thumbRect, const Radius.circular(14)),
      thumbPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(thumbRect, const Radius.circular(14)),
      thumbBorder,
    );

    final icon = Icons.arrow_forward_rounded;
    final text = String.fromCharCode(icon.codePoint);
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontFamily: icon.fontFamily, fontSize: 16, color: color),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(
      canvas,
      thumbCenter - Offset(tp.width / 2, tp.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _CursorPainter old) =>
      old.dragging != dragging || old.color != color;
}

class _CursorButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  const _CursorButton({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: SirexeTheme.surface.withOpacity(0.92),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.45), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
