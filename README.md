# Cerveja na Rede — V16 Online Fixo

Esta versão usa um único grupo online fixo. Todos os aparelhos que abrirem o aplicativo entram automaticamente no mesmo grupo, sem criar ou digitar código.

## Configuração única no Supabase
1. Abra o projeto `cerveja-na-rede` no Supabase.
2. Vá em **SQL Editor > New query**.
3. Abra o arquivo `SUPABASE_SETUP.sql` desta versão, copie todo o conteúdo e cole na nova consulta.
4. Clique em **Run**.
5. Confirme que **Authentication > Providers > Anonymous** está ativado.
6. Em **Database > Publications**, confirme que `fixed_players` e `fixed_state` aparecem em `supabase_realtime`.

Depois disso, basta publicar os arquivos no GitHub Pages. Não é necessário criar grupo nem conectar cada celular.

## O que mudou
- Grupo online fixo e automático.
- Jogadores sincronizados por registro, evitando que editar uma pessoa apague a foto/dados de outra.
- Fotos continuam compartilhadas junto do jogador.
- Histórico, times, placar, estatísticas e torneios usam estado online separado.
- Realtime para atualizações entre celulares.
- Chave `sb_publishable_...` usada no navegador; nunca use uma chave `sb_secret_...` no GitHub.


V23: correção do ReferenceError cloudDirtyPlayers (declaração movida para antes do uso).
