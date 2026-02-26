const String defaultContentType = 'general_post';
const String customContentTypeOption = '__custom__';

const List<String> presetContentTypes = <String>[
  defaultContentType,
  'coding_guide',
  'ai_tool_guide',
];

String normalizeContentType(String? raw) {
  final value = raw?.trim().toLowerCase() ?? '';
  if (value.isEmpty) {
    return defaultContentType;
  }
  final sanitized = value.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  final collapsed = sanitized.replaceAll(RegExp(r'_+'), '_');
  return collapsed.replaceAll(RegExp(r'^_|_$'), '').trim().isEmpty
      ? defaultContentType
      : collapsed.replaceAll(RegExp(r'^_|_$'), '');
}

String resolveContentTypeInput({
  required String selectedOption,
  required String customInput,
}) {
  if (selectedOption == customContentTypeOption) {
    return normalizeContentType(customInput);
  }
  return normalizeContentType(selectedOption);
}

String contentTypeOptionLabel(String value) {
  if (value == customContentTypeOption) {
    return 'Custom type';
  }
  return contentTypeDisplayLabel(value);
}

String contentTypeDisplayLabel(String value) {
  final normalized = normalizeContentType(value);
  return switch (normalized) {
    'general_post' => 'General post',
    'coding_guide' => 'Coding guide',
    'ai_tool_guide' => 'AI tool guide',
    _ => normalized.replaceAll('_', ' '),
  };
}

bool isCodingGuideType(String? contentType) {
  return normalizeContentType(contentType) == 'coding_guide';
}

bool isAiToolGuideType(String? contentType) {
  final normalized = normalizeContentType(contentType);
  if (normalized == 'ai_tool_guide') {
    return true;
  }
  return normalized.contains('ai') && normalized.contains('guide');
}

bool isGuideLikeType(String? contentType) {
  final normalized = normalizeContentType(contentType);
  if (normalized == 'coding_guide' || normalized == 'ai_tool_guide') {
    return true;
  }
  return normalized.endsWith('_guide') || normalized.contains('tutorial');
}

String intentForContentType(String? contentType) {
  if (isAiToolGuideType(contentType)) {
    return 'tool_guide';
  }
  if (isGuideLikeType(contentType)) {
    return 'guide';
  }
  return 'how_to';
}

String draftOutlineHintForContentType(String? contentType) {
  if (isCodingGuideType(contentType)) {
    return '- Setup and prerequisites\n- Step-by-step implementation\n- Verification and pitfalls';
  }
  if (isAiToolGuideType(contentType)) {
    return '- Use-case and tool setup\n- Prompt template and parameters\n- Guardrails, cost, and failure modes';
  }
  if (isGuideLikeType(contentType)) {
    return '- Context and objective\n- Practical steps or workflow\n- Verification checklist and caveats';
  }
  return '- What changed\n- Why this matters now';
}
