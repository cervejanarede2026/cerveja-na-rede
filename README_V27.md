# Cerveja na Rede V27 — Fotos pela câmera

Esta versão mantém a V26 e acrescenta botões explícitos para abrir a câmera do celular:
- Novo jogador: Câmera ou Galeria
- Editar jogador: Tirar foto ou Galeria
- Álbum da partida: Tirar foto ou Galeria
- Galeria geral: Tirar foto ou Galeria

Os inputs de câmera usam `accept="image/*" capture="environment"`. Em celulares compatíveis, isso solicita a câmera traseira; em navegadores que não suportam `capture`, o sistema pode mostrar o seletor normal de arquivos/fotos.
