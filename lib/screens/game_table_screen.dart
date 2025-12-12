import 'package:flutter/material.dart';
import '../services/game_service.dart';
import '../widgets/playing_card.dart';

class GameTableScreen extends StatefulWidget {
  final String roomCode;
  final String myPlayerId;

  const GameTableScreen({
    super.key, 
    required this.roomCode,
    required this.myPlayerId,
  });

  @override
  State<GameTableScreen> createState() => _GameTableScreenState();
}

class _GameTableScreenState extends State<GameTableScreen> {
  final GameService _gameService = GameService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[800], // Cor de mesa de feltro
      appBar: AppBar(
        title: Text('Mesa ${widget.roomCode}'),
        backgroundColor: Colors.green[900],
      ),
      body: StreamBuilder(
        stream: _gameService.getRoomStream(widget.roomCode),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }

          final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final currentTurn = data['currentTurn'];
          final isMyTurn = currentTurn == widget.myPlayerId;
          final pot = data['pot'] ?? 0;

          return Column(
            children: [
              // Área do Topo: Informações do Jogo
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pote: $pot Fichas', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(isMyTurn ? "SUA VEZ!" : "Vez de outro...", style: TextStyle(color: isMyTurn ? Colors.yellow : Colors.white70)),
                  ],
                ),
              ),

              const Spacer(),

              // Área Central: As Cartas (Placeholder por enquanto)
           Container(
                height: 200,
                width: double.infinity,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Carta 1 (Esquerda)
                    PlayingCard(cardCode: 'E-1'), // Espadas Ás
                    const SizedBox(width: 20),
                    
                    // Carta do Meio (A que o jogador compra) - Por enquanto virada
                    PlayingCard(cardCode: ''), // Vazia = Virada (verso azul)
                    const SizedBox(width: 20),

                    // Carta 2 (Direita)
                    PlayingCard(cardCode: 'C-13'), // Copas Rei
                  ],
                ),
              ),

              const Spacer(),

              // Área Inferior: Botões de Ação
              if (isMyTurn)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Expanded(child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("PASSAR"))),
                      const SizedBox(width: 10),
                      Expanded(child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: Colors.blue), child: const Text("APOSTAR"))),
                    ],
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text("Aguarde sua vez...", style: TextStyle(color: Colors.white)),
                ),
            ],
          );
        },
      ),
    );
  }
}