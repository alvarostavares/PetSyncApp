import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TelaAjustes extends StatelessWidget {
  const TelaAjustes({super.key});

  Future<void> _sair(BuildContext context) async {
    final navegador = Navigator.of(context);

    try {
      await Supabase.instance.client.auth.signOut();

      if (navegador.mounted) {
        navegador.popUntil((rota) => rota.isFirst);
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Não foi possível sair: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        backgroundColor: const Color(0xFF2E65F3),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.account_circle_outlined),
            title: const Text('Conta'),
            subtitle: Text(email ?? 'E-mail não disponível'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sair'),
            onTap: () => _sair(context),
          ),
        ],
      ),
    );
  }
}
