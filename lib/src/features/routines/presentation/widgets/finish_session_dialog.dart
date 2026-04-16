import 'package:flutter/material.dart';

typedef FinishSessionResult = ({
  String energy,
  String mood,
  String notes,
});

class FinishSessionDialog extends StatefulWidget {
  final String? initialEnergy;
  final String? initialMood;
  final String? initialNotes;
  final int durationMinutes;
  final double volume;

  static Future<FinishSessionResult?> show(
    BuildContext context, {
    String? initialEnergy,
    String? initialMood,
    String? initialNotes,
    int durationMinutes = 0,
    double volume = 0.0,
  }) =>
      showDialog<FinishSessionResult>(
        context: context,
        barrierDismissible: false,

        builder: (_) => FinishSessionDialog(
          initialEnergy: initialEnergy,
          initialMood: initialMood,
          initialNotes: initialNotes,
          durationMinutes: durationMinutes,
          volume: volume,
        ),
      );

  const FinishSessionDialog({
    super.key,
    required this.initialEnergy,
    required this.initialMood,
    required this.initialNotes,
    required this.durationMinutes,
    required this.volume,
  });

  @override
  State<FinishSessionDialog> createState() => _FinishSessionDialogState();
}

class _FinishSessionDialogState extends State<FinishSessionDialog> {
  String? _energy;
  String? _mood;
  late final TextEditingController _notesCtl;

  static const List<String> _energyScale = [
    '1', '2', '3', '4', '5', '6', '7', '8', '9', '10',
  ];

  @override
  void initState() {
    super.initState();
    _energy = widget.initialEnergy;
    _mood = widget.initialMood;
    _notesCtl = TextEditingController(text: widget.initialNotes ?? '');
  }

  @override
  void dispose() {
    _notesCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canFinish = _energy != null && _mood != null;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF131314),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFF484849).withValues(alpha: 0.1)),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.5),
                blurRadius: 40,
                offset: Offset(0, 20),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCC97FF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFCC97FF).withValues(alpha: 0.2)),
                  ),
                  child: const Icon(Icons.celebration, color: Color(0xFFCC97FF), size: 36),
                ),
                const SizedBox(height: 24),
                const Text(
                  'WORKOUT COMPLETE',
                  style: TextStyle(
                    fontFamily: 'Space Grotesk',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Phenomenal performance, user. Log your vitals.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFADAAAB),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard('DURATION', '${widget.durationMinutes}', 'MIN'),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard('VOLUME', (widget.volume / 1000).toStringAsFixed(1), 'K LBS'),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'ENERGY LEVEL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: Color(0xFFADAAAB),
                          ),
                        ),
                        if (_energy != null)
                          Text(
                            '$_energy/10',
                            style: const TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFCC97FF),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _energyScale.map((val) => _buildEnergyChip(val)).toList(),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'MOOD LEVEL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Color(0xFFADAAAB),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildMoodChip('1', Icons.sentiment_very_dissatisfied),
                        _buildMoodChip('2', Icons.sentiment_dissatisfied),
                        _buildMoodChip('3', Icons.sentiment_neutral),
                        _buildMoodChip('4', Icons.sentiment_satisfied),
                        _buildMoodChip('5', Icons.sentiment_very_satisfied),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'SESSION NOTES',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: Color(0xFFADAAAB),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesCtl,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'How did it feel? Any new PRs?',
                        hintStyle: TextStyle(color: const Color(0xFFADAAAB).withValues(alpha: 0.5)),
                        filled: true,
                        fillColor: const Color(0xFF1A191B),
                        border: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF484849)),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF484849)),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFCC97FF)),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 48),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GestureDetector(
                      onTap: canFinish
                          ? () => Navigator.of(context).pop((
                                energy: _energy!,
                                mood: _mood!,
                                notes: _notesCtl.text,
                              ))
                          : null,
                      child: Opacity(
                        opacity: canFinish ? 1.0 : 0.5,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFCC97FF), Color(0xFF9C48EA)],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(
                                color: Color.fromRGBO(132, 44, 211, 0.25),
                                blurRadius: 32,
                                offset: Offset(0, 12),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'SAVE & FINISH',
                            style: TextStyle(
                              fontFamily: 'Space Grotesk',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: Color(0xFF47007C),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(null),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C2C2D),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'RESUME SESSION',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFADAAAB),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              // Send a special signal, or just pop. We pop null.
                              // Real discard should be done in parent if wanted, but here we just pop null.
                              Navigator.of(context).pop(null);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C2C2D),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                'DISCARD',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFF6B6B).withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String unit) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A191B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF484849).withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Color(0xFFADAAAB),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Space Grotesk',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFCC97FF),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFADAAAB),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyChip(String value) {
    final bool isSelected = _energy == value;
    return GestureDetector(
      onTap: () => setState(() => _energy = value),
      child: Container(
        width: 28,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFCC97FF) : const Color(0xFF1A191B),
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? null : Border.all(color: const Color(0xFF484849).withValues(alpha: 0.2)),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color.fromRGBO(204, 151, 255, 0.3),
                    blurRadius: 20,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? const Color(0xFF0F0F10) : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildMoodChip(String value, IconData icon) {
    final bool isSelected = _mood == value;
    return GestureDetector(
      onTap: () => setState(() => _mood = value),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFCC97FF).withValues(alpha: 0.2) : const Color(0xFF1A191B),
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: const Color(0xFFCC97FF), width: 2)
              : Border.all(color: const Color(0xFF484849).withValues(alpha: 0.2)),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: isSelected ? const Color(0xFFCC97FF) : const Color(0xFFADAAAB),
          size: 28,
        ),
      ),
    );
  }
}
