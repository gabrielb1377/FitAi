import 'peito.dart';
import 'costas.dart';
import 'biceps.dart';
import 'triceps.dart';
import 'ombros.dart';
import 'antebraco.dart';
import 'abdomen.dart';
import 'pernas.dart';
import 'gluteos.dart';
import 'cardio.dart';
import 'funcional.dart';
import 'alongamento.dart';

import '../../models/exercicio_model.dart';

final List<ExercicioModel> bancoExercicios = [
  ...exerciciosPeito,
  ...exerciciosCostas,
  ...exerciciosBiceps,
  ...exerciciosTriceps,
  ...exerciciosOmbros,
  ...exerciciosAntebraco,
  ...exerciciosAbdomen,
  ...exerciciosPernas,
  ...exerciciosGluteos,
  ...exerciciosCardio,
  ...exerciciosFuncional,
  ...exerciciosAlongamento,
];
