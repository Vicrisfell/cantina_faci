import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedChildNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void selecionar(String id) => state = id;
}

final selectedChildIdProvider =
    NotifierProvider<SelectedChildNotifier, String?>(SelectedChildNotifier.new);

class HistoricoFiltroNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void selecionar(String? id) => state = id;
}

final historicoFiltroProvider =
    NotifierProvider<HistoricoFiltroNotifier, String?>(
  HistoricoFiltroNotifier.new,
);

class ShellIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void irPara(int indice) => state = indice;
}

final shellIndexProvider = NotifierProvider<ShellIndexNotifier, int>(
  ShellIndexNotifier.new,
);
