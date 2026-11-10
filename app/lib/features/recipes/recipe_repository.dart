import 'package:elytra/features/recipes/recipe.dart';
import 'package:elytra/main.dart';
import 'package:flutter/foundation.dart';

/// Số món tối đa tải về một lần từ RPC `search_recipes`.
const int kRecipeFetchLimit = 100;

/// Nguồn dữ liệu cho các màn hình món ăn (có thể thay bằng bản giả khi test).
abstract class RecipeRepository {
  Future<List<Recipe>> fetchAll();
  Future<RecipeDetail?> fetchDetail(String id);
  Future<UserNutritionProfile?> fetchProfile();
  Future<List<Allergen>> fetchAllergens();
  Future<Set<int>> fetchUserAllergenIds();
  Future<void> saveUserAllergenIds(Set<int> ids);
}

final _uuidRe = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

/// Bản dùng Supabase. Không giữ trạng thái; constructor không chạm `supabase`
/// (widget test dựng app khi chưa khởi tạo Supabase).
class SupabaseRecipeRepository implements RecipeRepository {
  SupabaseRecipeRepository();

  String get _uid => supabase.auth.currentUser!.id;

  @override
  Future<List<Recipe>> fetchAll() async {
    final rows = await supabase
        .rpc('search_recipes', params: {'p_limit': kRecipeFetchLimit}) as List;
    if (rows.length >= kRecipeFetchLimit) {
      debugPrint('search_recipes trả $kRecipeFetchLimit món, có thể thiếu món');
    }
    return [
      for (final r in rows) Recipe.fromSearchRow(Map<String, dynamic>.from(r as Map)),
    ];
  }

  @override
  Future<RecipeDetail?> fetchDetail(String id) async {
    if (!_uuidRe.hasMatch(id)) return null; // id rác: khỏi gọi mạng
    final row = await supabase
        .from('recipes')
        .select('*, recipe_ingredients(*), recipe_allergens(allergen_id, via_condiment)')
        .eq('id', id)
        .eq('is_verified', true)
        .maybeSingle();
    return row == null ? null : RecipeDetail.fromRow(row);
  }

  @override
  Future<UserNutritionProfile?> fetchProfile() async {
    final row = await supabase
        .from('profiles')
        .select('target_calories, target_protein_g, target_carbs_g, target_fat_g, target_fiber_g')
        .eq('id', _uid)
        .maybeSingle();
    return row == null ? null : UserNutritionProfile.fromRow(row);
  }

  @override
  Future<List<Allergen>> fetchAllergens() async {
    final rows =
        await supabase.from('allergens').select('id, name_vi, description').order('id');
    return [for (final r in rows) Allergen.fromRow(r)];
  }

  @override
  Future<Set<int>> fetchUserAllergenIds() async {
    final rows = await supabase
        .from('user_allergens')
        .select('allergen_id')
        .eq('user_id', _uid);
    return {for (final r in rows) (r['allergen_id'] as num).toInt()};
  }

  @override
  Future<void> saveUserAllergenIds(Set<int> ids) async {
    final uid = _uid;
    final table = supabase.from('user_allergens');
    if (ids.isEmpty) {
      // Xóa hết; không dùng not-in với danh sách rỗng.
      await table.delete().eq('user_id', uid);
      return;
    }
    await table
        .delete()
        .eq('user_id', uid)
        .not('allergen_id', 'in', ids.toList());
    await table.upsert([
      for (final id in ids) {'user_id': uid, 'allergen_id': id},
    ]);
  }
}

final recipeRepo = SupabaseRecipeRepository();
