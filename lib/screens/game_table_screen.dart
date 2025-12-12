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

          // --- NOVO: Lógica para pegar as cartas do jogador da vez ---
          List<dynamic> currentHand = [];
          final players = Map<String, dynamic>.from(data['players']);
          
          // Se tiver alguém jogando e esse alguém tiver cartas...
          if (currentTurn != null && players[currentTurn] != null) {
             final currentPlayer = Map<String, dynamic>.from(players[currentTurn]);
             if (currentPlayer['hand'] != null) {
               currentHand = currentPlayer['hand'];
             }
          }
          int myChips = 0;
          if (data['players'] != null && data['players'][widget.myPlayerId] != null) {
             myChips = data['players'][widget.myPlayerId]['chips'];
          }

          // Define as cartas visuais (ou vazio se der erro)
          String leftCard = currentHand.isNotEmpty ? currentHand[0] : '';
          String rightCard = currentHand.length > 1 ? currentHand[1] : '';
          // A carta do meio (terceira) só aparece depois
          String middleCard = currentHand.length > 2 ? currentHand[2] : ''; 
          // -----------------------------------------------------------

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

              // Área Central: As Cartas REAIS
              Container(
                height: 200,
                width: double.infinity,
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Carta 1 (Esquerda)
                    PlayingCard(cardCode: leftCard), 
                    const SizedBox(width: 20),
                    
                    // Carta do Meio (Vem vazia inicialmente)
                    PlayingCard(cardCode: middleCard),
                    const SizedBox(width: 20),

                    // Carta 2 (Direita)
                    PlayingCard(cardCode: rightCard), 
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
                      Expanded(child: ElevatedButton(onPressed: () {
  // Chama a função de passar
  _gameService.passTurn(widget.roomCode);
}, style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("PASSAR"))),
                      const SizedBox(width: 10),
                      
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            _showBetDialog(myChips); // <--- Chama o Dialog
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          child: const Text("APOSTAR"),
                        ),
                      ),
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
  void _showBetDialog(int maxChips) {
    final TextEditingController _amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Faça sua aposta'),
          content: TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Valor'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Cancelar
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                // Validação simples
                int amount = int.tryParse(_amountController.text) ?? 0;
                if (amount > 0 && amount <= maxChips) {
                  Navigator.pop(context); // Fecha o dialog
                  // CHAMA A LÓGICA DO SERVICE
                  _gameService.makeBet(widget.roomCode, amount);
                }
              },
              child: const Text('APOSTAR!'),
            ),
          ],
        );
      },
    );
  }
}