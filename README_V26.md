# Cerveja na Rede — V26

## Novidades
- Galeria geral de fotos, independente das partidas.
- Fotos gerais usam o mesmo bucket `player-photos`, em `general/`.
- Visualização ampliada e exclusão de fotos gerais.
- Área `🎥 Vídeos e Links` para cadastrar links importantes.
- Campo de nome, URL e descrição.
- Primeiro exemplo recomendado: `https://apertai.com.br/`.
- Links ficam sincronizados entre os aparelhos pelo `fixed_state`.
- Mantidos álbum por partida, partidas automáticas e administração da V25.

## Supabase
Não é necessário criar tabela nova se o SQL da V25 já foi executado. O bucket `player-photos` e suas políticas continuam sendo usados.

A V26 adiciona somente duas chaves ao `fixed_state`:
- `cnr_general_gallery`
- `cnr_important_links`

## Publicação
Substitua `index.html` e `logo.png` no GitHub Pages. Não altere as configurações do Supabase.
