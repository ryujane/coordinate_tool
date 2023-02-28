import 'package:desktop_drop/desktop_drop.dart';
import 'package:dotted_decoration/dotted_decoration.dart';
import 'package:fluent_ui/fluent_ui.dart';

Widget getFileWidget() {
  return DropTarget(
    child: Container(
      width: 755,
      height: 200,
      // 虚线框使用的是一个第三方插件dotted_decoration
      decoration: DottedDecoration(
        color: Colors.blue,
        shape: Shape.box,
        borderRadius: const BorderRadius.all(Radius.circular(24)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children:  [
          Icon(FluentIcons.open_file, size: 60, color: Colors.blue),
          SizedBox(height: 8),
          Text(
            '选择文件',
            style: TextStyle(fontSize: 24, color: Colors.blue),
          ),
        ],
      ),
    ),
  );
}
