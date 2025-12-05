import 'dart:math';

class AppStrings {
  static const premium = 'Premium';
  static const newChat = 'Yeni sohbet';
  static const projects = 'Projeler';
  static const library = 'Kitaplık';

  // Pricing header
  static const pricingTitle = 'Planını yükselt';

  // Plan titles
  static const planFreeTitle = 'Ücretsiz';
  static const planPlusTitle = 'Plus';
  static const planBusinessTitle = 'Business';
  static const planProTitle = 'Pro';
  static const planPopularTag = 'Popüler';

  // Prices (display-ready)
  static const planFreePrice = '₺0';
  static const planPlusPrice = '₺20/ay';
  static const planBusinessPrice = '₺100/ay';
  static const planProPrice = '₺200/ay';

  // Subtitles/blurbs
  static const planFreeBlurb = 'Günlük görevler için zeka';
  static const planPlusBlurb = 'Seçtiğiniz 2 grubun tüm modellerine erişim';
  static const planBusinessBlurb =
      'Seçtiğiniz 4 grubun tüm modellerine erişim, daha yüksek limitler';
  static const planProBlurb =
      'Tüm grupların modellerine sınırsız erişim ve en yüksek limitler';

  // CTA labels
  static const planFreeCta = 'Mevcut planın';
  static const planPlusCta = 'Plus edin';
  static const planBusinessCta = 'Business abonesi ol';
  static const planProCta = 'Pro edin';

  // Feature bullets
  static const featGpts = 'GPT-5’e erişim';
  static const featFileUpload = 'Sınırlı dosya yüklemesi';
  static const featLimitedImageGen = 'Sınırlı ve daha yavaş görsel üretimi';
  static const featLimitedMemory = 'Sınırlı bellek ve bağlam';
  static const featLimitedResearch = 'Sınırlı derin araştırma';

  static const featAdvancedReasoning = 'Gelişmiş akıl yürütme destekli GPT-5';
  static const featFasterMessaging = 'Genişletilmiş mesajlaşma ve yüklemeler';
  static const featFasterImageGen =
      'Genişletilmiş ve daha hızlı görsel oluşturma';
  static const featExpandedMemory = 'Genişletilmiş bellek ve bağlam';
  static const featDeepResearch = 'Genişletilmiş derin araştırma ve ajan modu';
  static const featProjects = 'Projeler ve görevler modu';
  static const featSora = 'Sora video üretimi';
  static const featCodex = 'Kodex için';

  static const featEverythingInPlus =
      'Plus’taki her şey, daha da yüksek limitlerle';
  static const featEverythingInBusiness =
      'Business’taki her şey, daha da yüksek limitlerle';
  static const featSecureAccess = 'Ekibin en iyi modellerimize sınırsız erişim';
  static const featSsoMfa = 'SSO, MFA ve daha fazlasıyla gelişmiş güvenlik';
  static const featPrivacy =
      'Gizlilik yerleşik; veriler hiçbir zaman eğitim için kullanılmaz';
  static const featSharepoint = 'Sharepoint ve diğer araçlarla entegrasyon';
  static const featProjectsCollab = 'Paylaşılan projeler ve özel modeller';

  static const featProReasoning = 'Pro akıl yürütme yeteneğine sahip modeller';
  static const featUnlimitedMessages = 'Sınırsız mesajlar ve yüklemeler';
  static const featMaxImageGen = 'Sınırsız ve daha hızlı görsel oluşturma';
  static const featMaxMemory = 'Maksimum bellek ve bağlam';
  static const featMaxResearch = 'Maksimum derin araştırma ve ajan modu';
  static const featProProjects =
      'Geliştirilmiş projeler, görevler ve özel modeller';

  static String unlockVendorsLabel(int groupCount) =>
      'Seçtiğiniz $groupCount grubun tüm modelleri dahil';
  static const featUnlockAllVendors = 'Tüm grupların tüm modelleri dahil';

  static const history = 'Geçmiş';
  static const favorites = 'Favoriler';
  static const attachFile = 'Dosya ekle';
  static String supportedExts =
      'Desteklenen formatlar: ${extensions.map((e) => '.$e').join(', ')}';
  static const maxSizeText = 'Maksimum dosya boyutu: 25 MB';
  static const newChatCleared = 'Yeni sohbet başlatıldı';

