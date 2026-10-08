CERVEJA NA REDE — V30

Correções desta versão:
- Controle de administrador também aparece dentro da Galeria de Fotos.
- Botões de exclusão ficam visíveis em todas as fotos da galeria quando o administrador está autenticado.
- Para quem não está autenticado, cada foto mostra que a exclusão exige administrador.
- Fotos antigas que já estavam cadastradas na galeria também podem ser removidas da lista, mesmo quando o registro antigo não possui `path` do Storage.
- Quando a foto possui `path`, a versão tenta apagar também o arquivo do Supabase Storage.
- Exclusão de fotos de partidas e fotos gerais usa a mesma proteção administrativa.

IMPORTANTE:
- Execute SUPABASE_V28_SETUP.sql no Supabase se ainda não tiver executado o SQL de administração.
- A senha inicial prevista pelo pacote é a definida no SQL. Depois, use a área de Administração para alterá-la.


V30: a galeria permite abrir uma única foto em tela ampliada e, somente após autenticação do administrador, excluir exatamente aquela foto. O SQL também pode ser executado novamente sem erro de policy já existente. Fotos antigas sem `path` são removidas da galeria; fotos com `path` também são removidas do Storage.
