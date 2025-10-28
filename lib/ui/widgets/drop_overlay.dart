import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

/// Unified drag/drop overlay:
/// - Web: listens to document dragover/dragleave/drop and forwards file names
/// - Other platforms: fully click-through no-op so the composer remains interactive
class DropOverlay extends StatefulWidget {
  final VoidCallback onHover;
  final VoidCallback onLeave;
  final void Function(List<String> names) onDrop;

  const DropOverlay({
    super.key,
    required this.onHover,
    required this.onLeave,
    required this.onDrop,
  });

  @override
  State<DropOverlay> createState() => _DropOverlayState();
}

class _DropOverlayState extends State<DropOverlay> {
  final _key = GlobalKey();

  // Web-only listeners (kept typed as dynamic to avoid analysis warnings on non-web)
  html.EventListener? _dragOverSub;
  html.EventListener? _dropSub;
  html.EventListener? _dragLeaveSub;

  Rect _bounds() {
    final box = _key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return Rect.zero;
    final topLeft = box.localToGlobal(Offset.zero);
    return topLeft & box.size;
  }

  bool _inside(html.MouseEvent e) {
    final r = _bounds();
    final x = e.client.x.toDouble();
    final y = e.client.y.toDouble();
    return r.contains(Offset(x, y));
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return; // non-web: no listeners

    _dragOverSub = (event) {
      final e = event as html.MouseEvent;
      if (_inside(e)) {
        e.preventDefault(); // allow drop
        widget.onHover();
      }
    };

    _dragLeaveSub = (event) {
      final e = event as html.MouseEvent;
      if (!_inside(e)) widget.onLeave();
    };

    _dropSub = (event) {
      final e = event as html.MouseEvent;
      if (_inside(e)) {
        e.preventDefault();
        final files = e.dataTransfer.files;
        final names = <String>[];
        if (files != null) {
          for (var i = 0; i < files.length; i++) {
            final f = files[i];
            names.add(f.name);
          }
        }
        if (names.isNotEmpty) {
          widget.onDrop(names);
        } else {
          widget.onLeave();
        }
      } else {
        widget.onLeave();
      }
    };

    html.document.addEventListener('dragover', _dragOverSub);
    html.document.addEventListener('dragleave', _dragLeaveSub);
    html.document.addEventListener('drop', _dropSub);
  }

  @override
  void dispose() {
    if (kIsWeb) {
      if (_dragOverSub != null) {
        html.document.removeEventListener('dragover', _dragOverSub);
        _dragOverSub = null;
      }
      if (_dragLeaveSub != null) {
        html.document.removeEventListener('dragleave', _dragLeaveSub);
        _dragLeaveSub = null;
      }
      if (_dropSub != null) {
        html.document.removeEventListener('drop', _dropSub);
        _dropSub = null;
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fully click-through; visuals are rendered by ContentDropzone when needed.
    return IgnorePointer(ignoring: true, child: SizedBox.expand(key: _key));
  }
}