  // Input hint text
  static const inputHint = 'Herhangi bir şey sor';
  static const reasoningText = 'Mantık yürüt';

  // Diversified, random home placeholders
  static final List<String> _homePlaceholders = [
    'Bugün aklında ne var?',
    'Ne üzerinde çalışıyorsun?',
    'Hangi konuda yardım edebilirim?',
    'Bir şeyler üretmeye hazır mısın?',
    'Sorularını getir, birlikte çözelim.',
    'Yeni bir fikir mi keşfetmek istiyorsun?',
    'Kod, tasarım, metin… ne istersen sor.',
  ];

  static String randomHomePlaceholder() {
    final r = Random();
    return _homePlaceholders[r.nextInt(_homePlaceholders.length)];
  }

  static const appTitle = 'Personal Chat UI';
  static const chats = 'Sohbetler';
  static const noChatsYet = 'Henüz sohbet yok';
  static const searchChatsHint = 'Sohbetleri ara…';
  static const modelTitle = 'Model seçimi';
  static const searchModelsHint = 'Model ara…';
  static const noResults = 'Sonuç bulunamadı';
  static const close = 'Kapat';
  static const renameChat = 'Sohbet adını değiştir';
  static const favoriteChat = 'Sohbeti favorile';
  static const unfavoriteChat = 'Favoriden çıkar';
  static const chatSettings = 'Sohbet ayarları';
  static const deleteChat = 'Sohbeti sil';
  static const deleteChatConfirmTitle = 'Sohbet silinsin mi?';
  static const deleteChatConfirmBody =
      'Bu sohbet tüm mesajlarıyla birlikte kalıcı olarak silinecek.';
  static const delete = 'Sil';
  static const cancel = 'İptal';
  static const expandSidebarToRename =
      'Sohbet başlığını düzenlemek için paneli genişlet';
  static String deleteChatDescription(String title) =>
      '“$title” sohbeti kalıcı olarak silinecek.';
  static const continueAction = 'Devam et';

  // Premium dialog
  static const featureLimitedSpeed = 'Sınırlı hız';
  static const featureBasicAccess = 'Temel erişim';
  static const featureFast = 'Hızlı yanıt';
  static const featurePriority = 'Öncelikli erişim';
  static const featureLimitedContext = 'Kısıtlı bağlam';
  static const featureLongContext = 'Uzun bağlam';
  static const featureMoreLongContext = 'Daha uzun bağlam';
  static const featureShared = 'Paylaşımlı öğeler';
  static const featureRbac = 'Rol bazlı erişim';

  // ChatService sample response phrases
  static const responseIntro = 'İstediğini anladım. İşte düşüncelerim:';
  static const responseDash = '—';
  static const responseAboutSuffix = 'hakkında bazı öneriler ve çıkarımlar.';
  static const responseOutro = 'Daha fazla detay istersen devam edebilirim.';

  static const today = 'Bugün';
  static const yesterday = 'Dün';
  static const last7Days = 'Önceki 7 Gün';
  static const older = 'Daha eski';

  // Thinking label
  static const thinking = 'Düşünüyor';

  // Message actions
  static const editMessage = 'Düzenle';
  static const copyMessage = 'Kopyala';
  static const copiedToClipboard = 'Panoya kopyalandı';

  // Library dialog
  static const images = 'Görseller';
  static const noImages = 'Henüz görsel yok';

  // User profile section
  static const userName = 'Kullanıcı';
  static const settings = 'Ayarlar';

  // User menu items
  static const upgradePlan = 'Planı yükselt';
  static const customization = 'Kişiselleştirme';
  static const help = 'Yardım';
  static const logout = 'Oturumu kapat';
  static const currentPlan = 'Ücretsiz';
}

class AppTooltips {
  static const toggleSidebar = 'Paneli aç/kapat';
  static const theme = 'Tema değiştir';
  static const mic = 'Mikrofon';
  static const send = 'Gönder';
  static const premium = 'Premium’u görüntüle';
  static const attachImage = 'Görsel ekle';
  static const attachFile = 'Dosya ekle';
  static const stop = 'Akışı durdur';
  static const supportedThink = 'Daha uzun süre düşün';
  static const notSupportedMic = 'Seçilen model sesli iletişimi desteklemiyor';
  static const notSupportedFile = 'Seçilen model dosya eklemeyi desteklemiyor';
  static const notSupportedThink =
      'Seçilen model mantık yürütme modunu desteklemiyor';
  static const openInChat = 'Sohbette aç';
  static const downloadImage = 'Görseli indir';

