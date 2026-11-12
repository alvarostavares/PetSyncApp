import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/mensagens_erro.dart';

class TelaAutenticacao extends StatefulWidget {
  const TelaAutenticacao({super.key});

  @override
  State<TelaAutenticacao> createState() => _TelaAutenticacaoState();
}

class _TelaAutenticacaoState extends State<TelaAutenticacao> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();

  bool _cadastrando = false;
  bool _carregando = false;

  Future<void> _enviar() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _carregando = true);

    try {
      final auth = Supabase.instance.client.auth;
      final email = _emailController.text.trim();
      final senha = _senhaController.text;

      if (_cadastrando) {
        final resposta = await auth.signUp(email: email, password: senha);

        if (!mounted) return;

        if (resposta.session == null) {
          setState(() => _carregando = false);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Confira seu e-mail para confirmar o cadastro. '
                'Depois, entre com sua senha.',
              ),
            ),
          );
        }
      } else {
        await auth.signInWithPassword(email: email, password: senha);
      }

      // Se houver sessão, o portão em main.dart abrirá a tela inicial.
    } on AuthException catch (e) {
      if (!mounted) return;

      setState(() => _carregando = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensagemErro(e))));
    } catch (e) {
      if (!mounted) return;

      setState(() => _carregando = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensagemErro(e))));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  Future<void> _recuperarSenha() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe seu e-mail primeiro.')),
      );
      return;
    }

    setState(() => _carregando = true);

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'petsyncapp://reset-password/',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Confira seu e-mail para abrir o link de redefinição.'),
        ),
      );
    } on AuthException catch (erro) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(erro.message)));
      }
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_cadastrando ? 'Criar conta' : 'Entrar')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.pets, size: 72, color: Color(0xFF2E65F3)),
                  const SizedBox(height: 32),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) {
                      if (valor == null || valor.trim().isEmpty) {
                        return 'Informe seu e-mail';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _senhaController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      border: OutlineInputBorder(),
                    ),
                    validator: (valor) {
                      if (valor == null || valor.length < 6) {
                        return 'Informe uma senha com pelo menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  if (!_cadastrando)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _carregando ? null : _recuperarSenha,
                        child: const Text('Esqueceu a senha?'),
                      ),
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _carregando ? null : _enviar,
                    child: _carregando
                        ? const CircularProgressIndicator()
                        : Text(_cadastrando ? 'Criar conta' : 'Entrar'),
                  ),
                  const SizedBox(height: 8),

                  TextButton(
                    onPressed: _carregando
                        ? null
                        : () {
                            setState(() {
                              _cadastrando = !_cadastrando;
                            });
                          },
                    child: Text(
                      _cadastrando ? 'Já tenho conta' : 'Ainda não tenho conta',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
