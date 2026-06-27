import 'package:flutter/material.dart';
import '../controller/admin_controller.dart';
import '../model/barbearia_model.dart';

class BarbeariasPage extends StatefulWidget {
  const BarbeariasPage({super.key});

  @override
  State<BarbeariasPage> createState() => _BarbeariasPageState();
}

class _BarbeariasPageState extends State<BarbeariasPage> {
  final AdminController _adminController = AdminController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Barbearias',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => _showAddEditBarbeariaDialog(),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Adicionar Barbearia'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB22222),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Barbearias',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddEditBarbeariaDialog(),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text('Adicionar Barbearia'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB22222),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        const SizedBox(height: 20),

        // Search bar
        TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
          decoration: InputDecoration(
            hintText: 'Pesquisar barbearias...',
            hintStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.search, color: Colors.white70),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 20),

        Expanded(
          child: StreamBuilder<List<BarbeariaModel>>(
            stream: _adminController.getAllBarbearias(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Erro: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                );
              }
              final allBarbearias = snapshot.data ?? [];

              // Filter barbearias based on search query
              final filteredBarbearias = allBarbearias.where((barbearia) {
                return barbearia.name.toLowerCase().contains(_searchQuery) ||
                       barbearia.address.toLowerCase().contains(_searchQuery) ||
                       barbearia.phone.contains(_searchQuery);
              }).toList();

              if (filteredBarbearias.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhuma barbearia encontrada',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredBarbearias.length,
                itemBuilder: (context, index) {
                  final barbearia = filteredBarbearias[index];
                  return Card(
                    color: const Color(0xFF2A2A2A),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      barbearia.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      barbearia.address,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Telefone: ${barbearia.phone}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Horários: ${barbearia.daysHours}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: barbearia.isActive ? Colors.green : Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  barbearia.isActive ? 'Ativa' : 'Inativa',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (isMobile)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _toggleActive(barbearia),
                                  icon: Icon(
                                    barbearia.isActive ? Icons.visibility_off : Icons.visibility,
                                    color: barbearia.isActive ? Colors.orange : Colors.green,
                                  ),
                                  label: Text(
                                    barbearia.isActive ? 'Desativar' : 'Ativar',
                                    style: TextStyle(
                                      color: barbearia.isActive ? Colors.orange : Colors.green,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextButton.icon(
                                  onPressed: () => _showAddEditBarbeariaDialog(barbearia: barbearia),
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  label: const Text(
                                    'Editar',
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                TextButton.icon(
                                  onPressed: () => _deleteBarbearia(barbearia),
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  label: const Text(
                                    'Excluir',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () => _toggleActive(barbearia),
                                  icon: Icon(
                                    barbearia.isActive ? Icons.visibility_off : Icons.visibility,
                                    color: barbearia.isActive ? Colors.orange : Colors.green,
                                  ),
                                  label: Text(
                                    barbearia.isActive ? 'Desativar' : 'Ativar',
                                    style: TextStyle(
                                      color: barbearia.isActive ? Colors.orange : Colors.green,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _showAddEditBarbeariaDialog(barbearia: barbearia),
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  label: const Text(
                                    'Editar',
                                    style: TextStyle(color: Colors.blue),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () => _deleteBarbearia(barbearia),
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  label: const Text(
                                    'Excluir',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddEditBarbeariaDialog({BarbeariaModel? barbearia}) {
    final isEditing = barbearia != null;
    final nameController = TextEditingController(text: barbearia?.name ?? '');
    final addressController = TextEditingController(text: barbearia?.address ?? '');
    final daysHoursController = TextEditingController(text: barbearia?.daysHours ?? '');
    final phoneController = TextEditingController(text: barbearia?.phone ?? '');
    bool isActive = barbearia?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: Text(
            isEditing ? 'Editar Barbearia' : 'Adicionar Barbearia',
            style: const TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome da Barbearia',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFB22222)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Endereço Completo',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFB22222)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: daysHoursController,
                  decoration: const InputDecoration(
                    labelText: 'Dias e Horários de Funcionamento',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFB22222)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Número de Telefone',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white70),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFFB22222)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Ativa:',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: isActive,
                      onChanged: (value) {
                        setState(() {
                          isActive = value;
                        });
                      },
                      activeColor: const Color(0xFFB22222),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    addressController.text.isEmpty ||
                    daysHoursController.text.isEmpty ||
                    phoneController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Preencha todos os campos')),
                  );
                  return;
                }

                final newBarbearia = BarbeariaModel(
                  id: barbearia?.id ?? '',
                  name: nameController.text,
                  address: addressController.text,
                  daysHours: daysHoursController.text,
                  phone: phoneController.text,
                  isActive: isActive,
                );

                try {
                  if (isEditing) {
                    await _adminController.updateBarbearia(newBarbearia);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Barbearia atualizada com sucesso')),
                    );
                  } else {
                    await _adminController.addBarbearia(newBarbearia);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Barbearia adicionada com sucesso')),
                    );
                  }
                  Navigator.of(context).pop();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB22222),
              ),
              child: Text(isEditing ? 'Atualizar' : 'Adicionar'),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleActive(BarbeariaModel barbearia) async {
    try {
      await _adminController.toggleBarbeariaActive(barbearia.id, !barbearia.isActive);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            barbearia.isActive ? 'Barbearia desativada' : 'Barbearia ativada',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  void _deleteBarbearia(BarbeariaModel barbearia) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir esta barbearia?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adminController.deleteBarbearia(barbearia.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Barbearia excluída com sucesso')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao excluir barbearia: $e')),
        );
      }
    }
  }
}
