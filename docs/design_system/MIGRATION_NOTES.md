# Migration Notes — Design System 3.0

## Estratégia

O projeto já possuía `lib/design_system`. O marco `DS3.0-M02` evolui essa
estrutura, sem criar uma segunda implementação em `lib/core/design_system` e
sem migrar telas em massa.

## Classes preservadas

| API existente | Tratamento no M02 | Remoção |
| --- | --- | --- |
| `AppTheme.dark` | alias para `FitTheme.dark()` | não prevista enquanto houver imports |
| `AppTheme.legacyDark` | configuração estrutural anterior com aliases atuais | após migração |
| `AppColors` | aliases semânticos para `FitColors`; ranks permanecem legados | gradual |
| `AppRadii` | aliases para `FitRadius` | gradual |
| `AppSpacing` | aliases para valores legados centralizados em `FitSpacing` | após migração visual |
| `AppMotion` | aliases para tempos legados centralizados em `FitDuration` | gradual |
| widgets em `theme/app_theme.dart` | preservados sem alteração de negócio | por micro-sprint |
| componentes `Fit*` | preservados | nenhuma |

Novos arquivos devem importar
`package:fitai/design_system/fit_design_system.dart`.

## Fonte única de tema

`FitTheme.dark()` é a factory oficial. A entrada atual do aplicativo continua
usando `AppTheme.dark`, mas esse getter delega para a factory oficial. Assim,
navegação e imports existentes continuam funcionando sem manter dois temas
ativos.

`AppTheme.legacyDark` não é um tema alternativo de produto. Ele preserva a
configuração estrutural anterior para apoiar a migração, mas consome os aliases
cromáticos atuais e não é um snapshot visual bit a bit. Não deve ser usado por
novas telas.

## Divergências encontradas

### Paleta

| Legado | DS3 | Decisão |
| --- | --- | --- |
| fundo `#070808` | `#00060C` | adotar neutro medido |
| superfície `#101312` | `#080E13` | adotar neutro medido |
| verde neon `#00E676` | candidato `#70A527` | adotar valor DS3 provisório |
| IA e Info compartilhavam azul | IA teal `#44B89C`; Info azul `#2F9ADB` | separar intenção |
| erro rosado `#FF5C7A` | vermelho `#C32722` | adotar papel DS3 |
| card local `#151917` | `#0A1218` | usar token de card |

O valor central do verde ainda é `PROVISÓRIO`. A mudança futura deve preservar
`FitColors.primary` e alterar somente sua referência interna.

### Accent

Não foi criado `FitColors.accent`. `DS-013` determina cores por domínio:
`ai`, `info`, `energy`, `warning`, `error`, `xp`, `premium` e `achievement`.

### Tipografia

- nenhuma fonte externa foi adicionada;
- o fallback da plataforma continua ativo;
- papéis semânticos foram completados;
- tamanhos, pesos e leading permanecem provisórios;
- números usam aliases com algarismos tabulares quando disponíveis.

### Spacing, radius, grid, elevation e motion

Essas foundations ainda não possuem valores finais no DS3. O Flutter mantém os
valores do Design System anterior como candidatos centralizados. Comentários e
o arquivo `FLUTTER_MAPPING.md` registram sua maturidade.

`AppMotion` preserva exatamente `160/240/320 ms` por aliases `legacyApp*`.
Novas APIs usam os papéis semânticos de `FitDuration`; nenhuma animação
existente foi acelerada por esta migração.

### Gradientes

Somente action, media scrim, chart area, glow contextual e surface depth entram
no mapeamento DS3. Gradientes `legacy*` permanecem centralizados exclusivamente
para não quebrar consumidores antigos.

## ThemeExtensions

Foram mantidas apenas duas extensões:

- `FitSemanticColors`: cores de domínio, gráficos e superfícies adicionais;
- `FitThemeGradients`: gradientes que não cabem em `ColorScheme`.

Cores globais continuam em `ColorScheme`. Não foram criadas extensões para
valores que já possuem lugar natural no Flutter.

## Migrações futuras

1. migrar imports `AppColors` para `FitColors` por módulo;
2. migrar `AppSpacing`, `AppRadii` e `AppMotion` em micro-sprints visuais;
3. remover literais dos Core Components restantes;
4. comparar o tema oficial em Android, Web e Windows;
5. medir foundations antes de remover a marcação provisória;
6. retirar `AppTheme.legacyDark` somente quando não houver necessidade de
   comparação;
7. remover aliases `legacy*` após não existirem consumidores.

Nenhuma dessas migrações foi iniciada automaticamente.
