import 'package:flutter/material.dart';
class gridviewitem extends StatefulWidget {

  String description ;
  IconData icon ;
  Color bg ;
  gridviewitem({
    required this.description,
    required this.icon,
    required this.bg
  });


  @override
  State<gridviewitem> createState() => _gridviewitemState();
}

class _gridviewitemState extends State<gridviewitem> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.0),
      margin: EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: widget.bg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 35,
              color: Colors.white,
            ),
          ),
          Spacer(),
          Text(
            widget.description,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.arrow_circle_right_rounded,
                size: 35,
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
