import 'package:flutter/material.dart';

import '../models/pet_model.dart';
import '../repositories/pet_repository.dart';

class TelaPerfilPet extends StatefulWidget {
  final PetModel? petAtual;

  const TelaPerfilPet({super.key, this.petAtual});

  @override
  State<TelaPerfilPet> createState() => _TelaPerfilPetState();
}

class _TelaPerfilPetState extends State<TelaPerfilPet> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _racaController = TextEditingController();
  final _dataController = TextEditingController();

  DateTime? _dataNascimentoSelecionada;
  String _sexoSelecionado = 'nao_informado';
  String? _tipoAnimalSelecionado;

  final PetRepository _repositorio = PetRepository();
  bool _estaCarregando = false;

  Future<void> _selecionarData() async {
    final DateTime? dataEscolhida = await showDatePicker(
      context: context,
      initialDate: _dataNascimentoSelecionada ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF2E65F3)),
          ),
          child: child!,
        );
      },
    );

    if (!mounted) return;

    if (dataEscolhida != null) {
      setState(() {
        _dataNascimentoSelecionada = dataEscolhida;
        _dataController.text =
            '${dataEscolhida.day.toString().padLeft(2, '0')}/'
            '${dataEscolhida.month.toString().padLeft(2, '0')}/'
            '${dataEscolhida.year}';
      });
    }
  }

  Future<void> _salvarPet() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() => _estaCarregando = true);

    try {
      final petFormulario = PetModel(
        idPet: widget.petAtual?.idPet,
        nome: _nomeController.text.trim(),
        especie: _tipoAnimalSelecionado,
        raca: _racaController.text.trim(),
        dataNascimento:
            _dataNascimentoSelecionada ?? widget.petAtual?.dataNascimento,
        sexo: _sexoSelecionado,
        pontuacaoGrupo: widget.petAtual?.pontuacaoGrupo ?? 0,
      );

      if (widget.petAtual == null) {
        await _repositorio.cadastrarPet(petFormulario);
      } else {
        await _repositorio.atualizarPet(petFormulario);
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() => _estaCarregando = false);

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.petAtual != null) {
      final p = widget.petAtual!;

      _nomeController.text = p.nome;
      const tiposPermitidos = {'cachorro', 'gato', 'ave', 'coelho', 'outro'};

      _tipoAnimalSelecionado = tiposPermitidos.contains(p.especie)
          ? p.especie
          : null;
      _racaController.text = p.raca ?? '';
      _sexoSelecionado = p.sexo;

      if (p.dataNascimento != null) {
        _dataNascimentoSelecionada = p.dataNascimento;
        _dataController.text =
            '${p.dataNascimento!.day.toString().padLeft(2, '0')}/'
            '${p.dataNascimento!.month.toString().padLeft(2, '0')}/'
            '${p.dataNascimento!.year}';
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _racaController.dispose();
    _dataController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E65F3),
        foregroundColor: Colors.white,
        title: Text(
          widget.petAtual != null ? 'Editar Pet' : 'Cadastrar Novo Pet',
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.pets, size: 80, color: Color(0xFF2E65F3)),
              const SizedBox(height: 32),

              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome do Pet',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                validator: (valor) => valor == null || valor.trim().isEmpty
                    ? 'Por favor, insira o nome'
                    : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _tipoAnimalSelecionado,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Tipo de animal',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: const [
                  DropdownMenuItem(value: 'cachorro', child: Text('Cachorro')),
                  DropdownMenuItem(value: 'gato', child: Text('Gato')),
                  DropdownMenuItem(value: 'ave', child: Text('Ave')),
                  DropdownMenuItem(value: 'coelho', child: Text('Coelho')),
                  DropdownMenuItem(value: 'outro', child: Text('Outro')),
                ],
                onChanged: (valor) {
                  setState(() {
                    _tipoAnimalSelecionado = valor;
                  });
                },
                validator: (valor) =>
                    valor == null ? 'Selecione o tipo de animal' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _sexoSelecionado,
                decoration: const InputDecoration(
                  labelText: 'Sexo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.pets),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'nao_informado',
                    child: Text('Não informado'),
                  ),
                  DropdownMenuItem(value: 'macho', child: Text('Macho')),
                  DropdownMenuItem(value: 'femea', child: Text('Fêmea')),
                ],
                onChanged: (valor) {
                  if (valor == null) return;

                  setState(() {
                    _sexoSelecionado = valor;
                  });
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _racaController,
                decoration: const InputDecoration(
                  labelText: 'Raça',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.auto_awesome),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _dataController,
                readOnly: true,
                onTap: _selecionarData,
                decoration: const InputDecoration(
                  labelText: 'Data de Nascimento',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cake),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _estaCarregando ? null : _salvarPet,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF2E65F3),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _estaCarregando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Salvar Cadastro',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
