# Cerveja na Rede — V35

## Compactação automática de vídeos
- Ao adicionar um vídeo, o aplicativo tenta compactá-lo no próprio celular/computador.
- Saída preferencial: WebM (VP9/VP8 + Opus), até 720 px e 24 fps, com bitrate reduzido.
- Se o navegador não oferecer suporte à regravação ou se a versão compactada não ficar menor, o arquivo original é enviado.
- O app continua limitando a entrada a 50 MB por vídeo.
- Fotos continuam usando a compactação JPEG já existente.
- A galeria de vídeos continua em Vídeos e Links, com exclusão individual somente pelo administrador.
- Os vídeos continuam sendo armazenados no Supabase Storage; apenas os metadados ficam em `cnr_video_gallery`.

## Observação
A compactação acontece no dispositivo e pode levar alguns segundos/minutos em vídeos longos, dependendo do celular/computador.
