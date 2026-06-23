enum WeightDisplayUnit {
  kg('kg', 'KG'),
  lb('lb', 'LB');

  const WeightDisplayUnit(this.storageValue, this.label);

  final String storageValue;
  final String label;

  static WeightDisplayUnit fromStorageValue(Object? value) {
    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == lb.storageValue || normalized == 'lbs') {
      return lb;
    }
    return kg;
  }
}
