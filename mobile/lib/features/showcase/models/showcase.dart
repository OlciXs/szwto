import '../../collection/models/monument_card_data.dart';

/// Gablotka gracza (#4): 5 miejsc, kolejne odblokowuje poziom.
class Showcase {
  final int unlockedSlots;
  final int maxSlots;
  final List<ShowcaseSlot> slots;

  Showcase({
    required this.unlockedSlots,
    required this.maxSlots,
    required this.slots,
  });

  factory Showcase.fromJson(Map<String, dynamic> json) => Showcase(
        unlockedSlots: json['unlockedSlots'] as int? ?? 1,
        maxSlots: json['maxSlots'] as int? ?? 5,
        slots: (json['slots'] as List<dynamic>? ?? const [])
            .map((s) => ShowcaseSlot.fromJson(s as Map<String, dynamic>))
            .toList(),
      );

  bool get isEmpty => slots.every((s) => s.monument == null);
}

class ShowcaseSlot {
  final int slot;
  final bool locked;
  final int unlockLevel;
  final MonumentCardData? monument;

  ShowcaseSlot({
    required this.slot,
    required this.locked,
    required this.unlockLevel,
    this.monument,
  });

  factory ShowcaseSlot.fromJson(Map<String, dynamic> json) {
    final monument = json['monument'] as Map<String, dynamic>?;
    return ShowcaseSlot(
      slot: json['slot'] as int,
      locked: json['locked'] as bool? ?? false,
      unlockLevel: json['unlockLevel'] as int? ?? 1,
      monument: monument != null ? MonumentCardData.fromJson(monument) : null,
    );
  }
}
