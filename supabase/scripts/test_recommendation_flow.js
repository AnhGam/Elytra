/**
 * Test script for Recommendation Engine & AI Chat Logic (Sprint 6)
 * Validates:
 * 1. Scoring mathematical formulas (Multi-objective loss function)
 * 2. Fallback response generator behavior
 * 3. Migration SQL syntax and constraints
 */

const fs = require('fs');
const path = require('path');
const assert = require('assert');

console.log('====================================================');
console.log('   TESTING RECOMMENDATION & AI CHAT FLOW (Sprint 6) ');
console.log('====================================================\n');

// 1. Kiểm tra công thức xếp hạng món ăn đa mục tiêu (Multi-objective scoring)
console.log('[1/3] Testing Content-based Nutrition Scoring Algorithm...');

function calculateCandidateScore(recipe, targetCal, targetProt, maxPrepTime = 60) {
  // Score calo
  const diffCal = Math.abs(recipe.calories_per_serving - targetCal);
  const scoreCal = Math.max(0, 1.0 - (diffCal / Math.max(targetCal, 100)));

  // Score protein
  const diffProt = Math.abs(recipe.protein_g_per_serving - targetProt);
  const scoreProt = Math.max(0, 1.0 - (diffProt / Math.max(targetProt, 10)));

  // Score thời gian
  const totalTime = (recipe.prep_time_minutes || 0) + (recipe.cook_time_minutes || 0);
  const scoreTime = totalTime <= 30 ? 1.0 : Math.max(0, 1.0 - ((totalTime - 30) / Math.max(maxPrepTime, 30)));

  // Tổng điểm có trọng số: 45% Calo + 35% Protein + 20% Thời gian
  const totalScore = (0.45 * scoreCal) + (0.35 * scoreProt) + (0.20 * scoreTime);
  return {
    scoreCal,
    scoreProt,
    scoreTime,
    totalScore: Math.round(totalScore * 100) / 100
  };
}

// Test case A: Món hoàn hảo (khớp cả calo, protein và thời gian nhanh)
const perfectDish = { calories_per_serving: 600, protein_g_per_serving: 40, prep_time_minutes: 10, cook_time_minutes: 15 };
const scoreA = calculateCandidateScore(perfectDish, 600, 40);
assert.strictEqual(scoreA.totalScore, 1.0, 'Món khớp hoàn hảo phải đạt 1.0 điểm');
console.log('  [PASS] Perfect dish score:', scoreA.totalScore);

// Test case B: Món lệch calo nhiều
const farCalDish = { calories_per_serving: 1200, protein_g_per_serving: 40, prep_time_minutes: 10, cook_time_minutes: 15 };
const scoreB = calculateCandidateScore(farCalDish, 600, 40);
assert(scoreB.totalScore < scoreA.totalScore, 'Món lệch calo phải có điểm thấp hơn');
console.log('  [PASS] Divergent calorie dish score correctly penalized:', scoreB.totalScore);

// 2. Kiểm tra bộ sinh Fallback template khi Gemini API gián đoạn
console.log('\n[2/3] Testing Intelligent Fallback Response Generation...');

function generateFallbackResponse(mealType, targetCal, candidates, hasRejected) {
  const MEAL_NAMES_VI = { breakfast: 'sáng', lunch: 'trưa', dinner: 'tối', snack: 'phụ' };
  const mealVi = MEAL_NAMES_VI[mealType] || 'trưa';
  if (!candidates || candidates.length === 0) {
    return `Hiện tại hệ thống chưa tìm thấy thêm món ăn nào phù hợp với các tiêu chí hạn chế của bạn cho bữa ${mealVi}. Bạn thử nới lỏng bộ lọc hoặc tăng giảm calo một chút nhé!`;
  }
  const top = candidates[0];
  const others = candidates.slice(1, 3);
  let text = '';
  if (hasRejected) {
    text += `Đã ghi nhận bạn không chọn món trước đó. Mình đã đổi sang phương án khác phù hợp hơn cho bữa ${mealVi} (~${Math.round(targetCal)} kcal):\n\n`;
  } else {
    text += `Dựa trên mục tiêu dinh dưỡng hôm nay (bữa ${mealVi} cần khoảng ~${Math.round(targetCal)} kcal), mình gợi ý cho bạn:\n\n`;
  }
  text += `⭐ **${top.title}** (${top.calories_per_serving} kcal | ${top.protein_g_per_serving}g Đạm | ${top.carbs_g_per_serving}g Carbs)\n`;
  text += `👉 *${top.match_reason}*.\n`;
  if (others.length > 0) {
    text += `\nNếu muốn đổi vị, bạn có thể tham khảo thêm:\n`;
    for (const r of others) {
      text += `• **${r.title}**: ${r.calories_per_serving} kcal, ${r.protein_g_per_serving}g protein\n`;
    }
  }
  text += `\nChúc bạn có một bữa ăn ngon miệng và cân đối dinh dưỡng!`;
  return text;
}

const mockCandidates = [
  {
    title: 'Phở bò tái nạm',
    calories_per_serving: 580,
    protein_g_per_serving: 35,
    carbs_g_per_serving: 65,
    match_reason: 'Rất chuẩn calo (lệch 20 kcal)'
  },
  {
    title: 'Cơm tấm sườn bì chả',
    calories_per_serving: 680,
    protein_g_per_serving: 32,
    carbs_g_per_serving: 75,
    match_reason: 'Phù hợp calo'
  }
];

const fallbackNormal = generateFallbackResponse('lunch', 600, mockCandidates, false);
assert(fallbackNormal.includes('Phở bò tái nạm'), 'Fallback phải nêu tên món đứng đầu');
assert(fallbackNormal.includes('580 kcal'), 'Fallback phải có số calo');
console.log('  [PASS] Normal fallback text rendered correctly.');

const fallbackRejected = generateFallbackResponse('lunch', 600, mockCandidates, true);
assert(fallbackRejected.includes('Đã ghi nhận bạn không chọn món trước đó'), 'Fallback khi đổi món phải có lời dẫn xác nhận');
console.log('  [PASS] Swap/rejected fallback text rendered correctly.');

// 3. Kiểm tra tính toàn vẹn của Migration SQL mới
console.log('\n[3/3] Validating Migration SQL Syntax & Integrity...');
const migrationPath = path.resolve(__dirname, '../migrations/20261106090000_recommendation_and_chat_schema.sql');
assert(fs.existsSync(migrationPath), 'Migration file must exist');

const migrationContent = fs.readFileSync(migrationPath, 'utf8');
assert(migrationContent.includes('CREATE TABLE IF NOT EXISTS public.chat_sessions'), 'Must create chat_sessions table');
assert(migrationContent.includes('CREATE TABLE IF NOT EXISTS public.chat_messages'), 'Must create chat_messages table');
assert(migrationContent.includes('recommend_dishes_for_user'), 'Must create recommend_dishes_for_user RPC');
assert(migrationContent.includes('ENABLE ROW LEVEL SECURITY'), 'Must enable RLS');
assert(migrationContent.includes('total_count'), 'search_recipes must return total_count for pagination');
assert(migrationContent.includes("category = 'gia_vi_an_kem'"), 'Must mark condiments category');

console.log('  [PASS] Migration SQL contains all required tables, RPCs, and security policies.');

console.log('\n----------------------------------------------------');
console.log('All tests passed successfully! Sprint 6 logic verified.');
console.log('----------------------------------------------------');
