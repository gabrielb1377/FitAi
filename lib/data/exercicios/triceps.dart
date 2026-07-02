import '../../models/exercicio_model.dart';

final List<ExercicioModel> exerciciosTriceps = [
  ExercicioModel(
    id: "triceps_001",
    nome: "Tríceps Pulley (Puxada na Polia)",
    categoria: "Tríceps",
    descricao:
        "Exercício de isolamento para o tríceps realizado na polia alta com barra reta ou corda. Um dos exercícios mais populares e eficientes para o desenvolvimento do tríceps.",
    comoExecutar:
        "Posicione a polia na altura mais alta. Segure a barra ou corda com as mãos na largura dos ombros, cotovelos fixos ao lado do corpo. Empurre o cabo para baixo estendendo completamente os cotovelos. Contraia o tríceps no ponto final e suba controladamente até os antebraços ficarem paralelos ao chão.",
    cuidados:
        "Mantenha os cotovelos fixos ao lado do corpo durante todo o movimento. Não use o corpo para empurrar. O movimento deve ocorrer apenas na articulação do cotovelo. Mantenha o core ativado.",
    musculos: ["Tríceps braquial", "Ancôneo"],
    equipamentos: ["Polia", "Barra reta", "Corda"],
    locais: ["Academia"],
    tags: ["pulley", "polia", "tríceps", "isolamento", "extensão", "cotovelo"],
    dificuldade: "Iniciante",
    objetivo: "Hipertrofia",
    caloriasHora: 260,
    imagem: "assets/gifs/triceps/triceps_pulley_puxada_na_polia.gif",
    video: "",
  ),
  ExercicioModel(
    id: "triceps_002",
    nome: "Tríceps Testa com Barra (Skull Crusher)",
    categoria: "Tríceps",
    descricao:
        "Exercício de isolamento que trabalha intensamente os três feixes do tríceps. Realizado deitado com a barra descendo em direção à testa ou atrás da cabeça.",
    comoExecutar:
        "Deite-se em um banco com a barra segurada acima do peito com pegada fechada. Mantendo os cotovelos fixos apontando para o teto, flexione-os descendo a barra em direção à testa. Ao chegar próximo à testa, estenda os cotovelos empurrando a barra de volta ao ponto inicial.",
    cuidados:
        "Mantenha os cotovelos fixos durante todo o movimento. Não deixe os cotovelos abrirem para os lados. Use um parceiro de treino para segurança. Realize de forma lenta para controlar a barra.",
    musculos: [
      "Tríceps braquial",
      "Cabeça longa do tríceps",
      "Cabeça lateral do tríceps",
    ],
    equipamentos: ["Barra", "Banco", "EZ Bar"],
    locais: ["Academia"],
    tags: ["skull crusher", "tríceps testa", "barra", "isolamento", "tríceps"],
    dificuldade: "Intermediário",
    objetivo: "Hipertrofia",
    caloriasHora: 270,
    imagem: "assets/gifs/triceps/triceps_testa_com_barra_skull_crusher.gif",
    video: "",
  ),
  ExercicioModel(
    id: "triceps_003",
    nome: "Tríceps Francês com Halter",
    categoria: "Tríceps",
    descricao:
        "Exercício de isolamento para o tríceps realizado com halter acima da cabeça, enfatizando a cabeça longa do músculo. Pode ser feito sentado ou em pé.",
    comoExecutar:
        "Segure um halter com as duas mãos por baixo dos pesos, braços estendidos acima da cabeça. Mantenha os cotovelos próximos às orelhas apontando para cima. Flexione os cotovelos descendo o halter atrás da cabeça. Estenda de volta à posição inicial.",
    cuidados:
        "Não deixe os cotovelos se abrirem para os lados. Mantenha o core ativado. Não arque a lombar excessivamente. Realize de forma lenta, especialmente na descida.",
    musculos: ["Cabeça longa do tríceps", "Tríceps braquial"],
    equipamentos: ["Halter"],
    locais: ["Academia", "Casa"],
    tags: [
      "francês",
      "tríceps",
      "halter",
      "cabeça longa",
      "isolamento",
      "acima cabeça",
    ],
    dificuldade: "Iniciante",
    objetivo: "Hipertrofia",
    caloriasHora: 250,
    imagem: "assets/gifs/triceps/triceps_frances_com_halter.gif",
    video: "",
  ),
  ExercicioModel(
    id: "triceps_004",
    nome: "Paralelas (Dips) para Tríceps",
    categoria: "Tríceps",
    descricao:
        "Exercício composto de peso corporal que trabalha o tríceps como músculo principal. A posição do tronco ereto enfatiza o tríceps em detrimento do peitoral.",
    comoExecutar:
        "Apoie-se nas paralelas com os braços estendidos. Mantenha o tronco ereto e as pernas ligeiramente à frente. Desça flexionando os cotovelos até os braços formarem 90 graus, mantendo o tronco vertical. Empurre de volta à posição inicial estendendo os cotovelos.",
    cuidados:
        "Mantenha o tronco ereto para enfatizar o tríceps. Não desça além de 90 graus nos cotovelos. Não balance o corpo. Se for muito difícil, utilize a máquina assistida.",
    musculos: ["Tríceps braquial", "Deltóide anterior", "Peitoral"],
    equipamentos: ["Paralelas", "Máquina assistida"],
    locais: ["Academia"],
    tags: [
      "paralelas",
      "dips",
      "tríceps",
      "peso corporal",
      "composto",
      "força",
    ],
    dificuldade: "Intermediário",
    objetivo: "Força",
    caloriasHora: 340,
    imagem: "assets/gifs/triceps/paralelas_dips_para_triceps.gif",
    video: "",
  ),
  ExercicioModel(
    id: "triceps_005",
    nome: "Tríceps Coice com Halter (Kickback)",
    categoria: "Tríceps",
    descricao:
        "Exercício de isolamento para o tríceps com o tronco inclinado e o braço paralelo ao chão. Enfatiza a contração do músculo no ponto de extensão total.",
    comoExecutar:
        "Incline o tronco até ficar quase paralelo ao chão, apoiando-se em um banco. Com o cotovelo flexionado a 90 graus e o braço paralelo ao corpo, estenda o cotovelo para trás até o braço ficar completamente estendido. Contraia o tríceps no topo e retorne.",
    cuidados:
        "Mantenha o cotovelo fixo ao lado do corpo e elevado. Não balance o braço. Realize de forma lenta, especialmente na volta. Use cargas que permitam a extensão completa.",
    musculos: ["Tríceps braquial", "Cabeça lateral do tríceps"],
    equipamentos: ["Halter", "Banco"],
    locais: ["Academia", "Casa"],
    tags: ["kickback", "coice", "tríceps", "isolamento", "halter", "extensão"],
    dificuldade: "Iniciante",
    objetivo: "Tonificação",
    caloriasHora: 240,
    imagem: "assets/gifs/triceps/triceps_coice_com_halter_kickback.gif",
    video: "",
  ),
  ExercicioModel(
    id: "triceps_006",
    nome: "Desenvolvimento Fechado com Barra (Close Grip Bench Press)",
    categoria: "Tríceps",
    descricao:
        "Variação do supino com pegada fechada que transfere o foco do exercício do peitoral para o tríceps. Exercício composto que permite trabalhar com cargas mais elevadas.",
    comoExecutar:
        "Deite-se no banco com a barra. Pegue a barra com as mãos a cerca de 20-30cm de distância entre si. Desça a barra até o peito em linha reta, mantendo os cotovelos próximos ao corpo. Empurre a barra de volta à posição inicial estendendo os cotovelos.",
    cuidados:
        "Não use pegada muito fechada para evitar dor nos pulsos. Mantenha os cotovelos próximos ao corpo, não abertos. Nunca passe sem travamento com cargas pesadas. Peça um auxílio para desmontar a barra se necessário.",
    musculos: ["Tríceps braquial", "Deltóide anterior", "Peitoral esternal"],
    equipamentos: ["Barra", "Banco"],
    locais: ["Academia"],
    tags: [
      "close grip",
      "supino fechado",
      "tríceps",
      "composto",
      "barra",
      "força",
    ],
    dificuldade: "Intermediário",
    objetivo: "Força",
    caloriasHora: 350,
    imagem:
        "assets/gifs/triceps/desenvolvimento_fechado_com_barra_close_grip_bench_press.gif",
    video: "",
  ),
  ExercicioModel(
    id: "triceps_007",
    nome: "Tríceps Pulley com Corda",
    categoria: "Tríceps",
    descricao:
        "Variação do tríceps pulley utilizando a corda, que permite uma supinação dos pulsos no ponto final, aumentando a contração do tríceps e enfatizando a cabeça lateral.",
    comoExecutar:
        "Posicione a corda na polia alta. Segure as extremidades da corda com as palmas voltadas para dentro. Com os cotovelos fixos ao lado do corpo, empurre a corda para baixo e para fora, abrindo as extremidades ao final do movimento. Contraia fortemente os tríceps e retorne.",
    cuidados:
        "Mantenha os cotovelos fixos durante todo o movimento. A abertura da corda no final é o que diferencia este exercício. Não use o corpo para ajudar. Mantenha o core ativado.",
    musculos: ["Cabeça lateral do tríceps", "Tríceps braquial"],
    equipamentos: ["Polia", "Corda"],
    locais: ["Academia"],
    tags: ["pulley corda", "tríceps", "corda", "cabeça lateral", "isolamento"],
    dificuldade: "Iniciante",
    objetivo: "Hipertrofia",
    caloriasHora: 250,
    imagem: "assets/gifs/triceps/triceps_pulley_com_corda.gif",
    video: "",
  ),
  ExercicioModel(
    id: "triceps_008",
    nome: "Tríceps Francês com Barra EZ",
    categoria: "Tríceps",
    descricao:
        "Variação do skull crusher utilizando a barra EZ, que permite uma posição mais natural dos pulsos e reduz o estresse nas articulações durante o exercício.",
    comoExecutar:
        "Deite-se no banco segurando a barra EZ com pegada fechada. Estenda os braços acima do peito. Mantendo os cotovelos apontando para o teto, desça a barra em direção à testa ou atrás da cabeça, flexionando apenas os cotovelos. Estenda de volta.",
    cuidados:
        "Mantenha os cotovelos fixos e paralelos durante todo o movimento. Não deixe os cotovelos se abrirem excessivamente. Controle a descida. A barra EZ é mais confortável para os pulsos que a barra reta.",
    musculos: [
      "Cabeça longa do tríceps",
      "Cabeça medial do tríceps",
      "Tríceps braquial",
    ],
    equipamentos: ["Barra EZ", "Banco"],
    locais: ["Academia"],
    tags: ["francês EZ", "skull crusher", "tríceps", "barra EZ", "isolamento"],
    dificuldade: "Intermediário",
    objetivo: "Hipertrofia",
    caloriasHora: 265,
    imagem: "assets/gifs/triceps/triceps_frances_com_barra_ez.gif",
    video: "",
  ),
  ExercicioModel(
    id: "triceps_009",
    nome: "Mergulho entre Bancos (Bench Dips)",
    categoria: "Tríceps",
    descricao:
        "Exercício de peso corporal para o tríceps utilizando dois bancos. Ideal para iniciantes ou para treino em casa. Pode ser progredido adicionando peso no colo.",
    comoExecutar:
        "Apoie as mãos em uma banca atrás de você com os dedos apontados para a frente. Estenda as pernas à frente com os calcanhares no outro banco. Desça flexionando os cotovelos até os braços formarem 90 graus. Empurre de volta estendendo completamente os cotovelos.",
    cuidados:
        "Não desça excessivamente para evitar sobrecarga nos ombros. Mantenha os quadris próximos ao banco durante a descida. Para progredir, coloque um peso sobre o colo. Inicie com pernas flexionadas se necessário.",
    musculos: ["Tríceps braquial", "Deltóide anterior"],
    equipamentos: ["Banco", "Peso corporal"],
    locais: ["Academia", "Casa"],
    tags: [
      "bench dips",
      "mergulho",
      "tríceps",
      "peso corporal",
      "iniciante",
      "bancos",
    ],
    dificuldade: "Iniciante",
    objetivo: "Tonificação",
    caloriasHora: 290,
    imagem: "assets/gifs/triceps/mergulho_entre_bancos_bench_dips.gif",
    video: "",
  ),
  ExercicioModel(
    id: "triceps_010",
    nome: "Extensão de Tríceps Acima da Cabeça na Polia",
    categoria: "Tríceps",
    descricao:
        "Exercício para a cabeça longa do tríceps realizado na polia baixa com o corpo de frente à máquina. A posição com os braços acima da cabeça maximiza o alongamento.",
    comoExecutar:
        "Posicione a polia baixa com a corda. De frente à máquina, incline o tronco para frente. Segure a corda atrás da cabeça com os cotovelos dobrados. Estenda os cotovelos para frente e acima, contraindo o tríceps. Retorne controladamente.",
    cuidados:
        "Mantenha os cotovelos próximos à cabeça. Não use impulso. Realize de forma lenta. A posição elevada dos braços é o que torna o exercício eficiente para a cabeça longa.",
    musculos: ["Cabeça longa do tríceps", "Tríceps braquial"],
    equipamentos: ["Polia", "Corda"],
    locais: ["Academia"],
    tags: [
      "extensão overhead polia",
      "cabeça longa",
      "tríceps",
      "polia",
      "isolamento",
    ],
    dificuldade: "Intermediário",
    objetivo: "Hipertrofia",
    caloriasHora: 255,
    imagem:
        "assets/gifs/triceps/extensao_de_triceps_acima_da_cabeca_na_polia.gif",
    video: "",
  ),
  ExercicioModel(
    id: "triceps_011",
    nome: "Flexão de Braços Diamante",
    categoria: "Tríceps",
    descricao:
        "Variação da flexão de braços com as mãos posicionadas em diamante, direcionando o esforço principalmente ao tríceps. Exercício eficiente sem necessidade de equipamento.",
    comoExecutar:
        "Apoie as mãos no chão formando um triângulo com polegares e indicadores. Corpo em linha reta. Desça flexionando os cotovelos até o peito quase tocar as mãos, cotovelos apontando para os lados. Empurre de volta à posição inicial estendendo completamente os cotovelos.",
    cuidados:
        "Mantenha o corpo em linha reta, sem elevar o quadril. Certifique-se de que os pulsos estão confortáveis. Para facilitar, realize nos joelhos. Mantenha o core ativado.",
    musculos: ["Tríceps braquial", "Deltóide anterior", "Peitoral"],
    equipamentos: ["Peso corporal"],
    locais: ["Casa", "Academia"],
    tags: [
      "diamante",
      "flexão",
      "tríceps",
      "sem equipamento",
      "casa",
      "peso corporal",
    ],
    dificuldade: "Intermediário",
    objetivo: "Força",
    caloriasHora: 310,
    imagem: "assets/gifs/triceps/flexao_de_bracos_diamante.gif",
    video: "",
  ),
  ExercicioModel(
    id: "triceps_012",
    nome: "Tríceps Testa com Halteres",
    categoria: "Tríceps",
    descricao:
        "Versão do skull crusher utilizando halteres, que permite posição mais natural dos pulsos e trabalha os braços de forma independente, corrigindo desequilíbrios.",
    comoExecutar:
        "Deite-se no banco segurando um halter em cada mão, braços estendidos acima do peito, palmas voltadas para dentro. Mantendo os cotovelos fixos, desça os halteres em direção às têmporas flexionando os cotovelos. Estenda de volta à posição inicial.",
    cuidados:
        "Mantenha os cotovelos fixos apontados para o teto. Realize de forma lenta e controlada. Não use cargas que comprometam a técnica. Controle a descida especialmente próximo à cabeça.",
    musculos: ["Tríceps braquial", "Cabeça longa do tríceps"],
    equipamentos: ["Halteres", "Banco"],
    locais: ["Academia", "Casa"],
    tags: [
      "tríceps testa halteres",
      "skull crusher",
      "isolamento",
      "halteres",
      "tríceps",
    ],
    dificuldade: "Intermediário",
    objetivo: "Hipertrofia",
    caloriasHora: 260,
    imagem: "assets/gifs/triceps/triceps_testa_com_halteres.gif",
    video: "",
  ),
  ExercicioModel(
    id: "triceps_013",
    nome: "Tríceps Pulley Unilateral",
    categoria: "Tríceps",
    descricao:
        "Versão unilateral do tríceps pulley que trabalha cada braço de forma independente. Permite identificar e corrigir assimetrias entre o tríceps direito e esquerdo.",
    comoExecutar:
        "Posicione a polia alta com a alça D. Segure com uma mão com o cotovelo fixo ao lado do corpo. Empurre a alça para baixo estendendo completamente o cotovelo. Contraia o tríceps no ponto final e suba controladamente. Complete as repetições e troque o braço.",
    cuidados:
        "Mantenha o cotovelo fixo ao lado do corpo. Não use o corpo para ajudar. Esteja consciente de possíveis diferenças de força entre os lados. Não segure a respiração.",
    musculos: ["Tríceps braquial"],
    equipamentos: ["Polia", "Alça D"],
    locais: ["Academia"],
    tags: ["pulley unilateral", "tríceps", "isolamento", "assimetria", "polia"],
    dificuldade: "Iniciante",
    objetivo: "Hipertrofia",
    caloriasHora: 240,
    imagem: "assets/gifs/triceps/triceps_pulley_unilateral.gif",
    video: "",
  ),
  ExercicioModel(
    id: "triceps_014",
    nome: "Paralelas Assistidas",
    categoria: "Tríceps",
    descricao:
        "Versão assistida do exercício de paralelas realizada em máquina específica. Permite que iniciantes realizem o movimento de paralelas com parte do peso corporal suportado.",
    comoExecutar:
        "Ajuste o contrapeso na máquina assistida de acordo com seu nível. Suba na plataforma e apoie os joelhos no pad. Segure as alças com os braços estendidos. Desça flexionando os cotovelos até os braços formarem 90 graus. Empurre de volta à posição inicial.",
    cuidados:
        "Quanto maior o contrapeso, mais fácil o exercício. Mantenha o tronco ereto. Progrida reduzindo o contrapeso gradualmente até conseguir realizar sem assistência.",
    musculos: ["Tríceps braquial", "Deltóide anterior", "Peitoral"],
    equipamentos: ["Máquina de paralelas assistida"],
    locais: ["Academia"],
    tags: [
      "paralelas assistidas",
      "tríceps",
      "iniciante",
      "máquina",
      "progressão",
    ],
    dificuldade: "Iniciante",
    objetivo: "Força",
    caloriasHora: 300,
    imagem: "assets/gifs/triceps/paralelas_assistidas.gif",
    video: "",
  ),
  ExercicioModel(
    id: "triceps_015",
    nome: "Desenvolvimento Fechado com Halteres",
    categoria: "Tríceps",
    descricao:
        "Desenvolvimento utilizando halteres com pegada neutra (palmas voltadas uma para a outra), direcionando maior recrutamento ao tríceps durante o movimento de pressão.",
    comoExecutar:
        "Deite-se no banco segurando um halter em cada mão com as palmas voltadas para dentro. Braços estendidos acima do peito. Desça os halteres mantendo os cotovelos próximos ao corpo até os halteres ficarem na altura dos ombros. Empurre de volta estendendo os cotovelos.",
    cuidados:
        "Mantenha os cotovelos próximos ao corpo durante a descida. As palmas devem ficar voltadas uma para a outra durante todo o movimento. Use amplitude completa.",
    musculos: ["Tríceps braquial", "Peitoral esternal", "Deltóide anterior"],
    equipamentos: ["Halteres", "Banco"],
    locais: ["Academia", "Casa"],
    tags: [
      "supino fechado halteres",
      "tríceps",
      "halteres",
      "pegada neutra",
      "composto",
    ],
    dificuldade: "Intermediário",
    objetivo: "Hipertrofia",
    caloriasHora: 340,
    imagem: "assets/gifs/triceps/desenvolvimento_fechado_com_halteres.gif",
    video: "",
  ),
  ExercicioModel(
    id: "triceps_016",
    nome: "Extensão de Tríceps com Elástico",
    categoria: "Tríceps",
    descricao:
        "Exercício de isolamento para o tríceps realizado com elástico de resistência. Ideal para treino em casa ou como exercício de ativação e finalização de treino.",
    comoExecutar:
        "Prenda um elástico em uma superfície elevada ou pise nele e passe atrás do corpo. Posicione as mãos na altura do peito segurando o elástico. Estenda os cotovelos pressionando o elástico para baixo. Contraia os tríceps no ponto final e retorne controladamente.",
    cuidados:
        "Mantenha os cotovelos fixos durante o movimento. Escolha a tensão do elástico adequada ao seu nível. Certifique-se de que o elástico está bem preso. Realize de forma lenta.",
    musculos: ["Tríceps braquial"],
    equipamentos: ["Elástico de resistência"],
    locais: ["Casa", "Academia"],
    tags: ["extensão elástico", "tríceps", "elástico", "casa", "isolamento"],
    dificuldade: "Iniciante",
    objetivo: "Tonificação",
    caloriasHora: 220,
    imagem: "assets/gifs/triceps/extensao_de_triceps_com_elastico.gif",
    video: "",
  ),
  ExercicioModel(
    id: "triceps_017",
    nome: "Tríceps Francês Unilateral com Halter",
    categoria: "Tríceps",
    descricao:
        "Versão unilateral do tríceps francês, realizada com um halter por vez. Permite maior amplitude de movimento e corrige desequilíbrios entre os braços.",
    comoExecutar:
        "Segure um halter com uma mão estendida acima da cabeça. Mantendo o cotovelo próximo à orelha e apontando para cima, desça o halter atrás da cabeça flexionando o cotovelo. Estenda de volta à posição inicial. Complete as repetições e troque o braço.",
    cuidados:
        "Não deixe o cotovelo se afastar da cabeça. Realize de forma lenta, especialmente na descida. Apoie o cotovelo com a outra mão se necessário. Use cargas que permitam a extensão completa.",
    musculos: ["Cabeça longa do tríceps", "Tríceps braquial"],
    equipamentos: ["Halter"],
    locais: ["Academia", "Casa"],
    tags: [
      "francês unilateral",
      "tríceps",
      "cabeça longa",
      "halter",
      "assimetria",
    ],
    dificuldade: "Iniciante",
    objetivo: "Hipertrofia",
    caloriasHora: 245,
    imagem: "assets/gifs/triceps/triceps_frances_unilateral_com_halter.gif",
    video: "",
  ),
  ExercicioModel(
    id: "triceps_018",
    nome: "Push-Down com Barra V",
    categoria: "Tríceps",
    descricao:
        "Variação do tríceps pulley com a barra em V, que proporciona um ângulo diferenciado de trabalho para o tríceps e pode ser mais confortável para os pulsos.",
    comoExecutar:
        "Posicione a barra V na polia alta. Segure as extremidades da barra com as palmas voltadas para baixo, cotovelos fixos ao lado do corpo. Empurre a barra para baixo até os braços estenderem completamente. Contraia os tríceps e retorne até os antebraços ficarem paralelos ao chão.",
    cuidados:
        "Mantenha os cotovelos fixos ao lado do corpo. Não use cargas que forcem os cotovelos a se moverem. O ângulo da barra V distribui o esforço de forma levemente diferente da barra reta.",
    musculos: ["Tríceps braquial", "Cabeça lateral do tríceps"],
    equipamentos: ["Polia", "Barra V"],
    locais: ["Academia"],
    tags: ["push-down barra V", "tríceps", "polia", "variação", "pulley"],
    dificuldade: "Iniciante",
    objetivo: "Hipertrofia",
    caloriasHora: 255,
    imagem: "assets/gifs/triceps/push_down_com_barra_v.gif",
    video: "",
  ),
  ExercicioModel(
    id: "triceps_019",
    nome: "Tríceps no Banco Inclinado com Halteres",
    categoria: "Tríceps",
    descricao:
        "Exercício de isolamento para o tríceps realizado em banco inclinado, alterando o ângulo de trabalho e recrutando as fibras de forma diferenciada.",
    comoExecutar:
        "Deite-se em um banco inclinado a aproximadamente 30-45 graus, segurando halteres com as palmas voltadas para cima, braços estendidos acima do peito. Flexione os cotovelos descendo os halteres em direção aos ombros, mantendo os cotovelos apontados para cima. Estenda de volta.",
    cuidados:
        "Mantenha os cotovelos fixos, apenas a articulação do cotovelo deve se mover. Não deixe os halteres caírem para os lados. Realize de forma lenta e controlada.",
    musculos: ["Cabeça medial do tríceps", "Tríceps braquial"],
    equipamentos: ["Halteres", "Banco inclinado"],
    locais: ["Academia"],
    tags: [
      "tríceps inclinado",
      "halteres",
      "banco inclinado",
      "ângulo",
      "isolamento",
    ],
    dificuldade: "Intermediário",
    objetivo: "Hipertrofia",
    caloriasHora: 250,
    imagem: "assets/gifs/triceps/triceps_no_banco_inclinado_com_halteres.gif",
    video: "",
  ),
  ExercicioModel(
    id: "triceps_020",
    nome: "Supino Fechado Declinado",
    categoria: "Tríceps",
    descricao:
        "Variação do supino fechado em banco declinado que aumenta o recrutamento da cabeça medial do tríceps e do peitoral inferior. Exige grande estabilidade.",
    comoExecutar:
        "Deite-se no banco declinado com as pernas presas no suporte. Segure a barra com pegada fechada (cerca de 20-30cm entre as mãos). Desça a barra controladamente ao peitoral inferior mantendo os cotovelos próximos ao corpo. Empurre de volta estendendo os cotovelos.",
    cuidados:
        "Sempre use um auxiliar com cargas pesadas no banco declinado. Não use pegada muito estreita para proteger os pulsos. Mantenha os cotovelos próximos ao tronco.",
    musculos: [
      "Tríceps braquial",
      "Cabeça medial do tríceps",
      "Peitoral inferior",
    ],
    equipamentos: ["Barra", "Banco declinado"],
    locais: ["Academia"],
    tags: [
      "supino fechado declinado",
      "tríceps",
      "declinado",
      "peitoral inferior",
      "composto",
    ],
    dificuldade: "Avançado",
    objetivo: "Hipertrofia",
    caloriasHora: 350,
    imagem: "assets/gifs/triceps/supino_fechado_declinado.gif",
    video: "",
  ),
  ExercicioModel(
    id: "triceps_021",
    nome: "Tríceps Coice na Polia",
    categoria: "Tríceps",
    descricao:
        "Variação do tríceps coice utilizando a polia baixa, que mantém tensão constante no músculo durante todo o arco de movimento, ao contrário do halter.",
    comoExecutar:
        "Prenda a alça D na polia baixa. Incline o tronco para frente segurando o cabo com uma mão. Mantendo o cotovelo elevado e paralelo ao tronco, estenda o cotovelo para trás até o braço ficar completamente estendido. Contraia o tríceps e retorne.",
    cuidados:
        "Mantenha o cotovelo fixo e elevado durante todo o movimento. Não balance o corpo. A tensão constante da polia é a vantagem deste exercício. Realize de forma lenta.",
    musculos: ["Cabeça lateral do tríceps", "Tríceps braquial"],
    equipamentos: ["Polia", "Alça D"],
    locais: ["Academia"],
    tags: [
      "coice polia",
      "tríceps",
      "tensão constante",
      "isolamento",
      "kickback polia",
    ],
    dificuldade: "Iniciante",
    objetivo: "Hipertrofia",
    caloriasHora: 240,
    imagem: "assets/gifs/triceps/triceps_coice_na_polia.gif",
    video: "",
  ),
  ExercicioModel(
    id: "triceps_022",
    nome: "Tríceps Nórdico (Ring Dips)",
    categoria: "Tríceps",
    descricao:
        "Exercício avançado de paralelas realizado em argolas olímpicas. A instabilidade das argolas exige muito mais ativação do tríceps e dos músculos estabilizadores.",
    comoExecutar:
        "Segure as argolas com os braços estendidos e estabilize-as próximas ao corpo. Desça flexionando os cotovelos até os braços formarem 90 graus, mantendo as argolas próximas e paralelas ao corpo. Empurre de volta estendendo os cotovelos. Mantenha estabilidade nas argolas durante todo o movimento.",
    cuidados:
        "Domine as paralelas tradicionais antes de tentar nas argolas. A instabilidade aumenta muito a dificuldade. Comece com argolas mais baixas para segurança. Mantenha os punhos firmes.",
    musculos: ["Tríceps braquial", "Deltóide anterior", "Core", "Peitoral"],
    equipamentos: ["Argolas olímpicas"],
    locais: ["Academia"],
    tags: [
      "ring dips",
      "argolas",
      "tríceps",
      "avançado",
      "calistenia",
      "instabilidade",
    ],
    dificuldade: "Avançado",
    objetivo: "Força",
    caloriasHora: 400,
    imagem: "assets/gifs/triceps/triceps_nordico_ring_dips.gif",
    video: "",
  ),
  ExercicioModel(
    id: "triceps_023",
    nome: "Tríceps Pulley Inverso (Reverse Grip)",
    categoria: "Tríceps",
    descricao:
        "Variação do tríceps pulley com a barra em pegada supinada (palmas para cima). Altera o ângulo de ação do tríceps e enfatiza a cabeça medial do músculo.",
    comoExecutar:
        "Posicione a barra reta na polia alta. Segure a barra com as palmas voltadas para cima (pegada supinada). Com os cotovelos fixos ao lado do corpo, empurre a barra para baixo estendendo os cotovelos. Contraia o tríceps no ponto final e retorne controladamente.",
    cuidados:
        "Mantenha os cotovelos fixos ao lado do corpo. A pegada supinada é diferente da tradicional e pode ser estranha inicialmente. Use cargas menores que na versão convencional.",
    musculos: ["Cabeça medial do tríceps", "Tríceps braquial"],
    equipamentos: ["Polia", "Barra reta"],
    locais: ["Academia"],
    tags: [
      "pulley inverso",
      "supinado",
      "tríceps",
      "cabeça medial",
      "variação",
    ],
    dificuldade: "Intermediário",
    objetivo: "Hipertrofia",
    caloriasHora: 250,
    imagem: "assets/gifs/triceps/triceps_pulley_inverso_reverse_grip.gif",
    video: "",
  ),
  ExercicioModel(
    id: "triceps_024",
    nome: "Tríceps no Cross-Over",
    categoria: "Tríceps",
    descricao:
        "Exercício de isolamento para o tríceps realizado no cross-over com polia acima da cabeça. Permite variações de ângulo e maior liberdade de movimento.",
    comoExecutar:
        "Posicione as polias na altura mais alta do cross-over com alças D. Segure ambas as alças cruzando os braços à frente do corpo. Posicione-se no centro da máquina com um passo à frente para equilíbrio. Estenda os cotovelos empurrando para baixo e para fora. Contraia e retorne.",
    cuidados:
        "Mantenha os cotovelos fixos. Não use o corpo para empurrar. Mantenha o core ativado para estabilidade. A posição dos pés deve garantir equilíbrio durante o exercício.",
    musculos: ["Tríceps braquial", "Cabeça lateral do tríceps"],
    equipamentos: ["Cross-Over", "Polia"],
    locais: ["Academia"],
    tags: ["cross-over", "tríceps", "polia", "isolamento", "variação"],
    dificuldade: "Intermediário",
    objetivo: "Hipertrofia",
    caloriasHora: 255,
    imagem: "assets/gifs/triceps/triceps_no_cross_over.gif",
    video: "",
  ),
  ExercicioModel(
    id: "triceps_025",
    nome: "Extensão de Tríceps com Kettlebell Acima da Cabeça",
    categoria: "Tríceps",
    descricao:
        "Exercício de isolamento para o tríceps com kettlebell sustentado com as duas mãos acima da cabeça. A posição enfatiza a cabeça longa do músculo.",
    comoExecutar:
        "Segure um kettlebell com as duas mãos pelo lado dos pesos, acima da cabeça com os braços estendidos. Mantendo os cotovelos próximos às orelhas e apontando para cima, desça o kettlebell atrás da cabeça flexionando os cotovelos. Estenda de volta à posição inicial.",
    cuidados:
        "Não deixe os cotovelos se abrirem para os lados. Mantenha o core ativado. Realize de forma lenta, especialmente na descida. A alça do kettlebell deve estar segura com firmeza.",
    musculos: ["Cabeça longa do tríceps", "Tríceps braquial"],
    equipamentos: ["Kettlebell"],
    locais: ["Academia", "Casa"],
    tags: [
      "tríceps francês",
      "kettlebell",
      "cabeça longa",
      "isolamento",
      "overhead",
    ],
    dificuldade: "Iniciante",
    objetivo: "Hipertrofia",
    caloriasHora: 245,
    imagem:
        "assets/gifs/triceps/extensao_de_triceps_com_kettlebell_acima_da_cabeca.gif",
    video: "",
  ),
  ExercicioModel(
    id: "triceps_026",
    nome: "Tríceps na Polia com Barra Reta",
    categoria: "Tríceps",
    descricao:
        "Exercício clássico de tríceps na polia com barra reta. Permite trabalho com cargas mais elevadas que a corda e proporciona ativação uniforme dos feixes do tríceps.",
    comoExecutar:
        "Posicione a barra reta na polia alta. Segure com pegada pronada (palmas para baixo) na largura dos ombros. Cotovelos fixos ao lado do corpo. Empurre a barra para baixo até os braços ficarem completamente estendidos. Segure 1 segundo contraindo o tríceps e retorne controladamente.",
    cuidados:
        "Não afaste os cotovelos do corpo. Não use impulso do tronco. Mantenha a postura ereta. A barra reta pode ser mais difícil nos pulsos que a EZ ou a corda.",
    musculos: ["Tríceps braquial", "Ancôneo"],
    equipamentos: ["Polia", "Barra reta"],
    locais: ["Academia"],
    tags: ["pulley barra reta", "tríceps", "polia", "clássico", "isolamento"],
    dificuldade: "Iniciante",
    objetivo: "Hipertrofia",
    caloriasHora: 255,
    imagem: "assets/gifs/triceps/triceps_na_polia_com_barra_reta.gif",
    video: "",
  ),
  ExercicioModel(
    id: "triceps_027",
    nome: "Dips em Banco com Peso",
    categoria: "Tríceps",
    descricao:
        "Versão avançada do mergulho entre bancos com adição de peso sobre as coxas para aumentar a resistência e promover maior hipertrofia do tríceps.",
    comoExecutar:
        "Realize a posição de bench dips com um anilha ou halter sobre as coxas. Desça flexionando os cotovelos até os braços formarem 90 graus e empurre de volta. Mantenha as costas próximas ao banco e os quadris próximos à borda do banco durante a descida.",
    cuidados:
        "Certifique-se de que o peso está bem posicionado e não vai cair. Mantenha as costas encostadas no banco durante a descida. Não desça além de 90 graus. Aumente o peso progressivamente.",
    musculos: ["Tríceps braquial", "Deltóide anterior"],
    equipamentos: ["Banco", "Anilha", "Halter"],
    locais: ["Academia"],
    tags: [
      "bench dips pesado",
      "tríceps",
      "progressão",
      "peso adicional",
      "banco",
    ],
    dificuldade: "Avançado",
    objetivo: "Força",
    caloriasHora: 310,
    imagem: "assets/gifs/triceps/dips_em_banco_com_peso.gif",
    video: "",
  ),
  ExercicioModel(
    id: "triceps_028",
    nome: "Tríceps Testa no Cabo Inclinado",
    categoria: "Tríceps",
    descricao:
        "Variação do skull crusher realizada em banco inclinado com cabos, que mantém tensão constante no tríceps durante toda a amplitude e altera o ângulo de recrutamento.",
    comoExecutar:
        "Deite-se em um banco inclinado posicionado na frente da polia baixa. Segure a barra EZ ou corda conectada à polia com os braços acima do peito. Flexione os cotovelos descendo a carga em direção à testa. Estenda de volta mantendo os cotovelos fixos.",
    cuidados:
        "Ajuste o banco para que fique em ângulo que permita boa tensão no cabo. Mantenha os cotovelos fixos. A tensão constante do cabo é a vantagem deste exercício sobre a versão com barra.",
    musculos: ["Tríceps braquial", "Cabeça longa do tríceps"],
    equipamentos: ["Polia", "Banco inclinado", "Barra EZ"],
    locais: ["Academia"],
    tags: [
      "skull crusher cabo",
      "tríceps testa polia",
      "tensão constante",
      "inclinado",
    ],
    dificuldade: "Avançado",
    objetivo: "Hipertrofia",
    caloriasHora: 265,
    imagem: "assets/gifs/triceps/triceps_testa_no_cabo_inclinado.gif",
    video: "",
  ),
  ExercicioModel(
    id: "triceps_029",
    nome: "Flexão de Braços com Diamante nas Joelhos",
    categoria: "Tríceps",
    descricao:
        "Versão adaptada para iniciantes da flexão diamante, realizada nos joelhos. Permite aprender o movimento com menos carga corporal antes de progredir para a versão completa.",
    comoExecutar:
        "Apoie-se nos joelhos e mãos no chão com as mãos formando um triângulo (diamante). Mantenha o corpo em linha reta dos joelhos à cabeça. Desça flexionando os cotovelos até o peito quase tocar as mãos. Empurre de volta estendendo os cotovelos completamente.",
    cuidados:
        "Mantenha o quadril baixo, em linha com os joelhos e ombros. Não deixe o quadril subir. Mantenha o core ativado. Este é o caminho para progredir para a versão completa.",
    musculos: ["Tríceps braquial", "Deltóide anterior", "Peitoral"],
    equipamentos: ["Peso corporal"],
    locais: ["Casa", "Academia"],
    tags: [
      "diamante joelhos",
      "tríceps",
      "iniciante",
      "casa",
      "sem equipamento",
      "progressão",
    ],
    dificuldade: "Iniciante",
    objetivo: "Força",
    caloriasHora: 250,
    imagem: "assets/gifs/triceps/flexao_de_bracos_com_diamante_nas_joelhos.gif",
    video: "",
  ),
  ExercicioModel(
    id: "triceps_030",
    nome: "Tríceps JM Press",
    categoria: "Tríceps",
    descricao:
        "Exercício híbrido desenvolvido por JM Blakley que combina elementos do supino fechado e do skull crusher. Permite trabalhar com cargas mais elevadas que o skull crusher tradicional.",
    comoExecutar:
        "Deite-se no banco com a barra segura em pegada fechada acima do peito. Desça a barra dobrando os cotovelos, mas trazendo-os em direção ao rosto ao mesmo tempo que os cotovelos se inclinam para frente. A barra deve chegar próximo ao pescoço com os cotovelos inclinados. Empurre de volta.",
    cuidados:
        "Exige prática para dominar o padrão de movimento. Realize com cargas moderadas inicialmente. Use um parceiro de treino para segurança. Este é um exercício avançado de powerbuilding.",
    musculos: ["Tríceps braquial", "Cabeça medial do tríceps", "Peitoral"],
    equipamentos: ["Barra", "Banco"],
    locais: ["Academia"],
    tags: ["JM press", "tríceps avançado", "powerbuilding", "barra", "híbrido"],
    dificuldade: "Avançado",
    objetivo: "Força",
    caloriasHora: 340,
    imagem: "assets/gifs/triceps/triceps_jm_press.gif",
    video: "",
  ),
];
