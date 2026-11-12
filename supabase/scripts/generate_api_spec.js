/**
 * Elytra API Specification & Release Bundle Generator
 * Generates OpenAPI 3.0.3 specification (JSON & YAML) and packages API documentation.
 * Zero external dependencies (uses standard Node.js libraries).
 */

const fs = require('fs');
const path = require('path');

const ROOT_DIR = path.resolve(__dirname, '../../');
const OUTPUT_DIR = path.join(ROOT_DIR, 'dist', 'api');
const DOCS_DIR = path.join(ROOT_DIR, 'docs');

const openApiSpec = {
  openapi: "3.0.3",
  info: {
    title: "Elytra Nutrition & Recipe Assistant API",
    version: "1.2.0",
    description: "Tài liệu API chính thức của hệ thống Elytra: Tính toán dinh dưỡng, Gợi ý món ăn thông minh (Sprint 6), Chat AI Gemini và Nhật ký bữa ăn.",
    contact: {
      name: "Elytra Engineering Team",
      url: "https://github.com/Elytra-Project/Elytra"
    }
  },
  servers: [
    {
      url: "https://{project-ref}.supabase.co/functions/v1",
      description: "Supabase Edge Functions Production",
      variables: {
        "project-ref": {
          default: "your-supabase-ref",
          description: "Mã định danh dự án Supabase"
        }
      }
    },
    {
      url: "https://{project-ref}.supabase.co/rest/v1",
      description: "PostgREST Database RPC",
      variables: {
        "project-ref": {
          default: "your-supabase-ref"
        }
      }
    }
  ],
  components: {
    securitySchemes: {
      BearerAuth: {
        type: "http",
        scheme: "bearer",
        bearerFormat: "JWT",
        description: "User JWT lấy sau khi đăng nhập Supabase Auth"
      },
      ApiKeyAuth: {
        type: "apiKey",
        in: "header",
        name: "apikey",
        description: "Supabase Anon Key"
      }
    },
    schemas: {
      ErrorResponse: {
        type: "object",
        properties: {
          error: {
            type: "object",
            properties: {
              code: { type: "string", example: "VALIDATION_ERROR" },
              message: { type: "string", example: "Tuổi phải nằm trong khoảng cho phép" },
              field: { type: "string", example: "age" }
            },
            required: ["code", "message"]
          }
        }
      },
      MacroNutrients: {
        type: "object",
        properties: {
          protein_g: { type: "number", example: 130.0 },
          fat_g: { type: "number", example: 55.3 },
          carbs_g: { type: "number", example: 243.4 },
          fiber_g: { type: "number", example: 27.9 },
          water_ml: { type: "number", example: 2275 }
        }
      },
      RecipeCandidate: {
        type: "object",
        properties: {
          id: { type: "string", format: "uuid" },
          title: { type: "string", example: "Bún riêu cua đồng" },
          slug: { type: "string", example: "cach-nau-bun-rieu-cua-dong-thom-ngon-dam-da" },
          category: { type: "string", example: "mon_an_sang" },
          image_url: { type: "string", nullable: true },
          servings: { type: "integer", example: 4 },
          prep_time_minutes: { type: "integer", example: 20 },
          cook_time_minutes: { type: "integer", example: 35 },
          calories_per_serving: { type: "number", example: 441.8 },
          protein_g_per_serving: { type: "number", example: 43.2 },
          fat_g_per_serving: { type: "number", example: 21.0 },
          carbs_g_per_serving: { type: "number", example: 19.8 },
          score: { type: "number", example: 0.88 },
          match_reason: { type: "string", example: "Rất chuẩn calo (lệch 8 kcal) và dồi dào chất đạm (43g)" },
          decision_probability: { type: "number", nullable: true, example: 0.62, description: "Xác suất mô hình quyết định chọn món này; null khi decision_mode = sql" }
        }
      },
      RecommendAIRequest: {
        type: "object",
        properties: {
          session_id: { type: "string", format: "uuid", description: "ID phiên chat (để trống nếu bắt đầu phiên mới)" },
          intent: { type: "string", enum: ["recommend", "how_to_cook", "nutrition"], description: "Gửi khi bấm chip; bỏ trống mà có message thì server tự phân loại" },
          recipe_id: { type: "string", format: "uuid", description: "Bắt buộc khi intent là how_to_cook / nutrition" },
          message: { type: "string", maxLength: 500, example: "Trưa nay ăn gì để tăng cơ?", description: "Câu người dùng gõ" },
          meal_type: { type: "string", enum: ["breakfast", "lunch", "dinner", "snack"], default: "lunch" },
          target_calories: { type: "number", example: 650, description: "Calo mục tiêu cho bữa ăn" },
          rejected_recipe_ids: {
            type: "array",
            items: { type: "string", format: "uuid" },
            description: "Danh sách món bị từ chối trong phiên chat để lọc bỏ (tối đa 50)"
          },
          accepted_recipe_id: { type: "string", format: "uuid", description: "Ăn món này: ghi nhật ký qua log_meal, trả status = logged" },
          servings: { type: "number", default: 1 },
          client_request_id: { type: "string", format: "uuid", description: "Chống ghi trùng khi retry" }
        }
      },
      RecommendAIResponse: {
        type: "object",
        properties: {
          session_id: { type: "string", format: "uuid" },
          message: { type: "string", description: "Lời khuyên từ Trợ lý Dinh dưỡng AI hoặc Fallback template" },
          suggested_recipes: {
            type: "array",
            items: { $ref: "#/components/schemas/RecipeCandidate" }
          },
          rejected_recipe_ids: {
            type: "array",
            items: { type: "string", format: "uuid" }
          },
          fallback: { type: "boolean", description: "true nếu Gemini API gặp sự cố và phản hồi tự động kích hoạt" },
          decision_mode: { type: "string", enum: ["model", "sql"], nullable: true, description: "model = Gemini Decision 1 xếp hạng; sql = giữ thứ tự điểm SQL" },
          intent: { type: "string", enum: ["recommend", "how_to_cook", "nutrition", "out_of_scope", "accept"] },
          status: { type: "string", enum: ["ok", "low", "capped", "goal_reached", "logged", "answered", "out_of_scope"], description: "Gợi ý: trạng thái ngân sách calo bữa; logged: Ăn món này; answered: hỏi cách nấu/dinh dưỡng" },
          recipe: { type: "object", nullable: true, description: "Khi how_to_cook/nutrition: món + instructions, ingredients, số liệu dinh dưỡng, allergens (từ DB)" },
          logged: { type: "object", nullable: true, description: "Khi Ăn món này: MealLogItem đã ghi" },
          budget: { type: "object", nullable: true, description: "meal_calorie_budget: status, target_kcal, base_kcal, remaining_kcal, daily_kcal" }
        }
      },
      SearchRecipesResponse: {
        type: "object",
        properties: {
          data: {
            type: "array",
            items: {
              type: "object",
              properties: {
                id: { type: "string", format: "uuid" },
                slug: { type: "string" },
                title: { type: "string" },
                category: { type: "string" },
                calories_per_serving: { type: "number" },
                total_count: { type: "integer", description: "Tổng số bản ghi thỏa mãn bộ lọc (cho phân trang)" }
              }
            }
          }
        }
      }
    }
  },
  security: [
    { BearerAuth: [] },
    { ApiKeyAuth: [] }
  ],
  paths: {
    "/calculate-bmr-tdee": {
      post: {
        summary: "Ước tính chỉ số BMR, TDEE và mục tiêu Calo/Macros",
        description: "Hỗ trợ onboarding hoặc cập nhật thể trạng người dùng.",
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                required: ["gender", "age", "height_cm", "weight_kg", "activity_level", "goal"],
                properties: {
                  gender: { type: "string", enum: ["male", "female", "other"] },
                  age: { type: "integer", minimum: 18, maximum: 80 },
                  height_cm: { type: "number", minimum: 120, maximum: 220 },
                  weight_kg: { type: "number", minimum: 30, maximum: 200 },
                  activity_level: { type: "string", enum: ["sedentary", "light", "moderate", "active", "very_active"] },
                  goal: { type: "string", enum: ["lose_weight", "maintain", "gain_weight"] },
                  save_to_profile: { type: "boolean", default: false }
                }
              }
            }
          }
        },
        responses: {
          "200": {
            description: "Tính toán thành công",
            content: {
              "application/json": {
                schema: {
                  type: "object",
                  properties: {
                    success: { type: "boolean" },
                    saved: { type: "boolean" },
                    data: {
                      type: "object",
                      properties: {
                        bmi: { type: "number" },
                        bmr: { type: "number" },
                        tdee: { type: "number" },
                        target_calories: { type: "number" },
                        macros: { $ref: "#/components/schemas/MacroNutrients" }
                      }
                    }
                  }
                }
              }
            }
          },
          "400": { $ref: "#/components/schemas/ErrorResponse" }
        }
      }
    },
    "/recommend-ai": {
      post: {
        summary: "Gợi ý món ăn thông minh & Chat AI với Gemini API (Sprint 6)",
        description: "Lọc dị ứng người dùng, cân đối calo bữa ăn, tự động đổi món khi bị từ chối và hỗ trợ fallback.",
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: { $ref: "#/components/schemas/RecommendAIRequest" }
            }
          }
        },
        responses: {
          "200": {
            description: "Gợi ý món ăn và phản hồi chat thành công",
            content: {
              "application/json": {
                schema: { $ref: "#/components/schemas/RecommendAIResponse" }
              }
            }
          },
          "401": { $ref: "#/components/schemas/ErrorResponse" },
          "500": { $ref: "#/components/schemas/ErrorResponse" }
        }
      }
    },
    "/meal-logs": {
      get: {
        summary: "Lấy nhật ký bữa ăn theo ngày",
        parameters: [
          { name: "date", in: "query", required: false, schema: { type: "string", format: "date" } }
        ],
        responses: {
          "200": { description: "Danh sách bữa ăn trong ngày" }
        }
      },
      post: {
        summary: "Ghi nhận món ăn vào nhật ký bữa ăn",
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                required: ["meal_type", "recipe_id"],
                properties: {
                  meal_type: { type: "string", enum: ["breakfast", "lunch", "dinner", "snack"] },
                  recipe_id: { type: "string", format: "uuid" },
                  servings: { type: "number", default: 1.0 },
                  date: { type: "string", format: "date" }
                }
              }
            }
          }
        },
        responses: {
          "200": { description: "Ghi nhật ký thành công" }
        }
      }
    },
    "/recipe-review-assist": {
      post: {
        summary: "AI chấm sẵn món cộng đồng chờ duyệt (chỉ admin)",
        description: "Gemini Decision 1: có phải món thật, danh mục, calo hợp lý, dị ứng. Lưu recipes.ai_review. Chỉ tham khảo, không tự duyệt.",
        requestBody: { required: true, content: { "application/json": { schema: { type: "object", required: ["recipe_id"], properties: { recipe_id: { type: "string", format: "uuid" } } } } } },
        responses: {
          "200": { description: "ai_review (null khi AI lỗi)" },
          "403": { description: "FORBIDDEN: không phải admin" },
          "404": { description: "RECIPE_NOT_FOUND" },
          "409": { description: "RECIPE_NOT_PENDING" }
        }
      }
    },
    "/rpc/submit_recipe": {
      post: {
        summary: "User gửi / sửa công thức (tự tính dinh dưỡng, chờ admin duyệt)",
        requestBody: {
          required: true,
          content: { "application/json": { schema: { type: "object", required: ["p_title", "p_category", "p_servings", "p_ingredients", "p_instructions"],
            properties: {
              p_title: { type: "string", minLength: 3, maxLength: 120 },
              p_category: { type: "string" },
              p_servings: { type: "integer", minimum: 1, maximum: 20 },
              p_ingredients: { type: "array", minItems: 2, maxItems: 40, items: { type: "object", properties: { ingredient_id: { type: "string", format: "uuid" }, amount: { type: "number" }, unit: { type: "string", enum: ["g", "ml"] } } } },
              p_instructions: { type: "array", minItems: 1, maxItems: 30, items: { type: "object", properties: { title: { type: "string" }, description: { type: "string" } } } },
              p_image_url: { type: "string" },
              p_recipe_id: { type: "string", format: "uuid", description: "Có = sửa + gửi lại món của mình đang pending/rejected" }
            } } } }
        },
        responses: { "200": { description: "{ id, status: pending, calories_per_serving, …, allergens }" } }
      }
    },
    "/rpc/admin_review_recipe": {
      post: {
        summary: "Admin duyệt / từ chối công thức (từ chối bắt buộc lý do; p_submitted_at = bản đã xem, lệch → RECIPE_CHANGED)",
        requestBody: { required: true, content: { "application/json": { schema: { type: "object", required: ["p_recipe_id", "p_approve", "p_submitted_at"],
          properties: { p_recipe_id: { type: "string", format: "uuid" }, p_approve: { type: "boolean" }, p_submitted_at: { type: "string", format: "date-time" }, p_reason: { type: "string", minLength: 5, maxLength: 500 } } } } } },
        responses: { "200": { description: "{ id, status }" } }
      }
    },
    "/rpc/search_recipes": {
      post: {
        summary: "Tìm kiếm công thức nấu ăn nâng cao có phân trang (RPC)",
        description: "Hỗ trợ phân trang p_page, p_page_size, sắp xếp p_sort, lọc gia_vi_an_kem và trả về total_count.",
        requestBody: {
          required: true,
          content: {
            "application/json": {
              schema: {
                type: "object",
                properties: {
                  p_query: { type: "string" },
                  p_page: { type: "integer", default: 1 },
                  p_page_size: { type: "integer", default: 20 },
                  p_sort: { type: "string", enum: ["title_asc", "calories_asc", "calories_desc", "time_asc"], default: "title_asc" },
                  p_min_calories: { type: "number" },
                  p_max_calories: { type: "number" },
                  p_include_condiments: { type: "boolean", default: false }
                }
              }
            }
          }
        },
        responses: {
          "200": {
            description: "Danh sách kết quả tìm kiếm kèm total_count",
            content: {
              "application/json": {
                schema: { $ref: "#/components/schemas/SearchRecipesResponse" }
              }
            }
          }
        }
      }
    }
  }
};

