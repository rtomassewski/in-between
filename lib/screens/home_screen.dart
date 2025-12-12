import 'package:flutter/material.dart';
import '../services/game_service.dart';
import 'lobby_screen.dart';

class GameHomeScreen extends StatefulWidget {
  const GameHomeScreen({super.key});

  @override
  State<GameHomeScreen> createState() => _GameHomeScreenState();
}

class _GameHomeScreenState extends State<GameHomeScreen> {
  final GameService _gameService = GameService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();

  void _createNewRoom() async {
    if (_nameController.text.isEmpty) return;
    
    try {
      // 1. Cria a sala no Firebase e recebe o código
      String code = await _gameService.createRoom(_nameController.text);
      print("Sala criada: $code");
      
      if (mounted) {
        // 2. Mostra mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sala $code criada!')));

        // 3. NAVEGA COMO HOST (Dono da sala)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LobbyScreen(
              roomCode: code,
              playerName: _nameController.text,
              isHost: true, // <--- O SEGREDO ESTÁ AQUI (TRUE = MOSTRA BOTÃO)
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  void _joinRoom() async {
    // 1. Validação básica
    if (_nameController.text.isEmpty || _roomController.text.isEmpty) return;

    try {
      // 2. Chama o Firebase e espera (await)
      await _gameService.joinRoom(_roomController.text, _nameController.text);
      
      print("Entrou na sala ${_roomController.text}");

      // 3. Se deu certo, verifica se o widget ainda existe e Navega
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entrou com sucesso!')));

        // AQUI ESTÁ A MÁGICA QUE FALTAVA:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LobbyScreen(
              roomCode: _roomController.text,
              playerName: _nameController.text,
              isHost: false, // Quem entra não é o dono
            ),
          ),
        );
      }
    } catch (e) {
      // Se der erro no Firebase, cai aqui
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acey Deucey Online')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Seu Nome', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createNewRoom,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('CRIAR SALA'),
            ),
            const SizedBox(height: 40),
            const Divider(),
            const SizedBox(height: 20),
            TextField(
              controller: _roomController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Código da Sala (Ex: 1234)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _joinRoom,
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              child: const Text('ENTRAR NA SALA'),
            ),
          ],
        ),
      ),
    );
  }
}