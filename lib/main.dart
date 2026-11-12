import 'dart:async';

import 'features/auth/views/tela_autenticacao.dart';
import 'features/home/views/tela_inicial.dart';
import 'features/auth/views/tela_nova_senha.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'firebase_options.dart';
import 'core/notificacao_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://drmhnywngysgfgdfbfmf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRybWhueXduZ3lzZ2ZnZGZiZm1mIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkwMzgwMjksImV4cCI6MjEwNDYxNDAyOX0.nsnyEU2nvwiPFxCH1Pxb9dcK_GaOR6QFDRDF8zD-XnA',
  );

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(const PetSyncApp());
  NotificacaoService.instancia.iniciar();
}

class PetSyncApp extends StatelessWidget {
  const PetSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetSync',
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
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
  bool _redefinindoSenha = false;

  @override
  void initState() {
    super.initState();

    _sessao = _auth.currentSession;

    _assinatura = _auth.onAuthStateChange.listen(
      (estado) {
        if (!mounted) return;

        setState(() {
          _sessao = estado.session;

          if (estado.event == AuthChangeEvent.passwordRecovery) {
            _redefinindoSenha = true;
          } else if (estado.event == AuthChangeEvent.signedOut) {
            _redefinindoSenha = false;
          }
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

    if (_redefinindoSenha) {
      return const TelaNovaSenha();
    }

    if (sessao == null) {
      return const TelaAutenticacao();
    }

    return TelaInicial(key: ValueKey(sessao.user.id));
  }
}
