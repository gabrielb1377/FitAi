import '../../models/exercicio_model.dart';

final List<ExercicioModel> exerciciosAntebraco = [
  ExercicioModel(
    id: "antebr_001",
    nome: "Rosca de Punho com Halteres (Flexão de Punho)",
    categoria: "Antebraço",
    descricao:
        "Exercício básico para os flexores do punho e antebraço, fortalecendo o grip e prevenindo lesões nos tendões dos flexores.",
    comoExecutar:
        "Sente-se em um banco e apoie os antebraços sobre as coxas com os pulsos além dos joelhos. Segure os halteres com pegada supinada (palma para cima). Flexione o punho elevando os halteres o máximo possível. Retorne de forma controlada.",
    cuidados:
        "Use carga leve. Realize o movimento apenas com o punho, sem mover o antebraço. Não faça movimentos bruscos.",
    musculos: [
      "Flexores do Punho",
      "Flexor Radial do Carpo",
      "Flexor Ulnar do Carpo",
    ],
    musculosSecundarios: ["Palmar Longo"],
    equipamentos: ["Halteres"],
    locais: ["Academia", "Casa"],
    tags: ["punho", "antebraço", "flexores", "grip", "halteres"],
    dificuldade: "Iniciante",
    objetivo: "Força e Hipertrofia",
    caloriasHora: 180,
    imagem:
        "assets/gifs/antebraco/rosca_de_punho_com_halteres_flexao_de_punho.gif",
    video: "",
  ),
  ExercicioModel(
    id: "antebr_002",
    nome: "Rosca de Punho Reversa (Extensão de Punho)",
    categoria: "Antebraço",
    descricao:
        "Exercício para os extensores do punho e antebraço, prevenindo a epicondilite lateral (cotovelo de tenista) e equilibrando o desenvolvimento do antebraço.",
    comoExecutar:
        "Sente-se em um banco e apoie os antebraços sobre as coxas com os pulsos além dos joelhos. Segure os halteres com pegada pronada (palma para baixo). Estenda o punho elevando o dorso da mão o máximo possível. Retorne de forma controlada.",
    cuidados:
        "Use carga ainda menor que na flexão de punho. Extensores são mais fracos que flexores. Não force além da amplitude natural.",
    musculos: [
      "Extensores do Punho",
      "Extensor Radial Longo do Carpo",
      "Extensor Ulnar do Carpo",
    ],
    musculosSecundarios: ["Braquiorradial"],
    equipamentos: ["Halteres"],
    locais: ["Academia", "Casa"],
    tags: [
      "extensão punho",
      "antebraço",
      "extensores",
      "cotovelo tenista",
      "prevenção",
    ],
    dificuldade: "Iniciante",
    objetivo: "Força e Prevenção",
    caloriasHora: 170,
    imagem:
        "assets/gifs/antebraco/rosca_de_punho_reversa_extensao_de_punho.gif",
    video: "",
  ),
  ExercicioModel(
    id: "antebr_003",
    nome: "Farmer's Walk (Caminhada do Fazendeiro)",
    categoria: "Antebraço",
    descricao:
        "Exercício funcional que desafia o grip de forma intensa ao caminhar carregando pesos pesados, desenvolvendo o antebraço, trapézio e core simultaneamente.",
    comoExecutar:
        "Segure um halter ou kettlebell pesado em cada mão com pegada neutra. Mantenha a postura ereta com ombros para trás. Caminhe de forma controlada por uma distância determinada ou por tempo. Retorne ao ponto inicial.",
    cuidados:
        "Mantenha a coluna ereta durante toda a caminhada. Não deixe os ombros protraírem. Comece com pesos moderados e aumente progressivamente.",
    musculos: ["Flexores do Antebraço", "Intrínsecos da Mão"],
    musculosSecundarios: ["Trapézio", "Core", "Quadríceps", "Glúteos"],
    equipamentos: ["Halteres", "Kettlebell"],
    locais: ["Academia", "Casa"],
    tags: [
      "farmer walk",
      "grip",
      "funcional",
      "força",
      "antebraço",
      "carga carregada",
    ],
    dificuldade: "Intermediário",
    objetivo: "Força Funcional",
    caloriasHora: 400,
    imagem: "assets/gifs/antebraco/farmer_s_walk_caminhada_do_fazendeiro.gif",
    video: "",
  ),
  ExercicioModel(
    id: "antebr_004",
    nome: "Suspensão na Barra (Dead Hang)",
    categoria: "Antebraço",
    descricao:
        "Exercício isométrico de suspensão na barra que desenvolve o grip, descomprime a coluna e fortalece os flexores do antebraço e manguito rotador.",
    comoExecutar:
        "Segure a barra fixa com pegada pronada na largura dos ombros. Deixe o corpo pendurado completamente relaxado, com os braços estendidos. Mantenha a posição pelo máximo de tempo possível respirando normalmente.",
    cuidados:
        "Mantenha os ombros ativos (leve depressão e retração) para proteger a articulação. Comece com séries curtas e progrida o tempo gradualmente.",
    musculos: ["Flexores do Antebraço", "Intrínsecos da Mão"],
    musculosSecundarios: ["Latíssimo do Dorso", "Romboides", "Bíceps"],
    equipamentos: ["Barra Fixa"],
    locais: ["Academia", "Casa"],
    tags: ["dead hang", "barra", "grip", "suspensão", "antebraço", "coluna"],
    dificuldade: "Iniciante",
    objetivo: "Força de Preensão",
    caloriasHora: 150,
    imagem: "assets/gifs/antebraco/suspensao_na_barra_dead_hang.gif",
    video: "",
  ),
  ExercicioModel(
    id: "antebr_005",
    nome: "Rosca Martelo com Halteres",
    categoria: "Antebraço",
    descricao:
        "Variação da rosca com pegada neutra que desenvolve o braquiorradial (músculo do antebraço) e o braquial, além de trabalhar o bíceps.",
    comoExecutar:
        "Fique em pé com halteres nas mãos em pegada neutra (polegares para cima). Com o cotovelo próximo ao corpo, flexione o antebraço elevando o halter em direção ao ombro. Desça de forma controlada. Pode ser realizado de forma alternada ou simultânea.",
    cuidados:
        "Não balance o tronco para ganhar impulso. Mantenha os cotovelos fixos ao lado do corpo. Controle a fase excêntrica.",
    musculos: ["Braquiorradial", "Braquial"],
    musculosSecundarios: ["Bíceps Braquial", "Flexores do Antebraço"],
    equipamentos: ["Halteres"],
    locais: ["Academia", "Casa"],
    tags: ["rosca martelo", "braquiorradial", "antebraço", "bíceps", "neutro"],
    dificuldade: "Iniciante",
    objetivo: "Hipertrofia",
    caloriasHora: 250,
    imagem: "assets/gifs/antebraco/rosca_martelo_com_halteres.gif",
    video: "",
  ),
  ExercicioModel(
    id: "antebr_006",
    nome: "Enrolamento de Pulso com Barra",
    categoria: "Antebraço",
    descricao:
        "Exercício com barra específica para enrolamento de punho que desenvolve os flexores do antebraço e o grip de forma intensa e progressiva.",
    comoExecutar:
        "Segure uma barra ou bastão com uma corda atada ao centro e um peso pendurado na extremidade. Estenda os braços à frente. Enrole a corda girando o bastão com os punhos até o peso chegar ao topo. Desça de forma controlada.",
    cuidados:
        "Use pouco peso no início. O movimento deve ser controlado tanto na subida quanto na descida. Mantenha os braços estendidos durante todo o exercício.",
    musculos: ["Flexores do Punho", "Extensores do Punho"],
    musculosSecundarios: ["Braquiorradial", "Deltóide Anterior"],
    equipamentos: ["Barra para Enrolamento", "Corda", "Peso"],
    locais: ["Academia"],
    tags: [
      "enrolamento punho",
      "wrist roller",
      "antebraço",
      "grip",
      "flexores",
    ],
    dificuldade: "Intermediário",
    objetivo: "Força e Resistência",
    caloriasHora: 200,
    imagem: "assets/gifs/antebraco/enrolamento_de_pulso_com_barra.gif",
    video: "",
  ),
  ExercicioModel(
    id: "antebr_007",
    nome: "Pronação e Supinação com Halter",
    categoria: "Antebraço",
    descricao:
        "Exercício para os pronadores e supinadores do antebraço, músculos responsáveis pela rotação do punho e fundamentais para esportes de raquete e arremesso.",
    comoExecutar:
        "Sente-se e apoie o antebraço na coxa com o punho além do joelho. Segure um halter na extremidade em posição vertical. Gire o punho para dentro (pronação) e depois para fora (supinação), controlando o peso em ambas as direções.",
    cuidados:
        "Use halter leve. Movimento lento e controlado. Estabilize o antebraço sobre a coxa durante todo o exercício.",
    musculos: ["Pronador Redondo", "Pronador Quadrado", "Supinador"],
    musculosSecundarios: ["Braquiorradial"],
    equipamentos: ["Halter"],
    locais: ["Academia", "Casa"],
    tags: ["pronação", "supinação", "antebraço", "rotação", "raquete"],
    dificuldade: "Iniciante",
    objetivo: "Força e Prevenção",
    caloriasHora: 160,
    imagem: "assets/gifs/antebraco/pronacao_e_supinacao_com_halter.gif",
    video: "",
  ),
  ExercicioModel(
    id: "antebr_008",
    nome: "Pegada de Pinça com Anilha",
    categoria: "Antebraço",
    descricao:
        "Exercício para desenvolver o grip de pinça utilizando anilhas seguradas pelos dedos, fortalecendo os intrínsecos da mão e os flexores dos dedos.",
    comoExecutar:
        "Segure uma anilha pelo bordo com os dedos indicador, médio, anelar e mínimo por baixo e o polegar por cima (pegada de pinça). Mantenha por um tempo determinado ou caminhe com ela. Troque de mão.",
    cuidados:
        "Comece com anilhas leves. Use superfície segura abaixo da anilha caso ela escorregue. Progrida o peso gradualmente.",
    musculos: ["Flexores dos Dedos", "Músculos Intrínsecos da Mão"],
    musculosSecundarios: ["Thenar", "Hipotenar"],
    equipamentos: ["Anilha"],
    locais: ["Academia"],
    tags: ["pinça", "grip", "dedos", "antebraço", "preensão"],
    dificuldade: "Intermediário",
    objetivo: "Força de Preensão",
    caloriasHora: 150,
    imagem: "assets/gifs/antebraco/pegada_de_pinca_com_anilha.gif",
    video: "",
  ),
  ExercicioModel(
    id: "antebr_009",
    nome: "Extensão de Punho com Barra no Cabo",
    categoria: "Antebraço",
    descricao:
        "Variação da extensão de punho no cabo que mantém tensão constante durante todo o movimento, ideal para trabalho de isolamento dos extensores do antebraço.",
    comoExecutar:
        "Posicione a polia baixa. Segure a barra com pegada pronada. Apoie os antebraços em um banco ou sobre as coxas com os pulsos além dos joelhos. Estenda o punho elevando a barra e retorne de forma controlada.",
    cuidados:
        "Use carga leve. Mantenha os antebraços fixos. Não permita que os cotovelos se movam durante o exercício.",
    musculos: ["Extensores do Punho"],
    musculosSecundarios: ["Braquiorradial"],
    equipamentos: ["Cabo", "Polia Baixa", "Barra"],
    locais: ["Academia"],
    tags: ["extensão punho", "cabo", "antebraço", "extensores"],
    dificuldade: "Iniciante",
    objetivo: "Força e Prevenção",
    caloriasHora: 170,
    imagem: "assets/gifs/antebraco/extensao_de_punho_com_barra_no_cabo.gif",
    video: "",
  ),
  ExercicioModel(
    id: "antebr_010",
    nome: "Flexão de Punho com Barra",
    categoria: "Antebraço",
    descricao:
        "Versão com barra da flexão de punho que permite trabalhar ambos os lados simultaneamente com carga progressiva para os flexores do antebraço.",
    comoExecutar:
        "Sente-se em um banco e apoie os antebraços sobre as coxas com os pulsos além dos joelhos. Segure a barra com pegada supinada. Flexione ambos os punhos simultaneamente elevando a barra. Desça lentamente.",
    cuidados:
        "Não use carga excessiva. Controle a fase negativa. Deixe a barra rolar até as pontas dos dedos na descida para aumentar a amplitude.",
    musculos: ["Flexores do Punho", "Flexores dos Dedos"],
    musculosSecundarios: ["Palmar Longo"],
    equipamentos: ["Barra"],
    locais: ["Academia"],
    tags: ["flexão punho barra", "antebraço", "flexores", "grip"],
    dificuldade: "Iniciante",
    objetivo: "Força e Hipertrofia",
    caloriasHora: 185,
    imagem: "assets/gifs/antebraco/flexao_de_punho_com_barra.gif",
    video: "",
  ),
  ExercicioModel(
    id: "antebr_011",
    nome: "Squeeze de Bola ou Esponja",
    categoria: "Antebraço",
    descricao:
        "Exercício de reabilitação e fortalecimento do grip utilizando bola de borracha ou esponja, ideal para iniciantes e praticantes de esportes de raquete.",
    comoExecutar:
        "Segure uma bola de borracha firme ou esponja na palma da mão. Aperte-a com máxima força utilizando todos os dedos. Mantenha a pressão por 3 a 5 segundos e relaxe. Repita pelo número de repetições desejado e troque de mão.",
    cuidados:
        "Não force se houver dor articular nos dedos. Ideal para recuperação de lesões ou iniciantes. Varie o tempo de contração.",
    musculos: ["Flexores dos Dedos", "Músculos Intrínsecos da Mão"],
    musculosSecundarios: ["Thenar", "Hipotenar"],
    equipamentos: ["Bola de Borracha"],
    locais: ["Casa", "Academia"],
    tags: ["squeeze", "grip", "dedos", "reabilitação", "preensão"],
    dificuldade: "Iniciante",
    objetivo: "Força de Preensão",
    caloriasHora: 100,
    imagem: "assets/gifs/antebraco/squeeze_de_bola_ou_esponja.gif",
    video: "",
  ),
  ExercicioModel(
    id: "antebr_012",
    nome: "Rosca Inversa com Barra",
    categoria: "Antebraço",
    descricao:
        "Variação da rosca bíceps com pegada pronada que trabalha intensamente o braquiorradial e os extensores do antebraço, além do bíceps.",
    comoExecutar:
        "Fique em pé com uma barra em pegada pronada (palmas para baixo), mãos na largura dos ombros. Mantenha os cotovelos fixos ao lado do corpo. Flexione os cotovelos elevando a barra. Desça de forma controlada.",
    cuidados:
        "A tendência de abrir os cotovelos é maior com essa pegada — mantenha-os fixos. Use carga menor que na rosca convencional. Não jogue o tronco para trás.",
    musculos: ["Braquiorradial", "Extensores do Punho"],
    musculosSecundarios: ["Bíceps Braquial", "Braquial"],
    equipamentos: ["Barra"],
    locais: ["Academia"],
    tags: ["rosca inversa", "braquiorradial", "antebraço", "bíceps", "pronada"],
    dificuldade: "Intermediário",
    objetivo: "Hipertrofia",
    caloriasHora: 260,
    imagem: "assets/gifs/antebraco/rosca_inversa_com_barra.gif",
    video: "",
  ),
  ExercicioModel(
    id: "antebr_013",
    nome: "Suspensão em Pegada de Toalha",
    categoria: "Antebraço",
    descricao:
        "Variação do dead hang com toalha na barra que aumenta drasticamente a demanda sobre os flexores dos dedos e o grip, um desafio para praticantes avançados.",
    comoExecutar:
        "Enrole uma toalha grossa ao redor de uma barra fixa. Segure as duas pontas da toalha, uma em cada mão. Pendure-se e mantenha a posição pelo máximo de tempo possível.",
    cuidados:
        "Exercício avançado. Certifique-se de que a toalha é resistente e está bem presa à barra. Tenha um colchonete abaixo por segurança.",
    musculos: ["Flexores dos Dedos", "Intrínsecos da Mão"],
    musculosSecundarios: ["Flexores do Punho", "Latíssimo do Dorso", "Bíceps"],
    equipamentos: ["Barra Fixa", "Toalha"],
    locais: ["Academia", "Casa"],
    tags: ["toalha", "grip", "avançado", "suspensão", "dedos"],
    dificuldade: "Avançado",
    objetivo: "Força de Preensão",
    caloriasHora: 200,
    imagem: "assets/gifs/antebraco/suspensao_em_pegada_de_toalha.gif",
    video: "",
  ),
  ExercicioModel(
    id: "antebr_014",
    nome: "Flexão de Punho no Cabo (Unilateral)",
    categoria: "Antebraço",
    descricao:
        "Exercício unilateral de flexão de punho no cabo que permite trabalhar cada antebraço individualmente, corrigindo desequilíbrios.",
    comoExecutar:
        "Posicione a polia baixa. Sente-se lateralmente e apoie o antebraço sobre a coxa com o punho além do joelho. Segure o cabo com pegada supinada. Flexione o punho e retorne de forma controlada. Complete as repetições e troque de lado.",
    cuidados:
        "Mantenha o antebraço imóvel sobre a coxa. Use carga leve. Concentre-se na contração e no alongamento do músculo.",
    musculos: ["Flexores do Punho"],
    musculosSecundarios: ["Palmar Longo", "Flexores dos Dedos"],
    equipamentos: ["Cabo", "Polia Baixa"],
    locais: ["Academia"],
    tags: ["flexão punho cabo", "unilateral", "antebraço", "isolamento"],
    dificuldade: "Iniciante",
    objetivo: "Força",
    caloriasHora: 160,
    imagem: "assets/gifs/antebraco/flexao_de_punho_no_cabo_unilateral.gif",
    video: "",
  ),
  ExercicioModel(
    id: "antebr_015",
    nome: "Kettlebell Swing",
    categoria: "Antebraço",
    descricao:
        "Exercício funcional com kettlebell que desafia o grip e os flexores do antebraço dinamicamente enquanto trabalha a cadeia posterior e o core.",
    comoExecutar:
        "Fique em pé com os pés afastados além da largura dos ombros. Segure o kettlebell com ambas as mãos. Incline o tronco para frente com a coluna reta e balance o kettlebell para trás entre as pernas. Empurre os quadris para frente projetando o kettlebell até a altura dos ombros. Repita o movimento com ritmo.",
    cuidados:
        "O movimento vem dos quadris, não da coluna. Mantenha o core contraído. Não arredonde a lombar. Aprenda a técnica com peso leve antes de progredir.",
    musculos: ["Flexores do Antebraço", "Flexores dos Dedos"],
    musculosSecundarios: ["Glúteos", "Isquiotibiais", "Core", "Deltóide"],
    equipamentos: ["Kettlebell"],
    locais: ["Academia", "Casa"],
    tags: [
      "kettlebell swing",
      "grip",
      "funcional",
      "cadeia posterior",
      "antebraço",
    ],
    dificuldade: "Intermediário",
    objetivo: "Força Funcional e Resistência",
    caloriasHora: 600,
    imagem: "assets/gifs/antebraco/kettlebell_swing.gif",
    video: "",
  ),
  ExercicioModel(
    id: "antebr_016",
    nome: "Rosca Zottman",
    categoria: "Antebraço",
    descricao:
        "Exercício que combina flexão supinada na subida e pronada na descida, trabalhando tanto os flexores quanto os extensores do antebraço em uma única repetição.",
    comoExecutar:
        "Fique em pé com halteres em pegada supinada. Flexione os cotovelos elevando os halteres (como rosca bíceps). No topo, gire os punhos para a posição pronada. Desça de forma lenta e controlada com a pegada pronada. Gire de volta para supinada para a próxima repetição.",
    cuidados:
        "Realize a troca de pegada de forma suave no topo do movimento. Use carga moderada. A descida em pronação é muito intensa — controle bem.",
    musculos: ["Bíceps Braquial", "Braquiorradial", "Extensores do Punho"],
    musculosSecundarios: ["Braquial", "Flexores do Antebraço"],
    equipamentos: ["Halteres"],
    locais: ["Academia", "Casa"],
    tags: [
      "zottman",
      "antebraço",
      "bíceps",
      "pronação",
      "supinação",
      "completo",
    ],
    dificuldade: "Intermediário",
    objetivo: "Hipertrofia",
    caloriasHora: 270,
    imagem: "assets/gifs/antebraco/rosca_zottman.gif",
    video: "",
  ),
  ExercicioModel(
    id: "antebr_017",
    nome: "Exercício de Dedo com Elástico",
    categoria: "Antebraço",
    descricao:
        "Exercício com elástico para fortalecer os extensores dos dedos, músculos frequentemente negligenciados e importantes para o equilíbrio muscular da mão.",
    comoExecutar:
        "Coloque um elástico ao redor de todos os dedos de uma mão (incluindo o polegar). Abra os dedos contra a resistência do elástico o máximo possível. Feche lentamente. Repita pelo número de repetições desejado e troque de mão.",
    cuidados:
        "Use elástico de resistência adequada. Exercício preventivo importante para tendinites e lesões dos extensores. Pode ser feito em qualquer lugar.",
    musculos: ["Extensores dos Dedos", "Músculos Intrínsecos da Mão"],
    musculosSecundarios: ["Thenar", "Hipotenar"],
    equipamentos: ["Elástico de Resistência"],
    locais: ["Casa", "Academia"],
    tags: ["dedos", "elástico", "extensores", "prevenção", "mão"],
    dificuldade: "Iniciante",
    objetivo: "Prevenção e Equilíbrio Muscular",
    caloriasHora: 80,
    imagem: "assets/gifs/antebraco/exercicio_de_dedo_com_elastico.gif",
    video: "",
  ),
  ExercicioModel(
    id: "antebr_018",
    nome: "Carries com Kettlebell (Suitcase Carry)",
    categoria: "Antebraço",
    descricao:
        "Variação do farmer's walk com carga unilateral que desafia o grip, o core anti-lateral e o trapézio de forma funcional.",
    comoExecutar:
        "Segure um kettlebell pesado em uma das mãos ao lado do corpo. Mantenha o tronco ereto e o ombro do lado carregado levemente deprimido. Caminhe por uma distância determinada. Troque de mão e repita.",
    cuidados:
        "Não incline o tronco para o lado carregado. Mantenha o core firme. O ombro do lado com carga não deve elevar.",
    musculos: ["Flexores do Antebraço", "Intrínsecos da Mão"],
    musculosSecundarios: ["Quadrado Lombar", "Oblíquos", "Trapézio"],
    equipamentos: ["Kettlebell"],
    locais: ["Academia", "Casa"],
    tags: ["suitcase carry", "unilateral", "grip", "core", "funcional"],
    dificuldade: "Intermediário",
    objetivo: "Força Funcional",
    caloriasHora: 380,
    imagem: "assets/gifs/antebraco/carries_com_kettlebell_suitcase_carry.gif",
    video: "",
  ),
  ExercicioModel(
    id: "antebr_019",
    nome: "Rosca de Punho Lateral (Desvio Radial e Ulnar)",
    categoria: "Antebraço",
    descricao:
        "Exercício para os músculos que controlam o desvio lateral do punho, trabalhando o extensor radial, flexor ulnar e outros músculos menores do antebraço.",
    comoExecutar:
        "Sente-se e apoie o antebraço sobre a coxa com o polegar apontando para cima. Segure um halter pela extremidade. Mova o punho para cima (desvio radial) e para baixo (desvio ulnar) de forma controlada. Complete as repetições e troque de lado.",
    cuidados:
        "Use halter muito leve. Movimento pequeno e controlado. Fundamental para a saúde dos tendões do punho.",
    musculos: [
      "Extensor Radial do Carpo",
      "Flexor Ulnar do Carpo",
      "Flexor Radial do Carpo",
    ],
    musculosSecundarios: ["Braquiorradial"],
    equipamentos: ["Halter"],
    locais: ["Academia", "Casa"],
    tags: ["desvio punho", "radial", "ulnar", "antebraço", "punho"],
    dificuldade: "Iniciante",
    objetivo: "Prevenção e Força",
    caloriasHora: 140,
    imagem:
        "assets/gifs/antebraco/rosca_de_punho_lateral_desvio_radial_e_ulnar.gif",
    video: "",
  ),
  ExercicioModel(
    id: "antebr_020",
    nome: "Barra de Dedos (Finger Board)",
    categoria: "Antebraço",
    descricao:
        "Exercício de suspensão em presas específicas para escalada, desenvolvendo a força dos flexores dos dedos e o grip para praticantes de boulder e escalada.",
    comoExecutar:
        "Segure uma presa (full crimp, half crimp ou sloper) na fingerboard. Pendure-se com os braços quase estendidos. Mantenha a posição pelo tempo determinado. Progrida adicionando peso ou reduzindo o tamanho da presa.",
    cuidados:
        "Aqueça bem os dedos antes. Inicie com presas grandes. Não force a extensão completa dos cotovelos. Alto risco de lesão nas polias dos dedos sem progressão adequada.",
    musculos: ["Flexores dos Dedos", "Lumbricais", "Intrínsecos da Mão"],
    musculosSecundarios: ["Flexores do Punho", "Bíceps"],
    equipamentos: ["Fingerboard", "Barra de Dedos"],
    locais: ["Academia", "Casa"],
    tags: ["fingerboard", "escalada", "dedos", "grip avançado", "boulder"],
    dificuldade: "Avançado",
    objetivo: "Força de Preensão",
    caloriasHora: 200,
    imagem: "assets/gifs/antebraco/barra_de_dedos_finger_board.gif",
    video: "",
  ),
  ExercicioModel(
    id: "antebr_021",
    nome: "Rotação de Barra (Wrist Supination/Pronation com Barra)",
    categoria: "Antebraço",
    descricao:
        "Exercício com barra longa ou bastão que trabalha pronadores e supinadores com maior alavanca, ideal para atletas de arremesso e raquete.",
    comoExecutar:
        "Segure uma barra leve ou bastão com uma mão, posicionada próximo à extremidade para aumentar a alavanca. Apoie o antebraço sobre uma mesa ou coxa. Gire o bastão de supinação para pronação e vice-versa de forma lenta e controlada.",
    cuidados:
        "A alavanca amplifica a sobrecarga — use bastão muito leve. Movimento deve ser suave e sem dor. Ótimo para reabilitação e prevenção de lesões no cotovelo.",
    musculos: ["Pronador Redondo", "Supinador", "Pronador Quadrado"],
    musculosSecundarios: ["Braquiorradial"],
    equipamentos: ["Barra Leve", "Bastão"],
    locais: ["Academia", "Casa"],
    tags: [
      "rotação",
      "supinação",
      "pronação",
      "barra",
      "cotovelo",
      "reabilitação",
    ],
    dificuldade: "Iniciante",
    objetivo: "Força e Reabilitação",
    caloriasHora: 130,
    imagem:
        "assets/gifs/antebraco/rotacao_de_barra_wrist_supinationpronation_com_barra.gif",
    video: "",
  ),
  ExercicioModel(
    id: "antebr_022",
    nome: "Levantamento Terra Isométrico (Towel Bar Pull)",
    categoria: "Antebraço",
    descricao:
        "Exercício isométrico que simula a fase de puxada do levantamento terra usando toalha ou corda, desenvolvendo o grip de força estática.",
    comoExecutar:
        "Amarre uma toalha resistente em um objeto fixo no chão. Segure as extremidades da toalha com pegada firme. Posicione-se como no início de um levantamento terra e puxe a toalha com força máxima de forma estática por 5 a 10 segundos.",
    cuidados:
        "Certifique-se de que o objeto está firmemente preso. Mantenha a postura do levantamento terra. Não puxe de forma brusca.",
    musculos: ["Flexores dos Dedos", "Flexores do Punho"],
    musculosSecundarios: ["Latíssimo do Dorso", "Trapézio", "Glúteos"],
    equipamentos: ["Toalha"],
    locais: ["Casa", "Academia"],
    tags: ["isométrico", "grip", "toalha", "força", "antebraço"],
    dificuldade: "Intermediário",
    objetivo: "Força Estática",
    caloriasHora: 180,
    imagem:
        "assets/gifs/antebraco/levantamento_terra_isometrico_towel_bar_pull.gif",
    video: "",
  ),
  ExercicioModel(
    id: "antebr_023",
    nome: "Remada com Pegada de Gancho (Hook Grip Row)",
    categoria: "Antebraço",
    descricao:
        "Exercício de remada com pegada de gancho (polegar por baixo dos outros dedos) que sobrecarrega o antebraço de forma diferente do grip convencional.",
    comoExecutar:
        "Configure a remada baixa no cabo. Utilize pegada de gancho: coloque o polegar ao redor da barra e feche os outros dedos sobre o polegar. Realize a remada normalmente puxando até o abdômen. Mantenha o grip firme durante todo o movimento.",
    cuidados:
        "A pegada de gancho pode ser desconfortável no início — adapte-se gradualmente. Mais comum na halterofilismo. Mantenha sempre a técnica de remada correta.",
    musculos: ["Flexores dos Dedos", "Flexores do Punho"],
    musculosSecundarios: ["Latíssimo do Dorso", "Romboides", "Bíceps"],
    equipamentos: ["Cabo", "Barra"],
    locais: ["Academia"],
    tags: ["hook grip", "remada", "antebraço", "pegada", "halterofilismo"],
    dificuldade: "Intermediário",
    objetivo: "Força",
    caloriasHora: 300,
    imagem:
        "assets/gifs/antebraco/remada_com_pegada_de_gancho_hook_grip_row.gif",
    video: "",
  ),
  ExercicioModel(
    id: "antebr_024",
    nome: "Rolo de Areia (Sand Bucket Training)",
    categoria: "Antebraço",
    descricao:
        "Treinamento funcional com balde de areia ou equivalente, onde os dedos são mergulhados e abertos contra a resistência, fortalecendo extensores e intrínsecos da mão.",
    comoExecutar:
        "Preencha um balde com areia. Mergulhe os dedos na areia com a mão fechada. Abra os dedos contra a resistência da areia. Feche novamente. Repita pelo número de repetições desejado.",
    cuidados:
        "Ótimo para reabilitação e prevenção. Areia úmida oferece mais resistência. Limpe bem as mãos após o exercício.",
    musculos: ["Extensores dos Dedos", "Músculos Intrínsecos da Mão"],
    musculosSecundarios: ["Thenar", "Hipotenar"],
    equipamentos: ["Balde de Areia"],
    locais: ["Casa", "Academia"],
    tags: ["areia", "dedos", "extensores", "reabilitação", "mão"],
    dificuldade: "Iniciante",
    objetivo: "Reabilitação e Prevenção",
    caloriasHora: 90,
    imagem: "assets/gifs/antebraco/rolo_de_areia_sand_bucket_training.gif",
    video: "",
  ),
  ExercicioModel(
    id: "antebr_025",
    nome: "Levantamento de Placa pelo Bordo (Plate Pinch)",
    categoria: "Antebraço",
    descricao:
        "Exercício de força de pinça com anilhas pelo bordo liso, altamente específico para o desenvolvimento do grip de pinça e dos flexores dos dedos.",
    comoExecutar:
        "Segure duas anilhas juntas pelo lado liso (bordo) usando apenas os dedos e o polegar em forma de pinça. Mantenha as anilhas elevadas por um tempo determinado. Pode também caminhar segurando as anilhas.",
    cuidados:
        "Use anilhas de mesmo peso. Tenha cuidado para que as anilhas não escorreguem — use superfície segura abaixo. Comece com anilhas leves.",
    musculos: ["Flexores dos Dedos", "Thenar"],
    musculosSecundarios: ["Intrínsecos da Mão", "Flexores do Punho"],
    equipamentos: ["Anilhas"],
    locais: ["Academia"],
    tags: ["plate pinch", "pinça", "grip", "anilha", "dedos", "avançado"],
    dificuldade: "Avançado",
    objetivo: "Força de Preensão",
    caloriasHora: 170,
    imagem:
        "assets/gifs/antebraco/levantamento_de_placa_pelo_bordo_plate_pinch.gif",
    video: "",
  ),
  ExercicioModel(
    id: "antebr_026",
    nome: "Rosca Bíceps com Corda no Cabo",
    categoria: "Antebraço",
    descricao:
        "Variação da rosca no cabo com corda que aumenta a exigência sobre o grip e o braquiorradial pela instabilidade da corda durante o movimento.",
    comoExecutar:
        "Acople uma corda na polia baixa. Segure as extremidades da corda com pegada neutra. Realize a flexão de cotovelo elevando as mãos em direção aos ombros. Na parte superior, separe as pontas da corda para fora maximizando a contração. Desça de forma controlada.",
    cuidados:
        "Mantenha os cotovelos fixos ao lado do corpo. Não use impulso. O grip na corda exige mais controle do que na barra.",
    musculos: ["Braquiorradial", "Bíceps Braquial"],
    musculosSecundarios: ["Flexores do Antebraço", "Braquial"],
    equipamentos: ["Cabo", "Corda"],
    locais: ["Academia"],
    tags: ["rosca corda", "cabo", "braquiorradial", "bíceps", "antebraço"],
    dificuldade: "Iniciante",
    objetivo: "Hipertrofia",
    caloriasHora: 250,
    imagem: "assets/gifs/antebraco/rosca_biceps_com_corda_no_cabo.gif",
    video: "",
  ),
  ExercicioModel(
    id: "antebr_027",
    nome: "Flexão de Punho com Corpo (Inclinado na Parede)",
    categoria: "Antebraço",
    descricao:
        "Exercício de peso corporal para os flexores do punho e antebraço inclinando o corpo contra a parede com o dorso das mãos apoiado.",
    comoExecutar:
        "Incline o corpo contra a parede apoiando o dorso das mãos (dedos apontando para baixo). Transfira gradualmente mais peso corporal sobre os pulsos em extensão. Mantenha por segundos ou realize leves flexões dos punhos nessa posição.",
    cuidados:
        "Exercício desconfortável nos pulsos — comece com pouco peso. Progrida muito gradualmente. Não recomendado para quem tem histórico de lesão nos pulsos.",
    musculos: ["Flexores do Punho", "Flexores dos Dedos"],
    musculosSecundarios: ["Músculos Intrínsecos da Mão"],
    equipamentos: const ['Peso corporal'],
    locais: ["Casa", "Academia"],
    tags: ["punho", "parede", "peso corporal", "flexores", "progressão"],
    dificuldade: "Intermediário",
    objetivo: "Força e Mobilidade",
    caloriasHora: 140,
    imagem:
        "assets/gifs/antebraco/flexao_de_punho_com_corpo_inclinado_na_parede.gif",
    video: "",
  ),
  ExercicioModel(
    id: "antebr_028",
    nome: "Rolling Thunder (Cabo Rotativo)",
    categoria: "Antebraço",
    descricao:
        "Exercício com acessório de cabo rotativo que exige grip de rotação, simulando o movimento de abertura de maçaneta e desenvolvendo o grip de forma não convencional.",
    comoExecutar:
        "Acople um cabo rotativo (rolling thunder) a uma polia. Segure o cabo e realize o rosca simples ou apenas sustente o peso contra a gravidade. O cabo girará exigindo constante ajuste do grip para não soltar.",
    cuidados:
        "Acessório específico — disponível em academias de powerlifting. Comece com pouco peso. A rotação do cabo exige muito dos flexores dos dedos.",
    musculos: ["Flexores dos Dedos", "Pronadores"],
    musculosSecundarios: ["Flexores do Punho", "Bíceps"],
    equipamentos: ["Rolling Thunder", "Cabo"],
    locais: ["Academia"],
    tags: [
      "rolling thunder",
      "grip rotativo",
      "avançado",
      "powerlifting",
      "dedos",
    ],
    dificuldade: "Avançado",
    objetivo: "Força de Preensão",
    caloriasHora: 220,
    imagem: "assets/gifs/antebraco/rolling_thunder_cabo_rotativo.gif",
    video: "",
  ),
  ExercicioModel(
    id: "antebr_029",
    nome: "Isometria de Preensão com Halter",
    categoria: "Antebraço",
    descricao:
        "Exercício isométrico onde o praticante mantém um halter comprimido entre os dedos em diferentes posições, desenvolvendo força estática de preensão.",
    comoExecutar:
        "Segure um halter pela extremidade dos anéis utilizando apenas os dedos indicador, médio, anelar e mínimo. Mantenha a posição pelo maior tempo possível. Pode também comprimir o halter entre as palmas das mãos. Troque de posição e repita.",
    cuidados:
        "Use carga moderada. Tenha cuidado para o halter não cair. Coloque um tapete abaixo por segurança.",
    musculos: ["Flexores dos Dedos", "Intrínsecos da Mão"],
    musculosSecundarios: ["Flexores do Punho"],
    equipamentos: ["Halter"],
    locais: ["Academia", "Casa"],
    tags: ["isometria", "preensão", "grip estático", "dedos", "força"],
    dificuldade: "Intermediário",
    objetivo: "Força Estática",
    caloriasHora: 130,
    imagem: "assets/gifs/antebraco/isometria_de_preensao_com_halter.gif",
    video: "",
  ),
  ExercicioModel(
    id: "antebr_030",
    nome: "Barra Fixa com Variação de Pegada (Thick Bar)",
    categoria: "Antebraço",
    descricao:
        "Realização de exercícios de barra (pull-up, hang) com barra mais grossa ou usando fat gripz, aumentando exponencialmente a exigência sobre os flexores dos dedos e o grip.",
    comoExecutar:
        "Use fat gripz (adaptadores de barra) ou uma barra de diâmetro maior. Realize hang isométrico ou pull-ups normalmente. A espessura extra da barra impede o fechamento completo dos dedos ao redor da barra, aumentando o trabalho dos flexores.",
    cuidados:
        "Reduza a carga ao usar fat gripz pois o grip será o limitador. Progresso gradual. Não indicado para quem ainda não domina o grip convencional.",
    musculos: ["Flexores dos Dedos", "Intrínsecos da Mão", "Flexores do Punho"],
    musculosSecundarios: ["Latíssimo do Dorso", "Bíceps", "Romboides"],
    equipamentos: ["Fat Gripz", "Barra Fixa"],
    locais: ["Academia"],
    tags: [
      "fat gripz",
      "barra grossa",
      "grip avançado",
      "pull-up",
      "antebraço",
    ],
    dificuldade: "Avançado",
    objetivo: "Força de Preensão",
    caloriasHora: 350,
    imagem:
        "assets/gifs/antebraco/barra_fixa_com_variacao_de_pegada_thick_bar.gif",
    video: "",
  ),
];
