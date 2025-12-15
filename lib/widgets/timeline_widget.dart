import 'package:flutter/material.dart';

class TimelineWidget extends StatelessWidget {
  final double pixelsPerMinute;

  const TimelineWidget({Key? key, required this.pixelsPerMinute}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      top: 0,
      width: 60,
      height: 1440 * pixelsPerMinute,
      child: Container(
        color: Colors.grey.shade200,
        child: ListView.builder(
          itemCount: 48,
          itemBuilder: (context, index) {
            int hour = index ~/ 2;
            int minute = (index % 2) * 30;
            String time = '${hour % 12 == 0 ? 12 : hour % 12}:${minute.toString().padLeft(2, '0')} ${hour < 12 ? 'AM' : 'PM'}';
            return Container(
              height: 30 * pixelsPerMinute,
              alignment: Alignment.topCenter,
              child: Text(time, style: TextStyle(fontSize: 10)),
            );
          },
        ),
      ),
    );
  }
}
