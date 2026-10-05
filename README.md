# Cerveja na Rede — V10 Online

Esta versão mantém todos os recursos anteriores e adiciona **grupo online compartilhado**.

## O que mudou
- ☁️ Criar grupo por código (ex.: CRN-8472)
- ↗ Entrar em um grupo pelo código
- 🔄 Sincronização em tempo real entre celulares
- 👥 Jogadores, fotos, estrelas, posições e presença compartilhados
- 🎲 Sorteios e times compartilhados
- 🏆 Placar, sets e estatísticas compartilhados
- 📊 Histórico, ranking e torneios compartilhados
- 📴 Continua funcionando localmente quando não há internet

## Configuração do banco

1. Crie um projeto gratuito no Supabase.
2. Em **Authentication → Providers**, ative **Anonymous sign-ins**.
3. Abra **SQL Editor** e execute o arquivo `SUPABASE_SETUP.sql`.
4. Em **Database → Replication**, adicione `public.group_state` à publicação `supabase_realtime`.
5. No Cerveja na Rede, toque em **☁️ Grupo online → ⚙️** e informe:
   - Project URL
   - chave **anon/public**

**Nunca coloque a chave `service_role` no aplicativo.**

Depois disso, crie um grupo e passe o código para as outras pessoas. Todos os celulares que entrarem pelo mesmo código verão os mesmos dados.


## V11 — correção do acesso online

A V11 corrige a autenticação anônima do Supabase: o aplicativo agora confirma a sessão antes de criar/entrar em um grupo, mostra o erro real de conexão e inclui o botão **Testar conexão**. O Service Worker também foi atualizado para a V11.
