import 'package:flutter/material.dart';
import '../pages/pokemon/enhanced_pokemon_detail_page.dart';

/// 显示宝可梦详情 bottom sheet（复用增强详情页）
void showPokemonDetailSheet(BuildContext context, int ndex, {bool shinyByDefault = false}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => EnhancedPokemonDetailPage(
        ndex: ndex,
        initialShiny: shinyByDefault,
      ),
    ),
  );
}