  // Message actions
  static const editMessage = 'Düzenle';
  static const copyMessage = 'Kopyala';

  // Assistant message actions
  static const likeMessage = 'Beğendim';
  static const dislikeMessage = 'Beğenmedim';
  static const regenerateMessage = 'Yeniden oluştur';

  // User profile section
  static const userProfile = 'Profil';
  static const settings = 'Ayarlar';
}

// Pricing enum + mapping
enum PricingPlan { free, plus, business, pro }

// Immutable model for plan metadata
class PlanMeta {
  final String title;
  final String price;
  final String blurb;
  final String cta;
  final bool isPopular;
  final List<String> features;
  const PlanMeta({
    required this.title,
    required this.price,
    required this.blurb,
    required this.cta,
    this.isPopular = false,
    required this.features,
  });
}

final Map<PricingPlan, PlanMeta> _kPlanMeta = Map.unmodifiable(
  _buildPlanMeta(),
);

Map<PricingPlan, PlanMeta> _buildPlanMeta() {
  return {
    PricingPlan.free: PlanMeta(
      title: AppStrings.planFreeTitle,
      price: AppStrings.planFreePrice,
      blurb: AppStrings.planFreeBlurb,
      cta: AppStrings.planFreeCta,
      features: [
        AppStrings.featureBasicAccess,
        AppStrings.featureLimitedSpeed,
        AppStrings.featureLimitedContext,
      ],
    ),
    PricingPlan.plus: PlanMeta(
      title: AppStrings.planPlusTitle,
      price: AppStrings.planPlusPrice,
      blurb: AppStrings.planPlusBlurb,
      cta: AppStrings.planPlusCta,
      isPopular: true,
      features: [
        AppStrings.unlockVendorsLabel(2),
        AppStrings.featFasterMessaging,
        AppStrings.featureFast,
        AppStrings.featureLongContext,
        AppStrings.featurePriority,
      ],
    ),
    PricingPlan.business: PlanMeta(
      title: AppStrings.planBusinessTitle,
      price: AppStrings.planBusinessPrice,
      blurb: AppStrings.planBusinessBlurb,
      cta: AppStrings.planBusinessCta,
      features: [
        AppStrings.featEverythingInPlus,
        AppStrings.unlockVendorsLabel(4),
        AppStrings.featFasterMessaging,
        AppStrings.featureMoreLongContext,
        AppStrings.featProjects,
      ],
    ),
    PricingPlan.pro: PlanMeta(
      title: AppStrings.planProTitle,
      price: AppStrings.planProPrice,
      blurb: AppStrings.planProBlurb,
      cta: AppStrings.planProCta,
      features: [
        AppStrings.featEverythingInBusiness,
        AppStrings.featUnlockAllVendors,
        AppStrings.featUnlimitedMessages,
        AppStrings.featMaxMemory,
        AppStrings.featMaxResearch,
      ],
    ),
  };
}

// Rewritten getters to read from the map (clean and DRY)
extension PricingPlanX on PricingPlan {
  PlanMeta get _meta => _kPlanMeta[this]!;
  String get title => _meta.title;
  String get price => _meta.price;
  String get blurb => _meta.blurb;
  String get cta => _meta.cta;
  bool get isPopular => _meta.isPopular;
  List<String> get features => _meta.features;
}

// Models catalog: vendors, capabilities, metadata and helpers
enum ModelVendor { xai, anthropic, deepseek, google, openai, alibaba, meta }

// Changed: imageInputs -> fileInputs. hybridReasoning removed previously.
enum ModelCapability { reasoning, fileInputs, audioInputs, textInputs }

extension ModelCapabilityX on ModelCapability {
  String get label {
    switch (this) {
      case ModelCapability.reasoning:
        return 'Mantık yürütme';
      case ModelCapability.fileInputs:
        return 'Dosya girdileri';
      case ModelCapability.audioInputs:
        return 'Ses girdileri';
      case ModelCapability.textInputs:
        return 'Metin girdileri';
    }
  }
}

