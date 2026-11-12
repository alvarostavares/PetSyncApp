import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/mensagens_erro.dart';

class TelaNovaSenha extends StatefulWidget {
  const TelaNovaSenha({super.key});

  @override
  State<TelaNovaSenha> createState() => _TelaNovaSenhaState();
}

class _TelaNovaSenhaState extends State<TelaNovaSenha> {
  final _senhaController = TextEditingController();
  final _confirmacaoController = TextEditingController();
  bool _salvando = false;

  Future<void> _salvar() async {
    final senha = _senhaController.text;

    if (senha.length < 6) {
      _mostrar('Use pelo menos 6 caracteres.');
      return;
    }

    if (senha != _confirmacaoController.text) {
      _mostrar('As senhas não coincidem.');
      return;
    }

    setState(() => _salvando = true);

    try {
      final auth = Supabase.instance.client.auth;

      await auth.updateUser(UserAttributes(password: senha));

      if (!mounted) return;

      _mostrar('Senha atualizada. Entre com a nova senha.');

      // Volta à tela de login após salvar.
      await auth.signOut();
    } on AuthException catch (erro) {
      if (mounted) _mostrar('Não foi possível alterar: ${mensagemErro(erro)}');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _mostrar(String mensagem) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  void dispose() {
    _senhaController.dispose();
    _confirmacaoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Definir nova senha')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _senhaController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Nova senha',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmacaoController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirme a nova senha',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _salvando ? null : _salvar,
                  child: Text(_salvando ? 'Salvando...' : 'Salvar nova senha'),
                ),
                TextButton(
                  onPressed: _salvando
                      ? null
                      : () => Supabase.instance.client.auth.signOut(),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
