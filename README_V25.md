# Cerveja na Rede — V25

## Novidades
- Álbum de fotos por partida, armazenado no Supabase Storage.
- Fotos podem ser adicionadas durante a partida e aparecem no histórico da partida.
- Ao finalizar uma partida, a próxima é criada automaticamente com o vencedor contra o próximo time.
- Se houver somente dois times, a próxima partida repete os mesmos dois times.
- Limpeza de partidas/ranking/álbuns protegida por senha de administrador no Supabase.

## Instalação
1. Substitua os arquivos do GitHub Pages pelos arquivos desta pasta.
2. No Supabase, execute `SUPABASE_V25_SETUP.sql` uma única vez.
3. Senha inicial da administração: `CNRADMIN2026!`.
4. Para trocar a senha, use o UPDATE comentado no final do SQL.

## Importante
- Não coloque `service_role` ou `sb_secret_...` no aplicativo.
- A publishable key pode continuar no navegador; a autorização é feita com Supabase Auth/RLS.
- O Storage usa o bucket `player-photos` tanto para fotos dos jogadores quanto para álbuns.

## Fluxo das partidas
- A primeira partida continua sendo escolhida normalmente em `Preparar partida`.
- Ao finalizar, o resultado é salvo no histórico.
- O vencedor permanece e enfrenta o próximo time disponível.
- Com apenas dois times, os mesmos dois continuam jogando.

## Manutenção
Consulte também o pacote de manutenção completo entregue anteriormente.
