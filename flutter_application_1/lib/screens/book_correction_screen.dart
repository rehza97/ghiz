import 'package:flutter/material.dart';
import '../models/book_correction_guide.dart';
import '../models/book_movement.dart';
import '../models/shelf_correction_state.dart';

/// Écran de correction des livres mal placés
class BookCorrectionScreen extends StatefulWidget {
  final BookCorrectionGuide correctionGuide;
  final String shelfId;
  final String libraryId;

  const BookCorrectionScreen({
    super.key,
    required this.correctionGuide,
    required this.shelfId,
    required this.libraryId,
  });

  @override
  State<BookCorrectionScreen> createState() => _BookCorrectionScreenState();
}

class _BookCorrectionScreenState extends State<BookCorrectionScreen> {
  late ShelfCorrectionState _correctionState;

  @override
  void initState() {
    super.initState();
    _initializeCorrectionState();
  }

  void _initializeCorrectionState() {
    _correctionState = ShelfCorrectionState(
      currentBooks: widget.correctionGuide.currentOrder,
      remainingMoves: List.from(widget.correctionGuide.requiredMoves),
      movesMade: 0,
      progressPercentage: 0,
      correctionComplete: widget.correctionGuide.isInCorrectOrder,
      lastUpdated: DateTime.now(),
      completedMoves: [],
    );
  }

  void _markMoveAsCompleted(String bookBarcode) {
    setState(() {
      _correctionState = _correctionState.markMoveAsCompleted(bookBarcode);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mouvement effectué ✓'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    if (_correctionState.correctionComplete) {
      _showCompletionDialog();
    }
  }

  void _undoLastMove() {
    if (_correctionState.completedMoves.isEmpty) return;

    setState(() {
      _correctionState = _correctionState.undoLastMove();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mouvement annulé'),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _resetCorrection() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser'),
        content: const Text('Êtes-vous sûr de vouloir recommencer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _correctionState = _correctionState.reset();
              });
            },
            child: const Text('Oui'),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Correction Complète! 🎉'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tous les livres sont maintenant en bon ordre.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '${_correctionState.movesMade} mouvements effectués',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Correction des Livres'),
        backgroundColor: const Color(0xFF38ada9),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barre de progression
          _buildProgressBar(),

          // Informations du rayon
          _buildShelfInfo(),

          // Liste des mouvements requis
          Expanded(child: _buildMovementsList()),

          // Boutons d'action
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _correctionState.statusText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                '${_correctionState.progressPercentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.cyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _correctionState.progressPercentage / 100,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _correctionState.correctionComplete
                    ? Colors.green
                    : Colors.cyan,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _correctionState.detailedStatus,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildShelfInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Statut du Rayon',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                widget.correctionGuide.accuracyDescription,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _correctionState.correctionComplete
                  ? Colors.green
                  : Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  '${_correctionState.correctBooksCount}/${_correctionState.currentBooks.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Text(
                  'correct',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementsList() {
    if (_correctionState.remainingMoves.isEmpty &&
        _correctionState.completedMoves.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'Tous les livres sont en bon ordre!',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Mouvements restants
        if (_correctionState.remainingMoves.isNotEmpty) ...[
          const Text(
            'Mouvements à effectuer',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          ..._correctionState.remainingMoves.map(
            (move) => _buildMovementCard(move, isCompleted: false),
          ),
        ],

        if (_correctionState.remainingMoves.isNotEmpty &&
            _correctionState.completedMoves.isNotEmpty)
          const Divider(height: 32),

        // Mouvements complétés
        if (_correctionState.completedMoves.isNotEmpty) ...[
          const Text(
            'Mouvements effectués',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          ..._correctionState.completedMoves.map(
            (move) => _buildMovementCard(move, isCompleted: true),
          ),
        ],
      ],
    );
  }

  Widget _buildMovementCard(BookMovement move, {required bool isCompleted}) {
    final color = _getPriorityColor(move.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.grey[100] : Colors.white,
        border: Border.all(
          color: isCompleted ? Colors.grey[300]! : Color(color),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Priorité badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Color(color),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    move.priorityDescription,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                // Direction
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    move.directionSymbol,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Titre du livre
            Text(
              move.bookTitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isCompleted ? Colors.grey[400] : Colors.black,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Instruction
            Text(
              move.instruction,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),

            // Position
            Row(
              children: [
                Chip(
                  label: Text('Position ${move.fromPosition}'),
                  labelStyle: const TextStyle(fontSize: 11),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.blue[100],
                ),
                const SizedBox(width: 8),
                Icon(
                  move.direction == MovementDirection.right
                      ? Icons.arrow_forward
                      : Icons.arrow_back,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Chip(
                  label: Text('Position ${move.toPosition}'),
                  labelStyle: const TextStyle(fontSize: 11),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Colors.green[100],
                ),
              ],
            ),

            if (!isCompleted)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _markMoveAsCompleted(move.bookBarcode),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(color),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text(
                      'Marquer comme effectué',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_correctionState.completedMoves.isNotEmpty)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _undoLastMove,
                icon: const Icon(Icons.undo),
                label: const Text('Annuler'),
              ),
            ),
          if (_correctionState.completedMoves.isNotEmpty)
            const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _resetCorrection,
              icon: const Icon(Icons.refresh),
              label: const Text('Réinitialiser'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('Fermer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF38ada9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getPriorityColor(int priority) {
    switch (priority) {
      case 0:
        return 0xFFF44336; // Rouge - Critique
      case 1:
        return 0xFFFF5722; // Orange foncé
      case 2:
        return 0xFFFFC107; // Orange
      case 3:
        return 0xFF4CAF50; // Vert
      default:
        return 0xFF2196F3; // Bleu
    }
  }
}
