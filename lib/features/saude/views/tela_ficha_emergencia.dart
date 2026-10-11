import 'package:flutter/material.dart';

import '../repositories/ficha_emergencia_repository.dart';

class TelaFichaEmergencia extends StatefulWidget {
  final int idPet;
  final String nomePet;
  final bool souTutor;

  const TelaFichaEmergencia({
    super.key,
    required this.idPet,
    required this.nomePet,
    required this.souTutor,
  });

  @override
  State<TelaFichaEmergencia> createState() => _TelaFichaEmergenciaState();
}

class _TelaFichaEmergenciaState extends State<TelaFichaEmergencia> {
  final _repositorio = FichaEmergenciaRepository();

  final _alergiasController = TextEditingController();
  final _condicoesController = TextEditingController();
  final _medicamentosController = TextEditingController();
  final _veterinarioController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _observacoesController = TextEditingController();

  bool _carregando = true;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _alergiasController.dispose();
    _condicoesController.dispose();
    _medicamentosController.dispose();
    _veterinarioController.dispose();
    _telefoneController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final dados = await _repositorio.buscar(widget.idPet);
      if (!mounted) return;

      String valor(String coluna) => (dados?[coluna] as String?) ?? '';

      setState(() {
        _alergiasController.text = valor('alergias');
        _condicoesController.text = valor('condicoes');
        _medicamentosController.text = valor('medicamentos_uso_continuo');
        _veterinarioController.text = valor('veterinario');
        _telefoneController.text = valor('telefone_veterinario');
        _observacoesController.text = valor('observacoes');
        _carregando = false;
      });
    } catch (erro) {
      if (!mounted) return;

      setState(() {
        _erro = 'Não foi possível carregar a ficha: $erro';
        _carregando = false;
      });
    }
  }

  Future<void> _salvar() async {
    if (_salvando || !widget.souTutor) return;

    setState(() => _salvando = true);

    try {
      await _repositorio.salvar(
        idPet: widget.idPet,
        alergias: _alergiasController.text,
        condicoes: _condicoesController.text,
        medicamentosUsoContinuo: _medicamentosController.text,
        veterinario: _veterinarioController.text,
        telefoneVeterinario: _telefoneController.text,
        observacoes: _observacoesController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ficha de emergência salva.')),
      );
    } catch (erro) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Não foi possível salvar: $erro')));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Widget _campo(
    String rotulo,
    TextEditingController controller, {
    int linhas = 2,
    TextInputType? teclado,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        readOnly: !widget.souTutor,
        maxLines: linhas,
        keyboardType: teclado,
        decoration: InputDecoration(
          labelText: rotulo,
          hintText: 'Não informado',
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emergência: ${widget.nomePet}'),
        backgroundColor: const Color(0xFF2E65F3),
        foregroundColor: Colors.white,
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_erro!, textAlign: TextAlign.center),
                  TextButton(
                    onPressed: _carregar,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _campo('Alergias', _alergiasController),
                _campo('Condições de saúde', _condicoesController),
                _campo('Medicamentos de uso contínuo', _medicamentosController),
                _campo(
                  'Veterinário ou clínica',
                  _veterinarioController,
                  linhas: 1,
                ),
                _campo(
                  'Telefone do veterinário ou clínica',
                  _telefoneController,
                  linhas: 1,
                  teclado: TextInputType.phone,
                ),
                _campo('Outras informações', _observacoesController),
                if (widget.souTutor)
                  ElevatedButton(
                    onPressed: _salvando ? null : _salvar,
                    child: Text(_salvando ? 'Salvando...' : 'Salvar ficha'),
                  ),
              ],
            ),
    );
  }
}
