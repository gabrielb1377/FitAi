class XpConfig {
  const XpConfig._();

  static const int treinoSerieConcluida = 2;
  static const int treinoExercicioConcluido = 5;
  static const int treinoConcluido = 15;
  static const int treinoPerfeitoBonus = 10;
  static const int recordePessoalBonus = 20;

  static const int corridaIniciar = 0;
  static const int corridaPorMinuto = 1;
  static const int corridaPorKm = 5;
  static const int corridaConcluir = 10;

  static const int passosMetaDiaria = 8;
  static const int passosMetaSemanal = 20;
  static const int passosMetaMensal = 50;

  static const int missaoSimples = 5;
  static const int missaoMedia = 10;
  static const int missaoDificil = 20;

  static const int conquistaComum = 20;
  static const int conquistaRara = 50;
  static const int conquistaEpica = 100;
  static const int conquistaLendaria = 200;

  static int xpParaProximoNivel(int nivelAtual) {
    if (nivelAtual <= 10) return 100;
    if (nivelAtual <= 25) return 150;
    if (nivelAtual <= 50) return 250;
    return 400;
  }

  static int normalizarXp(int xp) {
    return xp < 0 ? 0 : xp;
  }

  static int normalizarGanho(int xpGanho) {
    return xpGanho < 0 ? 0 : xpGanho;
  }
}
