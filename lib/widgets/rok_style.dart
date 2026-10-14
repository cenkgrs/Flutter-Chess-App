import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const rokBone = Color(0xfff3eee7);
const rokGraphite = Color(0xff202120);

class RokDialog extends StatelessWidget {
  const RokDialog(
      {super.key, this.icon, this.title, this.content, this.actions});
  final Widget? icon, title, content;
  final List<Widget>? actions;
  @override
  Widget build(BuildContext context) => Theme(
      data: rokTheme(),
      child: AlertDialog(
        scrollable: true,
        icon: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xff3b3027),
                border: Border.all(color: const Color(0xff8b7966))),
            child: IconTheme(
                data: const IconThemeData(color: rokBone, size: 36),
                child: icon ?? const Icon(Icons.castle_outlined))),
        title: title,
        content: content,
        actions: actions,
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      ));
}

const rokWood = BoxDecoration(
    image: DecorationImage(
        image: AssetImage('lib/images/wood/background.png'),
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(Color(0x40000000), BlendMode.darken)));

ThemeData rokTheme() => ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
          primary: rokBone,
          onPrimary: rokGraphite,
          surface: rokGraphite,
          onSurface: rokBone,
          secondary: Color(0xffb9aea5)),
      scaffoldBackgroundColor: rokGraphite,
      dialogTheme: DialogThemeData(
          backgroundColor: rokGraphite,
          surfaceTintColor: Colors.transparent,
          iconColor: rokBone,
          titleTextStyle: const TextStyle(
              color: rokBone, fontSize: 24, fontWeight: FontWeight.w600),
          contentTextStyle: const TextStyle(
              color: Color(0xffd2c8be), fontSize: 16, height: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xff8b7966)))),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
              backgroundColor: rokBone,
              foregroundColor: rokGraphite,
              minimumSize: const Size(48, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)))),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: rokBone)),
      bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: rokGraphite,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)))),
      progressIndicatorTheme: const ProgressIndicatorThemeData(color: rokBone),
    );

/// Default page surface for every new ROK screen, including its app bar.
class RokScaffold extends StatelessWidget {
  const RokScaffold(
      {super.key,
      this.appBar,
      required this.body,
      this.backgroundColor,
      this.extendBodyBehindAppBar = false,
      this.resizeToAvoidBottomInset});
  final AppBar? appBar;
  final Widget body;
  final Color? backgroundColor;
  final bool extendBodyBehindAppBar;
  final bool? resizeToAvoidBottomInset;
  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: rokWood,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        appBar: appBar == null
            ? null
            : AppBar(
                title: appBar!.title,
                actions: appBar!.actions,
                leading: appBar!.leading,
                automaticallyImplyLeading: appBar!.automaticallyImplyLeading,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                foregroundColor: rokBone,
                elevation: 0,
                scrolledUnderElevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle.light
                    .copyWith(statusBarColor: Colors.transparent)),
        body: body,
      ));
}
