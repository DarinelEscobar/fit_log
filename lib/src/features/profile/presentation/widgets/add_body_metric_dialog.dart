import 'package:flutter/material.dart';
import '../../domain/entities/body_metric.dart';
import '../../domain/entities/user_profile.dart';

class AddBodyMetricDialog extends StatefulWidget {
  final UserProfile user;
  final BodyMetric? last;
  const AddBodyMetricDialog({super.key, required this.user, this.last});

  @override
  State<AddBodyMetricDialog> createState() => _AddBodyMetricDialogState();
}

class _AddBodyMetricDialogState extends State<AddBodyMetricDialog> {
  late final TextEditingController weightCtl;
  late final TextEditingController bfCtl;
  late final TextEditingController neckCtl;
  late final TextEditingController shouldersCtl;
  late final TextEditingController chestCtl;
  late final TextEditingController abdomenCtl;
  late final TextEditingController waistCtl;
  late final TextEditingController glutesCtl;
  late final TextEditingController thighCtl;
  late final TextEditingController calfCtl;
  late final TextEditingController armCtl;
  late final TextEditingController forearmCtl;
  late final TextEditingController ageCtl;

  @override
  void initState() {
    super.initState();
    final last = widget.last;
    weightCtl = TextEditingController(text: last?.weight.toString() ?? '');
    bfCtl = TextEditingController(text: last?.bodyFat.toString() ?? '');
    neckCtl = TextEditingController(text: last?.neck.toString() ?? '');
    shouldersCtl = TextEditingController(text: last?.shoulders.toString() ?? '');
    chestCtl = TextEditingController(text: last?.chest.toString() ?? '');
    abdomenCtl = TextEditingController(text: last?.abdomen.toString() ?? '');
    waistCtl = TextEditingController(text: last?.waist.toString() ?? '');
    glutesCtl = TextEditingController(text: last?.glutes.toString() ?? '');
    thighCtl = TextEditingController(text: last?.thigh.toString() ?? '');
    calfCtl = TextEditingController(text: last?.calf.toString() ?? '');
    armCtl = TextEditingController(text: last?.arm.toString() ?? '');
    forearmCtl = TextEditingController(text: last?.forearm.toString() ?? '');
    ageCtl = TextEditingController(text: widget.user.age.toString());
  }

  @override
  void dispose() {
    weightCtl.dispose();
    bfCtl.dispose();
    neckCtl.dispose();
    shouldersCtl.dispose();
    chestCtl.dispose();
    abdomenCtl.dispose();
    waistCtl.dispose();
    glutesCtl.dispose();
    thighCtl.dispose();
    calfCtl.dispose();
    armCtl.dispose();
    forearmCtl.dispose();
    ageCtl.dispose();
    super.dispose();
  }

  TextField _field(String label, TextEditingController ctl, double? prev,
      {bool intType = false}) {
    final prevTxt = prev != null ? ' (último $prev)' : '';
    return TextField(
      controller: ctl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: '$label$prevTxt'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final last = widget.last;
    return AlertDialog(
      title: const Text('Registrar métricas'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field('Peso', weightCtl, last?.weight),
            _field('% Grasa', bfCtl, last?.bodyFat),
            _field('Cuello', neckCtl, last?.neck),
            _field('Hombros', shouldersCtl, last?.shoulders),
            _field('Pecho', chestCtl, last?.chest),
            _field('Abdomen', abdomenCtl, last?.abdomen),
            _field('Cintura', waistCtl, last?.waist),
            _field('Glúteos', glutesCtl, last?.glutes),
            _field('Muslo', thighCtl, last?.thigh),
            _field('Pantorrilla', calfCtl, last?.calf),
            _field('Brazo', armCtl, last?.arm),
            _field('Antebrazo', forearmCtl, last?.forearm),
            TextField(
              controller: ageCtl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Edad'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            final last = widget.last;
            final metric = BodyMetric(
              date: DateTime.now(),
              weight: double.tryParse(weightCtl.text) ?? last?.weight ?? 0,
              bodyFat: double.tryParse(bfCtl.text) ?? last?.bodyFat ?? 0,
              neck: double.tryParse(neckCtl.text) ?? last?.neck ?? 0,
              shoulders:
                  double.tryParse(shouldersCtl.text) ?? last?.shoulders ?? 0,
              chest: double.tryParse(chestCtl.text) ?? last?.chest ?? 0,
              abdomen: double.tryParse(abdomenCtl.text) ?? last?.abdomen ?? 0,
              waist: double.tryParse(waistCtl.text) ?? last?.waist ?? 0,
              glutes: double.tryParse(glutesCtl.text) ?? last?.glutes ?? 0,
              thigh: double.tryParse(thighCtl.text) ?? last?.thigh ?? 0,
              calf: double.tryParse(calfCtl.text) ?? last?.calf ?? 0,
              arm: double.tryParse(armCtl.text) ?? last?.arm ?? 0,
              forearm: double.tryParse(forearmCtl.text) ?? last?.forearm ?? 0,
              age: int.tryParse(ageCtl.text) ?? widget.user.age,
            );
            Navigator.pop(context, metric);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
