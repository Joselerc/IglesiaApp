import 'package:flutter/material.dart';

class GroupPostContent extends StatefulWidget {
  final String userName;
  final String content;

  const GroupPostContent({
    super.key,
    required this.userName,
    required this.content,
  });

  @override
  State<GroupPostContent> createState() => _GroupPostContentState();
}

class _GroupPostContentState extends State<GroupPostContent> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${widget.userName} ',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
                TextSpan(
                  text: widget.content,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            maxLines: _isExpanded ? null : 2,
            overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
          if (widget.content.length > 100)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _isExpanded ? 'Show less' : 'See more',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}