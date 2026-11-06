import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificacaoService {
  NotificacaoService._();

  static final instancia = NotificacaoService._();

  final _supabase = Supabase.instance.client;
  bool _iniciado = false;
  bool _saindo = false;
  Future<void>? _registroEmAndamento;

  bool get _suportaPush =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  void iniciar() {
    if (!_suportaPush || _iniciado) return;
    _iniciado = true;

    _supabase.auth.onAuthStateChange.listen((dados) {
      if (dados.event == AuthChangeEvent.initialSession ||
          dados.event == AuthChangeEvent.signedIn) {
        unawaited(_registrarComTratamento());
      }
    });

    FirebaseMessaging.instance.onTokenRefresh.listen(
      (_) => unawaited(_registrarComTratamento()),
      onError: (Object erro) {
        debugPrint('Erro ao renovar notificações: $erro');
      },
    );

    // Também cobre uma sessão que já estava aberta ao iniciar o app.
    unawaited(_registrarComTratamento());
  }

  Future<void> _registrarComTratamento() {
    if (_saindo) return Future.value();

    return _registroEmAndamento ??= _registrarToken()
        .catchError((Object erro) {
          debugPrint('Erro ao registrar notificações: $erro');
        })
        .whenComplete(() {
          _registroEmAndamento = null;
        });
  }

  Future<void> _registrarToken() async {
    final idUsuario = _supabase.auth.currentUser?.id;
    if (idUsuario == null) return;

    final permissao = await FirebaseMessaging.instance.requestPermission();
    if (permissao.authorizationStatus != AuthorizationStatus.authorized &&
        permissao.authorizationStatus != AuthorizationStatus.provisional) {
      return;
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || _saindo) return;

    // A conta pode ter mudado enquanto aguardávamos o Firebase.
    if (_supabase.auth.currentUser?.id != idUsuario) return;

    await _supabase.rpc(
      'registrar_dispositivo_push',
      params: {'p_token': token},
    );
  }

  Future<void> sairDaConta() async {
    _saindo = true;

    try {
      // Aguarda um registro iniciado anteriormente antes de remover o token.
      await _registroEmAndamento;

      if (_suportaPush && _supabase.auth.currentUser != null) {
        final token = await FirebaseMessaging.instance.getToken();

        if (token != null) {
          await _supabase.rpc(
            'remover_dispositivo_push',
            params: {'p_token': token},
          );
        }
      }

      await _supabase.auth.signOut();
    } finally {
      _saindo = false;
    }
  }
}
