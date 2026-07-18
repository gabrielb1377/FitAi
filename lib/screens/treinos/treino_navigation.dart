import 'package:flutter/material.dart';

import '../../features/auth/presentation/pages/auth_splash_page.dart';

/// Centraliza o retorno seguro das rotas de Planos e Treino.
///
/// Em fluxos normais, preserva a pilha atual. Quando uma tela e aberta
/// diretamente no debug ou na web, evita que o botao voltar encerre o app.
abstract final class TreinoNavigation {
  static void popOrHome(BuildContext context) {
    final navigator = Navigator.of(context);
    final route = ModalRoute.of(context);
    if (navigator.canPop() && route?.isFirst == false) {
      navigator.pop();
      return;
    }

    navigator.pushReplacement<void, void>(
      MaterialPageRoute<void>(builder: (_) => const AuthSplashPage()),
    );
  }
}
