import 'package:flutter/material.dart';

class PlayingCard extends StatelessWidget {
  final String cardCode; // Ex: "C-1", "E-10", "O-12"
  final double width;
  final double height;

  const PlayingCard({
    super.key,
    required this.cardCode,
    this.width = 70,
    this.height = 100,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Separar o naipe do valor
    // Se vier vazio ou erro, mostra carta virada
    if (cardCode.isEmpty || !cardCode.contains('-')) {
      return _buildBack();
    }

    final parts = cardCode.split('-');
    final suitLetter = parts[0]; // C, E, O, P
    final valueStr = parts[1];   // 1 a 13

    // 2. Definir cor e ícone
    Color color = Colors.black;
    String suitIcon = '';
    
    switch (suitLetter) {
      case 'C': // Copas
        color = Colors.red;
        suitIcon = '♥';
        break;
      case 'O': // Ouros
        color = Colors.red;
        suitIcon = '♦';
        break;
      case 'P': // Paus
        color = Colors.black;
        suitIcon = '♣';
        break;
      case 'E': // Espadas
        color = Colors.black;
        suitIcon = '♠';
        break;
    }

    // 3. Traduzir números para Letras (A, J, Q, K)
    String label = valueStr;
    switch (int.tryParse(valueStr)) {
      case 1: label = 'A'; break;
      case 11: label = 'J'; break;
      case 12: label = 'Q'; break;
      case 13: label = 'K'; break;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Topo (Número e naipe pequeno)
          Padding(
            padding: const EdgeInsets.only(left: 4, top: 4),
            child: Align(
              alignment: Alignment.topLeft,
              child: Text('$label$suitIcon', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ),
          
          // Centro (Naipe Grande)
          Text(suitIcon, style: TextStyle(color: color, fontSize: 32)),

          // Base (Número e naipe invertido)
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 4),
            child: Align(
              alignment: Alignment.bottomRight,
              child: Transform.rotate(
                angle: 3.14159, // Gira 180 graus
                child: Text('$label$suitIcon', style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.blue[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2))
        ],
      ),
      child: Center(
        child: Icon(Icons.help_outline, color: Colors.white24, size: 30),
      ),
    );
  }
}