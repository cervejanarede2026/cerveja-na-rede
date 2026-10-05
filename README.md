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
4. O arquivo já deixa `public.group_state` habilitado no Realtime, se ainda não estiver.
5. Esta versão já vem configurada com o Project URL e a chave **Publishable** do projeto.
6. Abra **☁️ Grupo online**, crie um grupo e passe o código para as outras pessoas.

A chave Publishable pode ficar no aplicativo do navegador; ela é feita para uso em componentes públicos. **Nunca coloque a chave Secret/service_role no aplicativo.**

Todos os celulares que entrarem pelo mesmo código verão os mesmos dados.
