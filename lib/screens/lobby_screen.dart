import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../services/game_service.dart';
import 'game_table_screen.dart';

class LobbyScreen extends StatefulWidget {
  final String roomCode;
  final String playerName; // Para saber quem sou eu
  final bool isHost;       // Para saber se posso iniciar o jogo

  const LobbyScreen({
    super.key, 
    required this.roomCode, 
    required this.playerName,
    this.isHost = false,
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final GameService _gameService = GameService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sala: ${widget.roomCode}'),
        centerTitle: true,
      ),
      body: StreamBuilder<DatabaseEvent>(
        // Aqui conectamos no cano de dados do Firebase
        stream: _gameService.getRoomStream(widget.roomCode),
        builder: (context, snapshot) {
          
          // 1. Verificando erros ou carregamento
          if (snapshot.hasError) return const Center(child: Text('Erro na conexão'));
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Transformando os dados brutos do Firebase (JSON) em Mapa
          final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final playersMap = Map<String, dynamic>.from(data['players'] ?? {});
          final status = data['status'];

          // Se o jogo começou, vamos navegar para a mesa (Futuro)
          if (status == 'playing') {
            // O uso de addPostFrameCallback evita erro de desenhar tela durante construção
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // Pega o ID do jogador atual para passar para a próxima tela
    String myId = await _gameService.getUserId();
    
    // Verificamos se o widget ainda está montado para evitar erros
    if (context.mounted) {
       // O pushReplacement remove o Lobby da pilha, para não voltar se der "Voltar"
       Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GameTableScreen(
            roomCode: widget.roomCode,
            myPlayerId: myId,
          ),
        ),
      );
    }
  });
          }

          // Convertendo o mapa de jogadores em uma lista para exibir
          final playersList = playersMap.entries.toList();

          return Column(
            children: [
              // Cabeçalho
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Jogadores (${playersList.length})',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),

              // Lista de Jogadores
              Expanded(
                child: ListView.builder(
                  itemCount: playersList.length,
                  itemBuilder: (context, index) {
                    final player = playersList[index].value;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(player['name'][0])),
                        title: Text(player['name']),
                        subtitle: Text('Fichas: ${player['chips']}'),
                        trailing: player['isReady'] == true 
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : const Icon(Icons.hourglass_empty, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),

              // Botão de Iniciar (Só aparece para o Dono da Sala)
              if (widget.isHost)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: ElevatedButton(
                    onPressed: () {
                      _gameService.startGame(widget.roomCode);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 60),
                    ),
                    child: const Text('INICIAR JOGO', style: TextStyle(fontSize: 20)),
                  ),
                )
              else
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'Aguardando o anfitrião iniciar...',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}