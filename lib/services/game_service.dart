import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GameService {
  // Instância do Database e Auth
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Retorna o ID do usuário atual (cria anônimo se não existir)
  Future<String> getUserId() async {
    User? user = _auth.currentUser;
    if (user == null) {
      UserCredential userCredential = await _auth.signInAnonymously();
      user = userCredential.user;
    }
    return user!.uid;
  }

  // --- FUNÇÃO 1: CRIAR UMA SALA ---
  Future<String> createRoom(String playerName) async {
    String userId = await getUserId();
    
    // Gera um código de sala aleatório (ex: 4521)
    String roomCode = (1000 + Random().nextInt(9000)).toString();

    // Estrutura inicial da sala no Banco de Dados
    Map<String, dynamic> roomData = {
      'hostId': userId,
      'status': 'waiting', // waiting, playing, finished
      'pot': 0, // Aposta total na mesa
      'players': {
        userId: {
          'name': playerName,
          'chips': 1000, // Fichas iniciais
          'hand': null, // Cartas na mão
          'isReady': false,
        }
      }
    };

    // Salva no caminho "rooms/4521"
    await _db.child('rooms').child(roomCode).set(roomData);
    
    return roomCode;
  }

  // --- FUNÇÃO 2: ENTRAR NA SALA ---
  Future<void> joinRoom(String roomCode, String playerName) async {
    String userId = await getUserId();

    // Verifica se a sala existe
    final snapshot = await _db.child('rooms').child(roomCode).get();
    
    if (snapshot.exists) {
      // Adiciona o jogador na lista
      await _db.child('rooms/$roomCode/players/$userId').set({
        'name': playerName,
        'chips': 1000,
        'hand': null,
        'isReady': false,
      });
    } else {
      throw Exception('Sala não encontrada!');
    }
  }

  // --- FUNÇÃO 3: OUVIR O JOGO (STREAM) ---
  // Isso permite que a tela atualize SOZINHA quando algo mudar no banco
  Stream<DatabaseEvent> getRoomStream(String roomCode) {
    return _db.child('rooms').child(roomCode).onValue;
  }
  Future<void> startGame(String roomCode) async {
    // 1. Criar um baralho simples (52 cartas)
    // Vamos usar Strings para facilitar: "C-1" (Copas Ás), "E-13" (Espadas Rei)
    // C=Copas, E=Espadas, O=Ouros, P=Paus
    List<String> deck = [];
    List<String> suits = ['C', 'E', 'O', 'P'];
    for (var suit in suits) {
      for (var i = 1; i <= 13; i++) {
        deck.add('$suit-$i');
      }
    }
    deck.shuffle(); // Embaralha

    // 2. Pegar o ID do primeiro jogador para começar
    final snapshot = await _db.child('rooms/$roomCode/players').get();
    if (!snapshot.exists) return;
    
    Map players = snapshot.value as Map;
    String firstPlayerId = players.keys.first; // Pega o primeiro ID da lista

    // 3. Atualizar o banco de dados
    await _db.child('rooms/$roomCode').update({
      'status': 'playing',   // Muda o status para todos saberem
      'deck': deck,          // Salva o baralho embaralhado
      'currentTurn': firstPlayerId, // Define de quem é a vez
      'cardsOnTable': [],    // Limpa a mesa
    });
  }
}