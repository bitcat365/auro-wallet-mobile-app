import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TokenIcon extends StatelessWidget {
  final double size;
  final String iconUrl;
  final String tokenSymbol;

  const TokenIcon({
    Key? key,
    this.size = 30,
    required this.iconUrl,
    required this.tokenSymbol,
  }) : super(key: key);

  final String holderIconName = "";

  String getHolderIconName() {
    String showIdentityName = tokenSymbol.substring(0, 3);
    showIdentityName = showIdentityName.toUpperCase();
    return showIdentityName;
  }

  @override
  Widget build(BuildContext context) {
    String iconName = getHolderIconName();
    if (iconUrl.isNotEmpty) {
      return Container(
          child: ClipOval(
              child: SvgPicture.asset(
        iconUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
      )));
    } else {
      return Container(
          child: CircleAvatar(
        radius: size / 2,
        backgroundColor: Colors.black.withOpacity(0.3),
        child: Text(
          iconName.isNotEmpty ? iconName.toUpperCase() : '',
          style: TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w400),
        ),
      ));
    }
  }
}