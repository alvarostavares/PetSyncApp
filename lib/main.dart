import 'dart:async';

import 'features/auth/views/tela_autenticacao.dart';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/home/views/tela_inicial.dart'; // Importação da nova tela principal

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://drmhnywngysgfgdfbfmf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRybWhueXduZ3lzZ2ZnZGZiZm1mIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkwMzgwMjksImV4cCI6MjEwNDYxNDAyOX0.nsnyEU2nvwiPFxCH1Pxb9dcK_GaOR6QFDRDF8zD-XnA',
  );

  runApp(const PetSyncApp());
}

class PetSyncApp extends StatelessWidget {
  const PetSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Cor baseada no azul do protótipo
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E65F3)),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        useMaterial3: true,
      ),
      home: const PortaAutenticacao(), // Aponta para a nova Home
    );
  }
}

class PortaAutenticacao extends StatefulWidget {
  const PortaAutenticacao({super.key});

  @override
  State<PortaAutenticacao> createState() => _PortaAutenticacaoState();
}

class _PortaAutenticacaoState extends State<PortaAutenticacao> {
  final _auth = Supabase.instance.client.auth;

  StreamSubscription<AuthState>? _assinatura;
  Session? _sessao;

  @override
  void initState() {
    super.initState();

    _sessao = _auth.currentSession;

    _assinatura = _auth.onAuthStateChange.listen(
      (estado) {
        if (!mounted) return;

        setState(() {
          _sessao = estado.session;
        });
      },
      onError: (Object erro, StackTrace stackTrace) {
        debugPrint('Erro ao acompanhar a autenticação: $erro');
      },
    );
  }

  @override
  void dispose() {
    _assinatura?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessao = _sessao;

    if (sessao == null) {
      return const TelaAutenticacao();
    }

    return TelaInicial(key: ValueKey(sessao.user.id));
  }
}
