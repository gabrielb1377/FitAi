import 'package:flutter/material.dart';

import '../../models/corrida_model.dart';
import '../../services/storage_service.dart';

class HistoricoCorridasPage extends StatefulWidget {
  const HistoricoCorridasPage({super.key});

  @override
  State<HistoricoCorridasPage> createState() =>
      _HistoricoCorridasPageState();
}

class _HistoricoCorridasPageState
    extends State<HistoricoCorridasPage> {

  List<CorridaModel> corridas = [];

  @override
  void initState() {
    super.initState();
    carregar();
  }

  Future<void> carregar() async {
    corridas =
        await StorageService.carregarCorridas();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Histórico"),
      ),
      body: ListView.builder(
        itemCount: corridas.length,
        itemBuilder: (context, index) {

          final corrida = corridas[index];

          return Card(
            child: ListTile(
              leading:
                  const Icon(Icons.directions_run),

              title: Text(
                "${corrida.distancia.toStringAsFixed(2)} km",
              ),

              subtitle: Text(
                "${corrida.segundos} segundos",
              ),
            ),
          );
        },
      ),
    );
  }
}