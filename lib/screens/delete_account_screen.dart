import 'package:flutter/material.dart';
import '../backend/account_repository.dart';
import '../l10n/app_language.dart';
import '../widgets/rok_style.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key, this.deleteAccount});
  final Future<void> Function()? deleteAccount;
  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool accepted = false, busy = false, deleted = false;
  String? error;
  Future<void> submit() async {
    if (!accepted || busy || deleted) return;
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => RokWoodDialog(
              title: const LText('Hesabını kalıcı olarak sil?'),
              content: const LText(
                  'Bu işlem geri alınamaz. Devam etmek istediğinden emin misin?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const LText('Vazgeç')),
                FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const LText('Kalıcı olarak sil'))
              ],
            ));
    if (!mounted || confirmed != true) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await (widget.deleteAccount ?? AccountRepository().deleteAccount)();
      if (mounted) {
        setState(() {
          deleted = true;
          busy = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          busy = false;
          error =
              'Silme işlemi doğrulanamadı. Bağlantını kontrol edip tekrar dene. Sorun sürerse destekle iletişime geç.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !busy && !deleted,
        child: RokScaffold(
          appBar: AppBar(
              title: const LText('Hesabımı sil'),
              automaticallyImplyLeading: !busy && !deleted,
              backgroundColor: Colors.transparent,
              foregroundColor: rokBone),
          body: SafeArea(
              child: ListView(padding: const EdgeInsets.all(24), children: [
            Icon(
                deleted
                    ? Icons.check_circle_outline
                    : Icons.delete_forever_outlined,
                size: 56,
                color: rokBone),
            const SizedBox(height: 24),
            if (deleted) ...[
              const LText('Hesabın silindi',
                  style: TextStyle(fontSize: 26, color: rokBone)),
              const SizedBox(height: 16),
              const LText(
                  'Hesabın ve ilişkili oyun verilerin kaldırıldı. Oturumun kapatıldı.'),
              const SizedBox(height: 24),
              FilledButton(
                  onPressed: () =>
                      Navigator.popUntil(context, (route) => route.isFirst),
                  child: const LText('Menüye dön')),
            ] else ...[
              const LText('Bu işlem geri alınamaz.',
                  style: TextStyle(fontSize: 24, color: rokBone)),
              const SizedBox(height: 16),
              const LText(
                  'Hesabın, profilin, ratinglerin, bulmaca ilerlemen, arkadaşlıkların ve davetlerin kalıcı olarak silinir.'),
              const SizedBox(height: 16),
              const LText(
                  'Sana ait maç ve düello kayıtları rakiplerinin geçmişinden de kaldırılır. Devam eden oyunların sona erer; rakiplerin hesapları ve mevcut ratingleri korunur.'),
              const SizedBox(height: 16),
              const LText(
                  'Silme işlemi sunucuda tamamlandığında onay gösterilir ve oturumun kapatılır.'),
              const SizedBox(height: 24),
              CheckboxListTile(
                  value: accepted,
                  onChanged: busy
                      ? null
                      : (value) => setState(() => accepted = value ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const LText(
                      'Verilerimin kalıcı olarak silineceğini anlıyorum.')),
              if (error != null)
                Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: LText(error!,
                        style: const TextStyle(color: Color(0xffffb4ab)))),
              FilledButton.icon(
                  onPressed: accepted && !busy ? submit : null,
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.delete_forever),
                  label: LText(busy ? 'Siliniyor…' : 'Hesabımı sil')),
            ],
          ])),
        ),
      );
}
