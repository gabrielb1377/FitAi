import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final nomeController = TextEditingController();
  final pesoController = TextEditingController();
  final alturaController = TextEditingController();
  final idadeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Editar Perfil")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(
              controller: nomeController,
              decoration: const InputDecoration(labelText: "Nome"),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: pesoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Peso"),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: alturaController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Altura"),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: idadeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Idade"),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                final dadosPerfil = {
                  "nome": nomeController.text,
                  "peso": pesoController.text,
                  "altura": alturaController.text,
                  "idade": idadeController.text,
                };

                Navigator.pop(context, dadosPerfil);
              },
              child: const Text("Salvar"),
            ),
          ],
        ),
      ),
    );
  }
}
