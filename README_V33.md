# Cerveja na Rede — V33

## Alteração desta versão
- A **Galeria de Vídeos** foi retirada de “Galeria de Fotos” e colocada dentro do menu **🎥 Vídeos e Links**.
- Dentro de “Vídeos e Links” ficam juntos os links salvos e a galeria de vídeos.
- O controle de administrador dos vídeos segue o mesmo modelo das fotos: senha de administrador, exclusão individual e exclusão pelo modo ampliado.
- Usuários comuns continuam podendo assistir/baixar vídeos, mas não podem excluir.
- A exclusão usa a proteção já existente do Supabase (`admin_delete_photo` + política de Storage com `is_admin_session()`), sem enfraquecer a segurança.
- **Não é necessário executar SQL novo** para esta mudança, desde que o setup de administração/Storage das versões anteriores já esteja configurado.