class ModelMeta {
  final String id; // unique key "vendor/model-name"
  final ModelVendor vendor;
  final String name;
  final String subtitle; // e.g., "Balanced hybrid-reasoning model"
  final List<ModelCapability> caps;
  final String logoUrl;
  const ModelMeta({
    required this.id,
    required this.vendor,
    required this.name,
    required this.subtitle,
    required this.caps,
    required this.logoUrl,
  });
}

class AppModels {
  // Models by id (single source of truth for all models)
  static final Map<String, ModelMeta> all = {
    // xAI
    'xai/grok-3': ModelMeta(
      id: 'xai/grok-3',
      vendor: ModelVendor.xai,
      name: 'Grok 3',
      subtitle: 'Previous flagship model',
      caps: const [ModelCapability.audioInputs, ModelCapability.textInputs],
      logoUrl: 'assets/grok-3.svg',
    ),
    'xai/grok-4': ModelMeta(
      id: 'xai/grok-4',
      vendor: ModelVendor.xai,
      name: 'Grok 4',
      subtitle: 'Flagship model',
      caps: const [
        ModelCapability.reasoning,
        ModelCapability.fileInputs,
        ModelCapability.audioInputs,
        ModelCapability.textInputs,
      ],
      logoUrl: 'assets/grok-4.svg',
    ),
    'xai/grok-4.1': ModelMeta(
      id: 'xai/grok-4.1',
      vendor: ModelVendor.xai,
      name: 'Grok 4.1',
      subtitle: 'Latest flagship model',
      caps: const [
        ModelCapability.reasoning,
        ModelCapability.fileInputs,
        ModelCapability.audioInputs,
        ModelCapability.textInputs,
      ],
      logoUrl: 'assets/grok-4-1.svg',
    ),
    // Anthropic
    'anthropic/claude-sonnet-4.5': ModelMeta(
      id: 'anthropic/claude-sonnet-4.5',
      vendor: ModelVendor.anthropic,
      name: 'Claude Sonnet 4.5',
      subtitle: 'Balanced hybrid-reasoning model',
      caps: const [
        ModelCapability.reasoning,
        ModelCapability.fileInputs,
        ModelCapability.audioInputs,
        ModelCapability.textInputs,
      ],
      logoUrl: 'assets/claude-sonnet-4-5.svg',
    ),
    'anthropic/claude-haiku-4.5': ModelMeta(
      id: 'anthropic/claude-haiku-4.5',
      vendor: ModelVendor.anthropic,
      name: 'Claude Haiku 4.5',
      subtitle: 'Efficient hybrid-reasoning model',
      caps: const [
        ModelCapability.reasoning,
        ModelCapability.fileInputs,
        ModelCapability.audioInputs,
        ModelCapability.textInputs,
      ],
      logoUrl: 'assets/claude-haiku-4-5.svg',
    ),
    'anthropic/claude-opus-4': ModelMeta(
      id: 'anthropic/claude-opus-4',
      vendor: ModelVendor.anthropic,
      name: 'Claude Opus 4',
      subtitle: 'Previous advanced hybrid-reasoning model',
      caps: const [
        ModelCapability.reasoning,
        ModelCapability.fileInputs,
        ModelCapability.audioInputs,
        ModelCapability.textInputs,
      ],
      logoUrl: 'assets/claude-opus-4.svg',
    ),
    'anthropic/claude-sonnet-4': ModelMeta(
      id: 'anthropic/claude-sonnet-4',
      vendor: ModelVendor.anthropic,
      name: 'Claude Sonnet 4',
      subtitle: 'Previous balanced hybrid-reasoning model',
      caps: const [
        ModelCapability.reasoning,
        ModelCapability.fileInputs,
        ModelCapability.audioInputs,
        ModelCapability.textInputs,
      ],
      logoUrl: 'assets/claude-sonnet-4.svg',
    ),
    'anthropic/claude-opus-4.1': ModelMeta(
      id: 'anthropic/claude-opus-4.1',
      vendor: ModelVendor.anthropic,
      name: 'Claude Opus 4.1',
      subtitle: 'Advanced hybrid-reasoning model',
      caps: const [
        ModelCapability.reasoning,
        ModelCapability.fileInputs,
        ModelCapability.audioInputs,
        ModelCapability.textInputs,
      ],
      logoUrl: 'assets/claude-opus-4-1.svg',
    ),
    'anthropic/claude-opus-4.5': ModelMeta(
      id: 'anthropic/claude-opus-4.5',
      vendor: ModelVendor.anthropic,
      name: 'Claude Opus 4.5',
      subtitle: 'Most advanced hybrid-reasoning model',
      caps: const [
        ModelCapability.reasoning,
        ModelCapability.fileInputs,
        ModelCapability.audioInputs,
        ModelCapability.textInputs,
      ],
      logoUrl: 'assets/claude-opus-4-5.svg',
    ),
    // DeepSeek
    'deepseek/r1': ModelMeta(
      id: 'deepseek/r1',
      vendor: ModelVendor.deepseek,
      name: 'DeepSeek R1',
      subtitle: 'Most advanced reasoning model',
      caps: const [ModelCapability.reasoning, ModelCapability.textInputs],
      logoUrl: 'assets/deepseek-r1.svg',
    ),
    // Google
    'google/gemini-2.5-pro': ModelMeta(
      id: 'google/gemini-2.5-pro',
      vendor: ModelVendor.google,
      name: 'Gemini 2.5 Pro',
      subtitle: 'Advanced reasoning model',
      caps: const [
        ModelCapability.reasoning,
        ModelCapability.fileInputs,
        ModelCapability.audioInputs,
        ModelCapability.textInputs,
      ],
      logoUrl: 'assets/gemini-2-5-pro.svg',
    ),
    'google/gemini-2.5-flash': ModelMeta(
      id: 'google/gemini-2.5-flash',
      vendor: ModelVendor.google,
      name: 'Gemini 2.5 Flash',
      subtitle: 'Efficient reasoning model',
      caps: const [
        ModelCapability.reasoning,
        ModelCapability.fileInputs,
        ModelCapability.audioInputs,
        ModelCapability.textInputs,
      ],
      logoUrl: 'assets/gemini-2-5-flash.svg',
    ),
    'google/gemini-3-pro': ModelMeta(
      id: 'google/gemini-3-pro',
      vendor: ModelVendor.google,
      name: 'Gemini 3 Pro',
      subtitle: 'Most advanced reasoning model',
      caps: const [
        ModelCapability.reasoning,
        ModelCapability.fileInputs, // image inputs
        ModelCapability.textInputs,
      ],
      logoUrl: 'assets/gemini-3-pro.svg',
    ),
    // OpenAI
    'openai/gpt-5': ModelMeta(
      id: 'openai/gpt-5',
      vendor: ModelVendor.openai,
      name: 'GPT-5',
      subtitle: 'Flagship model',
      caps: const [
        ModelCapability.fileInputs,
        ModelCapability.audioInputs,
        ModelCapability.textInputs,
      ],
      logoUrl: 'assets/gpt-5.svg',
    ),
    'openai/gpt-5.1': ModelMeta(
      id: 'openai/gpt-5.1',
      vendor: ModelVendor.openai,
      name: 'GPT-5.1',
      subtitle: 'Latest flagship model',
      caps: const [
        ModelCapability.fileInputs,
        ModelCapability.audioInputs,
        ModelCapability.textInputs,
      ],
      logoUrl: 'assets/gpt-5-1.svg',
    ),
    'openai/gpt-4o': ModelMeta(
      id: 'openai/gpt-4o',
      vendor: ModelVendor.openai,
      name: 'GPT-4o',
      subtitle: 'Advanced model',
      caps: const [
        ModelCapability.fileInputs,
        ModelCapability.audioInputs,
        ModelCapability.textInputs,
      ],
      logoUrl: 'assets/gpt-4o.svg',
    ),
    'openai/gpt-4.1': ModelMeta(
      id: 'openai/gpt-4.1',
      vendor: ModelVendor.openai,
      name: 'GPT-4.1',
      subtitle: 'Previous flagship model',
      caps: const [
        ModelCapability.fileInputs,
        ModelCapability.audioInputs,
        ModelCapability.textInputs,
      ],
      logoUrl: 'assets/gpt-4-1.svg',
    ),
    'openai/gpt-realtime': ModelMeta(
      id: 'openai/gpt-realtime',
      vendor: ModelVendor.openai,
      name: 'GPT Realtime',
      subtitle: 'Real-time conversational model',
      caps: const [ModelCapability.audioInputs, ModelCapability.textInputs],
      logoUrl: 'assets/gpt-realtime.svg',
    ),
    'openai/o3': ModelMeta(
      id: 'openai/o3',
      vendor: ModelVendor.openai,
      name: 'o3',
      subtitle: 'Advanced reasoning model',
      caps: const [
        ModelCapability.reasoning,
        ModelCapability.fileInputs,
        ModelCapability.audioInputs,
        ModelCapability.textInputs,
      ],
      logoUrl: 'assets/o3.svg',
    ),
    'openai/o4-mini': ModelMeta(
      id: 'openai/o4-mini',
      vendor: ModelVendor.openai,
      name: 'o4-mini',
      subtitle: 'Efficient reasoning model',
      caps: const [ModelCapability.textInputs],
      logoUrl: 'assets/o4-mini.svg',
    ),
    // Alibaba
    'alibaba/qwen3': ModelMeta(
      id: 'alibaba/qwen3',
      vendor: ModelVendor.alibaba,
      name: 'Qwen 3',
      subtitle: 'Efficient model',
      caps: const [ModelCapability.textInputs],
      logoUrl: 'assets/qwen3.svg',
    ),
    // Meta
    'meta/llama-4-maverick': ModelMeta(
      id: 'meta/llama-4-maverick',
      vendor: ModelVendor.meta,
      name: 'Llama 4 Maverick',
      subtitle: 'Advanced model',
      caps: const [ModelCapability.textInputs],
      logoUrl: 'assets/llama-4-maverick.svg',
    ),
  };

