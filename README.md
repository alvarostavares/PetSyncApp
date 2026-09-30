# PetApp

Aplicativo Flutter desenvolvido como parte do Trabalho de Conclusão de Curso de Sistemas de Informação da Universidade Federal de Sergipe (UFS). O projeto busca reunir informações dos pets e permitir que familiares acompanhem seus cuidados em um mesmo lugar.

## Estado do projeto

Protótipo acadêmico em desenvolvimento.

### Funcionalidades atuais

- Cadastro e autenticação de usuários por e-mail.
- Cadastro de múltiplos pets, com espécie, raça, sexo e data de nascimento.
- Edição e exclusão dos dados do pet pelo tutor.
- Atualização dos pets em tempo real entre dispositivos.
- Compartilhamento de pets por código de convite.
- Consulta dos dados do pet por participantes convidados, com permissões controladas no banco de dados.

A gestão da lista de participantes e a remoção de acesso estão em validação.

### Em desenvolvimento

- Registros de saúde e rotina.
- Linha do tempo de cuidados.
- Gamificação e recursos de apoio à análise dos dados.

## Tecnologias

- Flutter e Dart
- Supabase Auth
- PostgreSQL com políticas de segurança por linha (RLS)
- Supabase Realtime

## Execução local

1. Instale e configure o Flutter.
2. Na raiz do projeto, instale as dependências:

   ```bash
   flutter pub get
   ```

3. Configure a URL e a chave pública de um projeto Supabase em `lib/main.dart`.
4. Configure no Supabase as tabelas, funções e políticas utilizadas pelo aplicativo.
5. Execute:

   ```bash
   flutter run
   ```

> As migrações do banco de dados ainda precisam ser adicionadas ao repositório. Por enquanto, o código Flutter sozinho não recria a estrutura necessária no Supabase.

## Autor

Álvaro Santos Tavares