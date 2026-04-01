import 'package:flutter/material.dart';

class TutorialController {
  static void showHighlight({
    required BuildContext context,
    required GlobalKey targetKey,
    required String text,
    required VoidCallback onNext,
  }) {
    final RenderBox? renderBox = targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    final double screenHeight = MediaQuery.of(context).size.height;


    bool isBottomHalf = offset.dy > screenHeight / 2;

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.8),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Positioned(
                  top: offset.dy - 5,
                  left: offset.dx - 5,
                  child: Container(
                    height: size.height + 10,
                    width: size.width + 10,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(

            top: isBottomHalf ? null : offset.dy + size.height + 20,

            bottom: isBottomHalf ? (screenHeight - offset.dy) + 20 : null,
            left: 20,
            right: 20,
            child: DefaultTextStyle(
              style: const TextStyle(decoration: TextDecoration.none),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    ),
                    onPressed: () {
                      overlayEntry.remove();
                      onNext();
                    },
                    child: const Text("Next", style: TextStyle(color: Colors.white, fontSize: 16)),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(overlayEntry);
  }
}