  // Display titles for vendor sections (order matches ModelVendor.values)
  static const List<String> vendorTitles = <String>[
    'xAI',
    'Anthropic',
    'DeepSeek',
    'Google',
    'OpenAI',
    'Alibaba',
    'Meta',
  ];

  // Default model id used for new sessions — pick once randomly per app run
  static final String defaultModelId = _pickDefaultModelId();
  static String _pickDefaultModelId() {
    final ids = all.keys.toList();
    if (ids.isEmpty) return 'anthropic/claude-sonnet-4.5'; // safety fallback
    ids.shuffle(Random());
    return ids.first;
  }

  // Deduplicated: group models by vendor from `all`, preserving insertion order
  static Map<ModelVendor, List<String>> get byVendor =>
      _byVendor ??= _buildByVendor();
  static Map<ModelVendor, List<String>>? _byVendor;
  static Map<ModelVendor, List<String>> _buildByVendor() {
    final map = {for (final v in ModelVendor.values) v: <String>[]};
    // insertion order of `all` is preserved in Dart
    all.forEach((id, meta) {
      map[meta.vendor]!.add(id);
    });
    return map;
  }

  static ModelMeta meta(String id) => all[id] ?? all[defaultModelId]!;

  // Convenience accessor for logo path
  static String logo(String id) => meta(id).logoUrl;
}

// User menu actions
enum UserMenuAction { upgradePlan, customization, settings, help, logout }

enum RowType { newChat, header, item }

// Mock file extensions
const List<String> extensions = ['pdf', 'jpg', 'png', 'docx', 'xlsx'];

String get randomExtension => extensions[Random().nextInt(extensions.length)];

// Local models for dialog grouping
class SessionItem {
  final int index;
  final String title;
  final DateTime updatedAt;
  final bool isFavorite;
  SessionItem({
    required this.index,
    required this.title,
    required this.updatedAt,
    required this.isFavorite,
  });
}

class Section {
  final String title;
  final List<SessionItem> items;
  Section({required this.title, required this.items});
}

class SessionRow {
  final RowType type;
  final String? text;
  final SessionItem? item;

  SessionRow._(this.type, {this.text, this.item});

  factory SessionRow.newChat() => SessionRow._(RowType.newChat);
  factory SessionRow.header(String t) => SessionRow._(RowType.header, text: t);
  factory SessionRow.item(SessionItem it) =>
      SessionRow._(RowType.item, item: it);
}
