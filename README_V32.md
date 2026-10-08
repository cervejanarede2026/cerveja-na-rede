# Cerveja na Rede — V32

## Novidades
- Galeria de Vídeos dentro da Galeria de Fotos.
- Botões para gravar vídeo pelo celular e escolher vídeos da galeria.
- Vídeos ficam no mesmo bucket `player-photos`, dentro da pasta `videos/`, portanto não exige novo bucket ou SQL adicional.
- Cada vídeo pode ser aberto em tela ampliada, reproduzido e baixado.
- Exclusão de vídeo é protegida pela sessão de administrador e usa a mesma função/policy de exclusão do Storage já configurada.
- Estado da galeria de vídeos sincroniza entre os celulares pelo Supabase (`cnr_video_gallery`).
- Limite de segurança no aplicativo: 50 MB por vídeo. Vídeos não são recomprimidos pelo navegador.
- Estatísticas: `Saque vencedor` passou a `Errou`; `Levantamento decisivo` passou a `Levantamento`.
- No Histórico, cada partida ganhou `Registrar/alterar estatísticas`. É possível abrir uma partida já finalizada, alterar ou registrar ações e salvar sem alterar resultado, sets ou vencedor.
- O modo de edição de partida finalizada esconde os controles de finalizar/novo jogo para evitar alterar a partida por acidente.
- Partidas novas continuam seguindo o fluxo automático existente.

## Supabase
Nenhum SQL novo é necessário para a galeria de vídeos porque ela usa o bucket `player-photos` existente e a mesma proteção de Storage.

Observação: vídeos podem consumir bastante armazenamento. Para manter o plano gratuito sustentável, prefira vídeos curtos e compactados pelo próprio celular.
