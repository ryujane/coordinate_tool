import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:excel/excel.dart';
import 'package:file_selector/file_selector.dart';
import 'package:fluent_ui/fluent_ui.dart' hide Page;
import 'package:flutter/foundation.dart';
import 'package:motion_toast/motion_toast.dart';
import 'package:provider/provider.dart';
import 'package:system_theme/system_theme.dart';
import 'package:transformer/constant.dart';
import 'package:transformer/gps_util.dart';
import 'package:transformer/theme.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as flutter_acrylic;
import 'package:dotted_decoration/dotted_decoration.dart';



const String appTitle = '经纬度转换工具';

bool get isDesktop {
  if (kIsWeb) return false;
  return [
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  ].contains(defaultTargetPlatform);
}

void main() async {
  if (!kIsWeb &&
      [
        TargetPlatform.windows,
        TargetPlatform.android,
      ].contains(defaultTargetPlatform)) {
    SystemTheme.accentColor.load();
  }

  if (isDesktop) {
    WidgetsFlutterBinding.ensureInitialized();
    await flutter_acrylic.Window.initialize();
    await WindowManager.instance.ensureInitialized();
    windowManager.waitUntilReadyToShow().then((_) async {
      await windowManager.setTitleBarStyle(
        TitleBarStyle.hidden,
        windowButtonVisibility: false,
      );
      await windowManager.setSize(const Size(650, 520));
      await windowManager.setMinimumSize(const Size(650, 520));
      await windowManager.setMaximumSize(const Size(650, 520));
      await windowManager.center();
      await windowManager.setPreventClose(false);
      await windowManager.setSkipTaskbar(false);
      await windowManager.setFullScreen(false);
      await windowManager.show();

    });
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppTheme(),
      builder: (context, _) {
        final appTheme = context.watch<AppTheme>();
        return FluentApp(
          themeMode: appTheme.mode,
          title: appTitle,
          debugShowCheckedModeBanner: false,
          color: appTheme.color,
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            accentColor: appTheme.color,
            visualDensity: VisualDensity.standard,
            focusTheme: FocusThemeData(
              glowFactor: is10footScreen() ? 2.0 : 0.0,
            ),
          ),
          theme: ThemeData(
            accentColor: appTheme.color,
            visualDensity: VisualDensity.standard,
            focusTheme: FocusThemeData(
              glowFactor: is10footScreen() ? 2.0 : 0.0,
            ),
          ),
          locale: appTheme.locale,
          builder: (context, child) {
            return Directionality(
              textDirection: appTheme.textDirection,
              child: NavigationPaneTheme(
                data: NavigationPaneThemeData(
                  backgroundColor: appTheme.windowEffect !=
                          flutter_acrylic.WindowEffect.disabled
                      ? Colors.transparent
                      : null,
                ),
                child: child!,
              ),
            );
          },
          initialRoute: '/',
          routes: {'/': (context) => MyHomePage()},
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WindowListener {
  final viewKey = GlobalKey(debugLabel: 'Navigation View Key');
  int originIndex = 0;
  int toIndex=0;
  String latitudeIndex='';
  String longitudeIndex='';
  TextEditingController lngController =  TextEditingController();
  TextEditingController latController =  TextEditingController();
  TextEditingController dataRowController =  TextEditingController();
  String filePath = '';
  String fileName='';
  String fileType='';
  int dataRow=1;

  @override
  void initState() {
    windowManager.addListener(this);
    super.initState();
    lngController.text='A';
    latController.text='B';
    dataRowController.text='1';
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appTheme = context.watch<AppTheme>();
    final theme = FluentTheme.of(context);
    return NavigationView(
      key: viewKey,
      appBar: NavigationAppBar(
        automaticallyImplyLeading: false,
          title: () {
            return const DragToMoveArea(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(appTitle),
              ),
            );
          }(),
          actions: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8.0),
              child: ToggleSwitch(
                content: const Text('Dark Mode'),
                checked: FluentTheme.of(context).brightness.isDark,
                onChanged: (v) {
                  if (v) {
                    appTheme.mode = ThemeMode.dark;
                  } else {
                    appTheme.mode = ThemeMode.light;
                  }
                },
              ),
            ),
            const WindowButtons(),
          ])),
      content: ScaffoldPage(
        content: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('源坐标系'),
              Row(
                children: List.generate(3, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: RadioButton(
                        checked: originIndex == index,
                        onChanged: (checked){
                          if(checked){
                            setState(() {
                              originIndex = index;
                            });
                          }
                        },
                        content: Text(coordinates.elementAt(index)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 15,),
              const Text('转换坐标系'),
              Row(
                children: List.generate(3, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: RadioButton(
                      checked: toIndex == index,
                      onChanged: (checked){
                        if(checked){
                          setState(() {
                            toIndex = index;
                          });
                        }
                      },
                      content: Text(coordinates.elementAt(index)),
                    ),
                  );
                },
                ),
              ),
              const SizedBox(height: 15,),
              Row(
                children: [
                  const Text('经度列:'),
                  SizedBox(
                    width: 80,
                    child: TextBox(placeholder: 'A',controller: lngController,),
                  ),
                  const SizedBox(width: 10,),
                  const Text('纬度列:'),
                  SizedBox(
                    width: 80,
                    child: TextBox(placeholder: 'B',controller: latController,),
                  ),
                  const SizedBox(width: 10,),
                  const Text('数据行:'),
                  SizedBox(
                    width: 80,
                    child: TextBox(placeholder: '1',controller: dataRowController,keyboardType: TextInputType.number,),
                  )
                ],
              ),
              const Text('选择文件'),
              DropTarget(
                onDragDone:(details){
                  var files = details.files;
                  if(files.length>1){
                    MotionToast.error(
                        title: const Text("Error"),
                        description: const Text("只支持单个文件处理"))
                        .show(context);
                    return;
                  }
                  var file = files[0];
                  fileName = file.name;
                  filePath = file.path??'';
                  setState(() {
                  });
                },
                child: Container(
                  width: 755,
                  height: 180,
                  decoration: DottedDecoration(
                    color: Colors.blue,
                    shape: Shape.box,
                    borderRadius: const BorderRadius.all(Radius.circular(24)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:  [
                      GestureDetector(
                        child: Icon(FluentIcons.open_file, size: 60, color: Colors.blue),
                        onTap: () async {
                          const XTypeGroup typeGroup = XTypeGroup(
                            label: 'excels',
                            extensions: <String>['xls', 'xlsx'],
                          );
                          final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);

                          if (file != null ) {
                            fileName = file.name;
                            filePath = file.path??'';
                            setState(() {
                            });

                          } else {
                            // User canceled the picker
                          }
                        },
                      ),

                      SizedBox(height: 8),
                      Text(
                        '拖动或选择文件',
                        style: TextStyle(fontSize: 24, color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ),
              if (fileName.isNotEmpty)
                Row(
                  children: [
                    Text('已选择文件:$fileName'),
                    SizedBox(
                      width: 30,
                    ),
                    Button(
                        child: Row(
                          children: const [
                            Icon(FluentIcons.chevron_down_end6, size: 12.0),
                            Text('经纬度转换')
                          ],
                        ),
                        onPressed: () async {
                          if(originIndex==toIndex){
                            MotionToast.error(
                                title: const Text("Error"),
                                description: const Text("坐标系不能是同一个"))
                                .show(context);
                            return;
                          }
                          if(preCheck()){
                            File file =  File(filePath);
                            if(!file.existsSync()){
                              MotionToast.error(
                                  title: const Text("Error"),
                                  description: const Text("文件获取失败"))
                                  .show(context);
                              return;
                            }
                            var excel = Excel.decodeBytes(file.readAsBytesSync());

                            for (var table in excel.tables.keys) {
                              Map<String, Sheet> tables = excel.tables;
                              Sheet? sheet = tables[table];
                              if(sheet!=null){
                                int maxRows = sheet.maxRows;
                                int maxColumns = sheet.maxCols;
                                print('$maxColumns');
                                sheet.insertColumn(maxColumns+1);
                                sheet.insertColumn(maxColumns+2);
                                for(int i=int.parse(dataRowController.text);i<maxRows+1;i++){
                                  Data lngData =sheet.cell(CellIndex.indexByString('${lngController.text}$i'));
                                  Data latData =sheet.cell(CellIndex.indexByString('${latController.text}$i'));
                                  print('index:${lngController.text}$i,lng:${lngData.value}');
                                  if(lngData.cellType!= CellType.double||latData.cellType!= CellType.double){
                                    continue;
                                  }
                                  double lng = lngData.value as double;
                                  double lat = latData.value as double;
                                  List<num> result = transform(originIndex, toIndex, lng, lat);
                                  sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: maxColumns,rowIndex: i-1), result[1]);
                                  sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: maxColumns+1,rowIndex: i-1), result[0]);
                                }

                              }
                            }
                            var bytes = excel.save(fileName: '${filePath}');
                            // File savedFile = File('${filePath}1')
                            // ..createSync(recursive: true)
                            // ..writeAsBytesSync(bytes!);
                            String saveFileName = fileName;
                            final String? path = await getSavePath(suggestedName: fileName);
                            if (path == null) {
                              // Operation was canceled by the user.
                              return;
                            }
                            final Uint8List fileData = Uint8List.fromList(bytes!);
                            final XFile textFile =
                            XFile.fromData(fileData, name: fileName);
                            textFile.saveTo(path).then((value){
                            MotionToast.success(
                            title: const Text("Success"),
                            description: const Text("转换成功"))
                                .show(context);
                            });
                          }
                        })
                  ],
                )
            ],
          ),
        ),

      ),
    );
  }

  bool preCheck(){
    if (lngController.text.isEmpty) {
      MotionToast.error(
          title: const Text("Error"),
          description: const Text("请输入经度列"))
          .show(context);
      return false;
    }
    if (latController.text.isEmpty) {
      MotionToast.error(
          title: const Text("Error"),
          description: const Text("请输入纬度列"))
          .show(context);
      return false;
    }
    if (filePath.isEmpty) {
      MotionToast.error(
          title: const Text("Error"),
          description: const Text("文件地址不合法"))
          .show(context);
      return false;
    }
    return true;
  }
  /// 转换经纬度
  List<num> transform(int originIndex, int toIndex,double lng,double lat){
    if(originIndex==0 && toIndex==1){
      return GpsUtil.gps84_To_Gcj02(lat, lng);
    }
    if(originIndex==0 && toIndex==2){
      return GpsUtil.gps84_To_bd09(lat, lng);
    }
    if(originIndex==1&& toIndex==0){
      return GpsUtil.gcj02_To_Gps84(lat, lng);
    }
    if(originIndex==1&& toIndex==2){
      return GpsUtil.gcj02_To_Bd09(lat, lng);
    }
    if(originIndex==2&& toIndex==0){
      return GpsUtil.bd09_To_gps84(lat, lng);
    }
    if(originIndex==2&& toIndex==1){
      return GpsUtil.bd09_To_Gcj02(lat, lng);
    }
    return [];
  }

  @override
  void onWindowClose() async {
    bool _isPreventClose = await windowManager.isPreventClose();
    if (_isPreventClose) {
      showDialog(
        context: context,
        builder: (_) {
          return ContentDialog(
            title: const Text('Confirm close'),
            content: const Text('Are you sure you want to close this window?'),
            actions: [
              FilledButton(
                child: const Text('Yes'),
                onPressed: () {
                  Navigator.pop(context);
                  windowManager.destroy();
                },
              ),
              Button(
                child: const Text('No'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    }
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = FluentTheme.of(context);

    return SizedBox(
      width: 138,
      height: 50,
      child: WindowCaption(
        brightness: theme.brightness,
        backgroundColor: Colors.transparent,
      ),
    );
  }
}
