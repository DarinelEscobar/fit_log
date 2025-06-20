part of 'exercise_tile.dart';
extension ExerciseTileBody on ExerciseTileState {
    Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    final titleColor = isDark ? Colors.white70 : Colors.black87;
    final lastTon = _tonnage(widget.lastLogs ?? []);
    final todayTon = _todayTonnage;
    int? delta;
    if (_todayCompletedLogs.isNotEmpty && lastTon > 0) {
      final raw = ((todayTon - lastTon) / lastTon * 100);
      delta = raw.abs() < 1 ? 0 : raw.round();
    }
    Color deltaColor = Colors.grey.shade400;
    IconData deltaIcon = Icons.remove;
    if (delta != null) {
      if (delta > 0) {
        deltaColor = const Color(0xFF40CF45);
        deltaIcon = Icons.arrow_upward;
      } else if (delta < 0) {
        deltaColor = const Color(0xFFFF2600);
        deltaIcon = Icons.arrow_downward;
      }
    }
    return GestureDetector(
      onTap: widget.onToggle,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: widget.highlightDone ? Colors.blueGrey.shade800 : cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 72, right: 16),
                  title: Text(widget.detail.name,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                          fontSize: 16)),
                  subtitle: widget.detail.description.isNotEmpty
                      ? Text(widget.detail.description,
                          style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54,
                              fontSize: 12))
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(_showChart ? Icons.grid_view : Icons.show_chart, size: 20),
                        tooltip: _showChart ? 'Ocultar gráfica' : 'Mostrar gráfica',
                        onPressed: () => setState(() => _showChart = !_showChart),
                      ),
                      if (delta != null)
                        _deltaBadge(delta, deltaColor, deltaIcon, 'vs última sesión'),
                      if (widget.onSwap != null)
                        IconButton(icon: const Icon(Icons.swap_horiz), onPressed: widget.onSwap),
                      Icon(widget.expanded ? Icons.expand_less : Icons.expand_more),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _showChart
                      ? SizedBox(
                          key: const ValueKey('chart'),
                          height: 160,
                          width: double.infinity,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: MiniLineChart(
                              today: _todayCompletedLogs
                                  .map((e) => e.reps * e.weight)
                                  .toList(),
                              last: widget.lastLogs
                                      ?.map((e) => e.reps * e.weight)
                                      .toList() ??
                                  [],
                              best: widget.bestLogs
                                      ?.map((e) => e.reps * e.weight)
                                      .toList() ??
                                  [],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('empty')),
                ),
                if (delta != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Tonnage: ${todayTon.toStringAsFixed(0)} kg '
                        '(${delta > 0 ? '+' : ''}$delta%)',
                        style: TextStyle(fontSize: 11, color: deltaColor),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _info(
                      'Plan',
                      '${widget.detail.sets}x${widget.detail.reps} @${widget.detail.weight.toStringAsFixed(0)}kg • ${widget.detail.restSeconds}s',
                    ),
                  ),
                ),
                if (widget.expanded) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 12, bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _actionBtn(Icons.remove, _remove),
                        const SizedBox(width: 8),
                        _actionBtn(Icons.add, _add),
                      ],
                    ),
                  ),
                  Column(
                    children: List.generate(_visibleSets, (i) {
                      final done = widget.logsMap['${widget.detail.exerciseId}-${i + 1}']
                              ?.completed ??
                          false;
                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        child: Row(
                          children: [
                            _num(_repCtl[i], 50, 'r', i, !done),
                            const SizedBox(width: 12),
                            _num(_kgCtl[i], 66, 'kg', i, !done),
                            const SizedBox(width: 12),
                            _num(_rirCtl[i], 54, 'R', i, !done),
                            const Spacer(),
                            Icon(
                              done ? Icons.check_circle : Icons.circle,
                              size: 18,
                              color: done ? Colors.green : Colors.grey,
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
          if (_restRemaining > 0)
            Positioned(
              top: 16,
              left: 16,
              child: SizedBox(
                height: 48,
                width: 48,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: 1 - _restRemaining / _restTotal,
                      strokeWidth: 4,
                      color: Colors.amber,
                      backgroundColor: Colors.white12,
                    ),
                    Center(
                      child: Text(
                        '$_restRemaining',
                        style: const TextStyle(fontSize: 12, color: Colors.amber),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
}
