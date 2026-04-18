import 'package:flutter/material.dart';

class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const FloatingNavBar(
      {Key? key, required this.currentIndex, required this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF171717).withOpacity(0.9), // Neutral 900
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: currentIndex,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withOpacity(0.4),
          showSelectedLabels: true,
          showUnselectedLabels: false,
          selectedFontSize: 12,
          onTap: onTap,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.play_circle_outline,
                  color: currentIndex == 0 ? Colors.indigoAccent : null),
              label: 'Anime',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_border,
                  color: currentIndex == 1 ? Colors.white : null),
              label: 'Library',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined,
                  color: currentIndex == 2 ? Colors.pinkAccent : null),
              label: 'Manga',
            ),
          ],
        ),
      ),
    );
  }
}
