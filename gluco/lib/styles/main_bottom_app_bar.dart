import 'package:flutter/material.dart';
import 'package:gluco/styles/custom_colors.dart';
import 'package:gluco/extensions/buildcontext/loc.dart';

enum MainBottomAppBarEnum { home, history }

class MainBottomAppBar extends StatelessWidget {
  const MainBottomAppBar({Key? key, required this.page}) : super(key: key);

  final MainBottomAppBarEnum page;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      elevation: 0.0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: page == MainBottomAppBarEnum.home
                      ? BorderSide(
                          width: 4.0,
                          color: CustomColors.lightBlue.withOpacity(1.0))
                      : BorderSide.none,
                ),
              ),
              child: TextButton(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    context.loc.measure,
                    style: TextStyle(
                      color: page == MainBottomAppBarEnum.home
                          ? CustomColors.lightBlue.withOpacity(1.0)
                          : Colors.grey,
                      fontWeight: page == MainBottomAppBarEnum.home
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 18,
                    ),
                  ),
                ),
                onPressed: () async {
                  if (page != MainBottomAppBarEnum.home) {
                    Navigator.popUntil(context, ModalRoute.withName('/home'));
                  }
                },
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  top: page == MainBottomAppBarEnum.history
                      ? BorderSide(
                          width: 4.0,
                          color: CustomColors.lightBlue.withOpacity(1.0))
                      : BorderSide.none,
                ),
              ),
              child: TextButton(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    context.loc.historic,
                    style: TextStyle(
                      color: page == MainBottomAppBarEnum.history
                          ? CustomColors.lightBlue.withOpacity(1.0)
                          : Colors.grey,
                      fontWeight: page == MainBottomAppBarEnum.history
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 18,
                    ),
                  ),
                ),
                onPressed: () async {
                  if (page != MainBottomAppBarEnum.history) {
                    await Navigator.pushNamed(context, '/history');
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
