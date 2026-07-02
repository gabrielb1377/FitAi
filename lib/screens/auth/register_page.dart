import 'package:flutter/material.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Criar Conta"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: "Nome",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 15),

            TextField(
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 15),

            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Senha",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 15),

            TextField(
              decoration: InputDecoration(
                labelText: "Peso",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 15),

            TextField(
              decoration: InputDecoration(
                labelText: "Altura",
                border: OutlineInputBorder(),
              ),
            ),

            SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {},
                child: Text("Criar Conta"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}