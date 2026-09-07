import 'package:openexam_app/core/ai/ai_client.dart';
import 'package:openexam_app/core/ai/ai_settings.dart';
import 'package:openexam_app/features/essay/domain/essay_models.dart';

/// 申论批改与拍照识题。
///
/// 批改的价值不在那个分数，而在「哪几个采分点没写到、为什么会漏」——
/// prompt 也是照这个目标写的：阅卷口吻，逐点对照，不做鼓励式点评。
class EssayGrader {
  const EssayGrader(this.settings);

  final AiSettings settings;

  static const _graderSystem = '''
你是一位阅卷经验丰富的公考申论阅卷老师。你的任务是按评分标准客观批改考生答案，不是鼓励，也不是教学。
批改必须做到：
1. 逐条对照采分点，明确指出考生写到了哪些、漏了哪些
2. 漏点要说清楚"材料里在哪、为什么该写、考生为什么会漏"
3. 打分以要点覆盖为主、语言表述为辅，不放水
4. 只输出 JSON，不要任何解释性文字，不要代码块标记''';

  static const _ocrSystem = '''
你是申论真题录入助手。从图片里原样提取给定材料和题目，不要改写、不要总结、不要补充。只输出 JSON。''';

  Future<AiResult<EssayReview>> grade({
    required EssayPrompt prompt,
    required String answer,
  }) async {
    AiClient.feature = 'essay';
    final result = await AiClient(settings).completeJson(
      system: _graderSystem,
      prompt: _buildPrompt(prompt, answer),
      maxTokens: 4096,
    );
    if (!result.isOk) return AiResult.fail(result.error);
    try {
      return AiResult.ok(EssayReview.fromJson(result.value!));
    } catch (error) {
      return AiResult.fail('批改结果解析失败：$error');
    }
  }

  String _buildPrompt(EssayPrompt p, String answer) {
    final limit = p.wordLimit == null ? '未限制字数' : '${p.wordLimit} 字以内';

    final points = p.scoringPoints.isEmpty
        ? '\n【采分点】未提供。请你先从给定材料中自行提炼应得的采分点，再据此批改。\n'
        : '\n【已知采分点】\n${p.scoringPoints.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}\n';

    final reference = (p.referenceAnswer?.trim().isNotEmpty ?? false)
        ? '\n【参考答案】\n${p.referenceAnswer}\n'
        : '';

    return '''请批改下面这道申论「${p.type.label}」题。

【给定材料】
${p.material}

【题目要求】
${p.requirement}
字数要求：$limit
$points$reference
【考生答案】
$answer

按下面的 JSON 结构输出批改结果：
{
  "score": 得分数字,
  "maxScore": 满分数字,
  "dimensions": [
    {"name":"要点覆盖","score":数字,"max":数字,"comment":"一句话点评"},
    {"name":"概括层次","score":数字,"max":数字,"comment":"..."},
    {"name":"语言规范","score":数字,"max":数字,"comment":"..."},
    {"name":"字数控制","score":数字,"max":数字,"comment":"..."}
  ],
  "points": [
    {"text":"采分点内容","hit":true或false,"evidence":"材料出处或考生原文","why":"漏掉时说明为什么该写、为什么容易漏"}
  ],
  "summary": "整体评价，两三句话",
  "improvements": ["下次要注意的具体动作，两到四条"]
}

要点覆盖占分最重。points 数组要把所有采分点都列出来，命中的 hit 为 true。''';
  }

  /// 从截图/拍照里认出一道申论题，回填录入表单。
  Future<AiResult<EssayPrompt>> recognize({
    required String imageBase64,
    String mimeType = 'image/png',
  }) async {
    const prompt = '''识别这张图片里的申论题目，按下面的 JSON 输出：
{
  "title": "题目标题，没有就用题干前 20 字",
  "essayType": "guina|duice|fenxi|guanche|dazuowen 之一",
  "material": "给定材料全文，保留段落编号和换行",
  "requirement": "作答要求原文",
  "wordLimit": 字数上限数字，没有则 null,
  "province": "省份，认不出填 null",
  "year": 年份数字，认不出填 null
}
材料要一字不漏地抄下来，这是批改的依据。''';

    AiClient.feature = 'ocr';
    final result = await AiClient(settings).completeWithImage(
      system: _ocrSystem,
      prompt: prompt,
      imageBase64: imageBase64,
      mimeType: mimeType,
    );
    if (!result.isOk) return AiResult.fail(result.error);

    final json = extractJson(result.value ?? '');
    if (json == null) {
      return const AiResult.fail('没能从图片里认出申论题，换一张更清晰的试试');
    }

    final type = EssayTypeLabel.parse(json['essayType']?.toString());
    final material = (json['material'] ?? '').toString();
    if (material.trim().isEmpty) {
      return const AiResult.fail('图片里没识别到给定材料，换一张更完整的');
    }

    return AiResult.ok(EssayPrompt(
      id: '',
      title: (json['title'] ?? '未命名').toString(),
      type: type,
      material: material,
      requirement: (json['requirement'] ?? '').toString(),
      province: json['province']?.toString(),
      year: int.tryParse(json['year']?.toString() ?? ''),
      wordLimit: int.tryParse(json['wordLimit']?.toString() ?? ''),
      minutes: type.defaultMinutes,
      createdAt: DateTime.now(),
    ));
  }
}
