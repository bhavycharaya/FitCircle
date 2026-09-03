// lib/services/family_service.dart
// FitCircle — Family creation, joining, and member listing
import '../config/supabase_config.dart';
import '../models/family.dart';

class FamilyService {
  final _client = SupabaseConfig.client;

  /// Create a new family circle.
  /// The family code is generated server-side via the SQL function.
  Future<Family> createFamily(String familyName) async {
    final userId = SupabaseConfig.currentUser!.id;

    // Generate unique code via DB function
    final codeResult = await _client.rpc('generate_family_code');
    final familyCode = codeResult as String;

    final result = await _client
        .from('families')
        .insert({
          'family_name': familyName,
          'family_code': familyCode,
          'created_by':  userId,
        })
        .select()
        .single();

    final family = Family.fromJson(result);

    // Automatically add creator as a member
    await _client.from('family_members').insert({
      'family_id': family.id,
      'user_id':   userId,
    });

    return family;
  }

  /// Join a family by code (e.g., FIT-7K92X).
  /// Throws FamilyNotFoundException if the code is invalid.
  Future<Family> joinFamily(String familyCode) async {
    final userId = SupabaseConfig.currentUser!.id;
    final code = familyCode.trim().toUpperCase();

    // Look up the family
    final result = await _client
        .from('families')
        .select()
        .eq('family_code', code)
        .maybeSingle();

    if (result == null) {
      throw FamilyNotFoundException('Family code not found. Please check and try again.');
    }

    final family = Family.fromJson(result);

    // Check not already a member
    final existing = await _client
        .from('family_members')
        .select('id')
        .eq('family_id', family.id)
        .eq('user_id', userId)
        .maybeSingle();

    if (existing != null) {
      throw AlreadyMemberException('You\'re already in this family circle.');
    }

    // Join
    await _client.from('family_members').insert({
      'family_id': family.id,
      'user_id':   userId,
    });

    return family;
  }

  /// Get the current user's family (first family they belong to).
  Future<Family?> getMyFamily() async {
    final userId = SupabaseConfig.currentUser!.id;

    final result = await _client
        .from('family_members')
        .select('families(*)')
        .eq('user_id', userId)
        .maybeSingle();

    if (result == null) return null;
    final familyData = result['families'];
    if (familyData == null) return null;
    return Family.fromJson(familyData as Map<String, dynamic>);
  }

  /// Get all members of the given family, joined with profile data.
  Future<List<FamilyMember>> getFamilyMembers(String familyId) async {
    final results = await _client
        .from('family_members')
        .select('*, profiles(name, avatar_url)')
        .eq('family_id', familyId)
        .order('joined_at');

    return results.map((r) => FamilyMember.fromJson(r)).toList();
  }

  /// Leave the current family.
  Future<void> leaveFamily(String familyId) async {
    final userId = SupabaseConfig.currentUser!.id;
    await _client
        .from('family_members')
        .delete()
        .eq('family_id', familyId)
        .eq('user_id', userId);
  }
}

// ── Custom exceptions ──────────────────────────────────────

class FamilyNotFoundException implements Exception {
  final String message;
  FamilyNotFoundException(this.message);
  @override String toString() => message;
}

class AlreadyMemberException implements Exception {
  final String message;
  AlreadyMemberException(this.message);
  @override String toString() => message;
}
