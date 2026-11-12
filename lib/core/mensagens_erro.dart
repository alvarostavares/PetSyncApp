import 'package:supabase_flutter/supabase_flutter.dart';

String mensagemErro(Object erro) {
  if (erro is AuthException) {
    return switch (erro.code) {
      'invalid_credentials' => 'E-mail ou senha incorretos.',
      'email_not_confirmed' => 'Confirme seu e-mail antes de entrar.',
      'user_already_exists' ||
      'email_exists' => 'Já existe uma conta com esse e-mail.',
      'weak_password' => 'Escolha uma senha mais forte.',
      'otp_expired' => 'O link expirou ou já foi usado. Solicite outro.',
      'same_password' => 'A nova senha deve ser diferente da anterior.',
      'over_email_send_rate_limit' || 'over_request_rate_limit' =>
        'Muitas tentativas. Aguarde alguns minutos e tente novamente.',
      'email_address_not_authorized' =>
        'O envio de e-mail para este endereço não está disponível.',
      'refresh_token_not_found' ||
      'refresh_token_already_used' => 'Sua sessão expirou. Entre novamente.',
      _ => 'Não foi possível autenticar. Tente novamente.',
    };
  }

  if (erro is PostgrestException) {
    return switch (erro.code) {
      '23505' => 'Esse registro já existe.',
      '23502' => 'Preencha os campos obrigatórios.',
      '23503' => 'O registro está vinculado a outros dados.',
      '23514' => 'Algum dado não atende às regras do cadastro. Confira os campos e as datas.',
      '42501' => 'Você não tem permissão para realizar esta ação.',
      _ => 'Não foi possível salvar os dados. Tente novamente.',
    };
  }

  return 'Não foi possível concluir a operação. Tente novamente.';
}