// Hàm chuyển đổi đơn giản Object -> YAML cho OpenAPI (tránh phụ thuộc thư viện)
function objectToYaml(obj, indent = 0) {
  const pad = ' '.repeat(indent);
  if (obj === null || obj === undefined) return 'null\n';
  if (typeof obj === 'string') {
    if (obj.includes('\n') || obj.includes(':') || obj.includes('#') || obj.includes('"') || obj.includes("'")) {
      return JSON.stringify(obj) + '\n';
    }
    return obj + '\n';
  }
  if (typeof obj === 'number' || typeof obj === 'boolean') {
    return String(obj) + '\n';
  }
  if (Array.isArray(obj)) {
    if (obj.length === 0) return '[]\n';
    return '\n' + obj.map(item => {
      const child = objectToYaml(item, indent + 2);
      if (typeof item === 'object' && item !== null && !Array.isArray(item)) {
        const lines = child.trim().split('\n');
        return `${pad}- ${lines[0]}\n` + lines.slice(1).map(l => `${pad}  ${l}`).join('\n') + (lines.length > 1 ? '\n' : '');
      }
      return `${pad}- ${child.trim()}\n`;
    }).join('');
  }
  if (typeof obj === 'object') {
    const keys = Object.keys(obj);
    if (keys.length === 0) return '{}\n';
    return (indent === 0 ? '' : '\n') + keys.map(key => {
      const val = obj[key];
      const valYaml = objectToYaml(val, indent + 2);
      if (typeof val === 'object' && val !== null) {
        return `${pad}${key}:${valYaml.endsWith('\n') ? valYaml : valYaml + '\n'}`;
      } else {
        return `${pad}${key}: ${valYaml.trim()}\n`;
      }
    }).join('');
  }
  return String(obj) + '\n';
}

