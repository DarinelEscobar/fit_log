import 'package:flutter/material.dart';
import '../../domain/entities/user_profile.dart';

class EditProfileDialog extends StatefulWidget {
  final UserProfile user;
  const EditProfileDialog({super.key, required this.user});

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late final TextEditingController ageCtl;
  late final TextEditingController genderCtl;
  late final TextEditingController weightCtl;
  late final TextEditingController heightCtl;
  late final TextEditingController levelCtl;
  late final TextEditingController goalCtl;
  late final TextEditingController targetWeightCtl;
  late final TextEditingController targetBfCtl;
  late final TextEditingController targetNeckCtl;
  late final TextEditingController targetShouldersCtl;
  late final TextEditingController targetChestCtl;
  late final TextEditingController targetAbdomenCtl;
  late final TextEditingController targetWaistCtl;
  late final TextEditingController targetGlutesCtl;
  late final TextEditingController targetThighCtl;
  late final TextEditingController targetCalfCtl;
  late final TextEditingController targetArmCtl;
  late final TextEditingController targetForearmCtl;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    ageCtl = TextEditingController(text: u.age.toString());
    genderCtl = TextEditingController(text: u.gender);
    weightCtl = TextEditingController(text: u.weight.toString());
    heightCtl = TextEditingController(text: u.height.toString());
    levelCtl = TextEditingController(text: u.experienceLevel);
    goalCtl = TextEditingController(text: u.goal);
    targetWeightCtl = TextEditingController(text: u.targetWeight.toString());
    targetBfCtl = TextEditingController(text: u.targetBodyFat.toString());
    targetNeckCtl = TextEditingController(text: u.targetNeck.toString());
    targetShouldersCtl = TextEditingController(text: u.targetShoulders.toString());
    targetChestCtl = TextEditingController(text: u.targetChest.toString());
    targetAbdomenCtl = TextEditingController(text: u.targetAbdomen.toString());
    targetWaistCtl = TextEditingController(text: u.targetWaist.toString());
    targetGlutesCtl = TextEditingController(text: u.targetGlutes.toString());
    targetThighCtl = TextEditingController(text: u.targetThigh.toString());
    targetCalfCtl = TextEditingController(text: u.targetCalf.toString());
    targetArmCtl = TextEditingController(text: u.targetArm.toString());
    targetForearmCtl = TextEditingController(text: u.targetForearm.toString());
  }

  @override
  void dispose() {
    ageCtl.dispose();
    genderCtl.dispose();
    weightCtl.dispose();
    heightCtl.dispose();
    levelCtl.dispose();
    goalCtl.dispose();
    targetWeightCtl.dispose();
    targetBfCtl.dispose();
    targetNeckCtl.dispose();
    targetShouldersCtl.dispose();
    targetChestCtl.dispose();
    targetAbdomenCtl.dispose();
    targetWaistCtl.dispose();
    targetGlutesCtl.dispose();
    targetThighCtl.dispose();
    targetCalfCtl.dispose();
    targetArmCtl.dispose();
    targetForearmCtl.dispose();
    super.dispose();
  }

  TextField _field(String label, TextEditingController ctl, {TextInputType? type}) {
    return TextField(
      controller: ctl,
      keyboardType: type,
      decoration: InputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar perfil'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field('Edad', ageCtl, type: TextInputType.number),
            _field('Género', genderCtl),
            _field('Peso', weightCtl, type: TextInputType.number),
            _field('Altura', heightCtl, type: TextInputType.number),
            _field('Nivel', levelCtl),
            _field('Meta', goalCtl),
            const Divider(),
            _field('Peso deseado', targetWeightCtl, type: TextInputType.number),
            _field('BF deseado', targetBfCtl, type: TextInputType.number),
            _field('Cuello deseado', targetNeckCtl, type: TextInputType.number),
            _field('Hombros deseados', targetShouldersCtl, type: TextInputType.number),
            _field('Pecho deseado', targetChestCtl, type: TextInputType.number),
            _field('Abdomen deseado', targetAbdomenCtl, type: TextInputType.number),
            _field('Cintura deseada', targetWaistCtl, type: TextInputType.number),
            _field('Glúteos deseados', targetGlutesCtl, type: TextInputType.number),
            _field('Muslo deseado', targetThighCtl, type: TextInputType.number),
            _field('Pantorrilla deseada', targetCalfCtl, type: TextInputType.number),
            _field('Brazo deseado', targetArmCtl, type: TextInputType.number),
            _field('Antebrazo deseado', targetForearmCtl, type: TextInputType.number),
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
            final p = UserProfile(
              id: widget.user.id,
              age: int.tryParse(ageCtl.text) ?? widget.user.age,
              gender: genderCtl.text,
              weight: double.tryParse(weightCtl.text) ?? widget.user.weight,
              height: double.tryParse(heightCtl.text) ?? widget.user.height,
              experienceLevel: levelCtl.text,
              goal: goalCtl.text,
              targetWeight: double.tryParse(targetWeightCtl.text) ?? widget.user.targetWeight,
              targetBodyFat: double.tryParse(targetBfCtl.text) ?? widget.user.targetBodyFat,
              targetNeck: double.tryParse(targetNeckCtl.text) ?? widget.user.targetNeck,
              targetShoulders: double.tryParse(targetShouldersCtl.text) ?? widget.user.targetShoulders,
              targetChest: double.tryParse(targetChestCtl.text) ?? widget.user.targetChest,
              targetAbdomen: double.tryParse(targetAbdomenCtl.text) ?? widget.user.targetAbdomen,
              targetWaist: double.tryParse(targetWaistCtl.text) ?? widget.user.targetWaist,
              targetGlutes: double.tryParse(targetGlutesCtl.text) ?? widget.user.targetGlutes,
              targetThigh: double.tryParse(targetThighCtl.text) ?? widget.user.targetThigh,
              targetCalf: double.tryParse(targetCalfCtl.text) ?? widget.user.targetCalf,
              targetArm: double.tryParse(targetArmCtl.text) ?? widget.user.targetArm,
              targetForearm: double.tryParse(targetForearmCtl.text) ?? widget.user.targetForearm,
            );
            Navigator.pop(context, p);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
