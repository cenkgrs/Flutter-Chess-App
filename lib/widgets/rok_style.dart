import '../l10n/app_language.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const rokBone = Color(0xfff3eee7);
const rokGraphite = Color(0xff202120);

/// Match results use a dedicated, full-width action layout, not a generic alert.
class RokResultDialog extends StatelessWidget {
  const RokResultDialog(
      {super.key,
      this.icon,
      required this.title,
      this.content,
      required this.actions});
  final Widget? icon, content;
  final Widget title;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: DecoratedBox(
            decoration: rokWood,
            child: SingleChildScrollView(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  child: Column(children: [
                    const LText('OYUN TAMAMLANDI',
                        style: TextStyle(
                            color: rokBone, fontSize: 10, letterSpacing: 3)),
                    const SizedBox(height: 18),
                    IconTheme(
                        data: const IconThemeData(color: rokBone, size: 32),
                        child: icon ?? const Icon(Icons.flag_outlined)),
                    const SizedBox(height: 12),
                    DefaultTextStyle(
                        style: const TextStyle(
                            color: rokBone,
                            fontSize: 30,
                            fontWeight: FontWeight.w600),
                        child: title),
                  ])),
              Padding(
                  padding: const EdgeInsets.all(20),
                  child: Theme(
                      data: rokTheme().copyWith(
                        textButtonTheme: TextButtonThemeData(
                            style: TextButton.styleFrom(
                                foregroundColor: rokBone,
                                minimumSize: const Size.fromHeight(46))),
                        filledButtonTheme: FilledButtonThemeData(
                            style: FilledButton.styleFrom(
                                backgroundColor: rokGraphite,
                                foregroundColor: rokBone,
                                minimumSize: const Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)))),
                      ),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (content != null)
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: DefaultTextStyle(
                                      style: const TextStyle(
                                          color: rokBone,
                                          height: 1.5,
                                          fontSize: 14),
                                      textAlign: TextAlign.center,
                                      child: content!)),
                            ...actions.map((action) => Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: action)),
                          ]))),
            ]))),
      );
}

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

class RokWoodDialog extends StatelessWidget {
  const RokWoodDialog(
      {super.key,
      required this.title,
      required this.content,
      this.actions = const []});
  final Widget title, content;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xff8b7966))),
        child: DecoratedBox(
            decoration: rokWood,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Theme(
                  data: rokTheme(),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DefaultTextStyle(
                            style: const TextStyle(
                                color: rokBone,
                                fontSize: 24,
                                fontWeight: FontWeight.w600),
                            child: title),
                        const SizedBox(height: 16),
                        DefaultTextStyle(
                            style: const TextStyle(color: rokBone, height: 1.4),
                            child: content),
                        const SizedBox(height: 12),
                        ...actions,
                      ])),
            )),
      );
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

/// The shell every bottom sheet in ROK wears: the board's own dark wood, a
/// grab handle, and a titled header. Sheets used to be bone-coloured panels
/// on a dark wooden app, which read as borrowed from somewhere else.
class RokSheet extends StatelessWidget {
  const RokSheet({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.note,
    this.onBack,
  });

  final IconData icon;
  final String title;
  final String? note;
  final Widget child;

  /// When a sheet has steps, going back is a step back inside it rather than
  /// closing it and making the player start again from the card.
  final VoidCallback? onBack;

  static const border = Color(0xff6d6356);
  static const muted = Color(0xffb9aea5);

  @override
  Widget build(BuildContext context) => Container(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .78),
        padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
        decoration: const BoxDecoration(
          color: Color(0xff2a1a10),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(top: BorderSide(color: Color(0xff6d6356))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: muted,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 17),
            Row(children: [
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: rokBone,
                  tooltip: 'Geri',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                )
              else
                Icon(icon, color: rokBone),
              const SizedBox(width: 10),
              Expanded(
                child: LText(title,
                    style: const TextStyle(
                      color: rokBone,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    )),
              ),
            ]),
            if (note != null) ...[
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: LText(note!,
                    style: const TextStyle(color: muted, fontSize: 13)),
              ),
            ],
            const SizedBox(height: 14),
            Flexible(child: child),
          ],
        ),
      );
}

/// A tappable row inside a [RokSheet].
class RokSheetRow extends StatelessWidget {
  const RokSheetRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.icon,
    this.trailing,
  });

  final String title, subtitle;
  final VoidCallback onTap;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0x33000000),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: RokSheet.border),
            ),
            child: Row(children: [
              if (icon != null) ...[
                Icon(icon, color: rokBone, size: 26),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LText(title,
                        style: const TextStyle(
                            color: rokBone,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    LText(subtitle,
                        style: const TextStyle(
                            color: RokSheet.muted, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              trailing ??
                  const Icon(Icons.chevron_right_rounded,
                      color: RokSheet.muted),
            ]),
          ),
        ),
      );
}

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
