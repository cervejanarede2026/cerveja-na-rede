# Cerveja na Rede — V28

## Novidades
- Galeria de Fotos no menu inicial, logo abaixo de Torneio.
- Organização da galeria em **Fotos gerais** e **Fotos das partidas**.
- Cada partida aparece com data, confronto e quantidade de fotos.
- Visualização ampliada das fotos.
- Exclusão de fotos somente após autenticação do administrador.
- Estatísticas da partida só podem ser zeradas pelo administrador; a regra também é protegida no Supabase.
- Área administrativa com login, logout e alteração de senha.
- Senha inicial, se a instalação V25 ainda não tinha sido alterada: `CNRADMIN2026!`
- A nova senha precisa ter pelo menos 8 caracteres.

## Instalação
1. Substitua os arquivos do GitHub Pages pela V28.
2. Execute `SUPABASE_V28_SETUP.sql` no Supabase SQL Editor.
3. Não apague as tabelas existentes.
4. Abra o app e entre em Administração com a senha atual.

## Segurança
A exclusão de objetos do Storage é controlada por RLS e por uma sessão administrativa vinculada ao usuário autenticado. O código do navegador não contém a senha administrativa.