function main() {
  console.log('Generating Elytra OpenAPI Specification & Release Bundle...');

  if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  }

  // 1. Ghi openapi.json
  const jsonPath = path.join(OUTPUT_DIR, 'openapi.json');
  fs.writeFileSync(jsonPath, JSON.stringify(openApiSpec, null, 2), 'utf8');
  console.log(`[OK] Generated: ${jsonPath}`);

  // 2. Ghi openapi.yaml
  const yamlPath = path.join(OUTPUT_DIR, 'openapi.yaml');
  const yamlContent = objectToYaml(openApiSpec);
  fs.writeFileSync(yamlPath, yamlContent, 'utf8');
  console.log(`[OK] Generated: ${yamlPath}`);

  // 3. Sao chép api-contract.md sang dist/api
  const contractSrc = path.join(DOCS_DIR, 'api-contract.md');
  const contractDest = path.join(OUTPUT_DIR, 'api-contract.md');
  if (fs.existsSync(contractSrc)) {
    fs.copyFileSync(contractSrc, contractDest);
    console.log(`[OK] Copied: ${contractDest}`);
  }

  // 4. Tạo Release Manifest
  const manifest = {
    release_name: `Elytra API Spec v${openApiSpec.info.version}`,
    version: openApiSpec.info.version,
    generated_at: new Date().toISOString(),
    files: [
      "openapi.json",
      "openapi.yaml",
      "api-contract.md"
    ]
  };
  fs.writeFileSync(path.join(OUTPUT_DIR, 'release-manifest.json'), JSON.stringify(manifest, null, 2), 'utf8');
  console.log('[OK] Generated release-manifest.json');

  console.log('\nAll API assets prepared successfully in dist/api/');
}

main();
