import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GameService {
  // Instância do Database e Auth
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Retorna o ID do usuário atual
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
    String roomCode = (1000 + Random().nextInt(9000)).toString();

    Map<String, dynamic> roomData = {
      'hostId': userId,
      'status': 'waiting',
      'pot': 0,
      'players': {
        userId: {
          'name': playerName,
          'chips': 1000,
          'hand': null,
          'isReady': false,
        }
      }
    };

    await _db.child('rooms').child(roomCode).set(roomData);
    return roomCode;
  }

  // --- FUNÇÃO 2: ENTRAR NA SALA ---
  Future<void> joinRoom(String roomCode, String playerName) async {
    String userId = await getUserId();
    final snapshot = await _db.child('rooms').child(roomCode).get();
    
    if (snapshot.exists) {
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

  // --- FUNÇÃO 3: OUVIR O JOGO ---
  Stream<DatabaseEvent> getRoomStream(String roomCode) {
    return _db.child('rooms').child(roomCode).onValue;
  }

  // --- FUNÇÃO 4: INICIAR O JOGO ---
  Future<void> startGame(String roomCode) async {
    List<String> deck = [];
    List<String> suits = ['C', 'E', 'O', 'P'];
    for (var suit in suits) {
      for (var i = 1; i <= 13; i++) {
        deck.add('$suit-$i');
      }
    }
    deck.shuffle();

    final snapshot = await _db.child('rooms/$roomCode/players').get();
    if (!snapshot.exists) return;
    
    Map players = snapshot.value as Map;
    String firstPlayerId = players.keys.first;

    String card1 = deck.removeLast();
    String card2 = deck.removeLast();

    await _db.child('rooms/$roomCode').update({
      'status': 'playing',
      'deck': deck,
      'currentTurn': firstPlayerId,
    });

    await _db.child('rooms/$roomCode/players/$firstPlayerId').update({
      'hand': [card1, card2],
      'state': 'betting'
    });
  } // <--- AQUI FECHA O START GAME

  // --- FUNÇÃO 5: PASSAR A VEZ (Agora do lado de fora, correto) ---
  Future<void> passTurn(String roomCode) async {
    final snapshot = await _db.child('rooms/$roomCode').get();
    if (!snapshot.exists) return;
    
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final players = Map<String, dynamic>.from(data['players']);
    final currentTurn = data['currentTurn'];
    
    List<String> deck = List<String>.from(data['deck'] ?? []);

    List<String> playerIds = players.keys.toList();
    playerIds.sort(); // Garante a ordem correta
    
    int currentIndex = playerIds.indexOf(currentTurn);
    if (currentIndex == -1) currentIndex = 0;

    int nextIndex = (currentIndex + 1) % playerIds.length; 
    String nextPlayerId = playerIds[nextIndex];

    if (deck.length < 10) {
      List<String> suits = ['C', 'E', 'O', 'P'];
      deck = [];
      for (var suit in suits) {
        for (var i = 1; i <= 13; i++) {
          deck.add('$suit-$i');
        }
      }
      deck.shuffle();
    }

    String c1 = deck.removeLast();
    String c2 = deck.removeLast();

    await _db.child('rooms/$roomCode').update({
      'currentTurn': nextPlayerId,
      'deck': deck,
      'players/$nextPlayerId/hand': [c1, c2],
      'players/$nextPlayerId/state': 'betting', 
    });
  }
int _getCardValue(String cardCode) {
    return int.parse(cardCode.split('-')[1]);
  }

  // --- FUNÇÃO 6: FAZER APOSTA ---
  Future<void> makeBet(String roomCode, int betAmount) async {
    // 1. Pegar dados do banco
    final snapshot = await _db.child('rooms/$roomCode').get();
    if (!snapshot.exists) return;
    
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final currentTurn = data['currentTurn'];
    final players = Map<String, dynamic>.from(data['players']);
    final currentPlayer = Map<String, dynamic>.from(players[currentTurn]);
    
    // Pega as cartas da mão atual
    List<dynamic> hand = currentPlayer['hand'];
    String card1 = hand[0];
    String card2 = hand[1];
    
    // Pega o baralho
    List<String> deck = List<String>.from(data['deck']);
    
    // 2. Sacar a TERCEIRA carta (A carta do destino)
    String card3 = deck.removeLast();
    
    // 3. A Lógica Matemática (Ganhou ou Perdeu?)
    int v1 = _getCardValue(card1);
    int v2 = _getCardValue(card2);
    int v3 = _getCardValue(card3);
    
    int min = v1 < v2 ? v1 : v2;
    int max = v1 > v2 ? v1 : v2;
    
    // REGRA: Tem que ser MAIOR que o menor E MENOR que o maior.
    // Se for igual (na trave), perde.
    bool playerWon = v3 > min && v3 < max;
    
    // 4. Atualizar Saldo (Fichas)
    int currentPot = data['pot'] ?? 0;
    int playerChips = currentPlayer['chips'];
    
    if (playerWon) {
      // Ganhou: Tira do pote e dá pro jogador
      // (Se o pote for menor que a aposta, ganha só o que tem no pote)
      int winAmount = (betAmount > currentPot) ? currentPot : betAmount;
      currentPot -= winAmount;
      playerChips += winAmount;
    } else {
      // Perdeu: Tira do jogador e põe no pote
      playerChips -= betAmount;
      currentPot += betAmount;
    }
    
    // 5. Salvar TUDO no Firebase e MOSTRAR a carta 3
    // Nota: Não passamos a vez ainda, para dar tempo do jogador ver a carta
    await _db.child('rooms/$roomCode').update({
      'pot': currentPot,
      'deck': deck,
      'players/$currentTurn/chips': playerChips,
      'players/$currentTurn/hand': [card1, card2, card3], // Agora tem 3 cartas!
    });
    
    // 6. Pequeno atraso para ver o resultado, depois passa a vez automático
    await Future.delayed(const Duration(seconds: 3));
    await passTurn(roomCode);
  }
} 