class LinkModel {
  String? id;
  late String dominio;
  String? prefixo;
  late String slug;

  String? titulo;
  String? descricao;
  String? urlImage;

  String? urlDesktop;
  String? urlPlayStore;
  String? urlAppStore;

  String? androidPackage;
  String? iosBundleId;
  String? scheme;
  String? appPath;

  Map<String, dynamic>? parametrosPersonalizados;

  bool onlyWeb;
  late ComportamentoLink comportamento;

  LinkModel({
    this.id,
    required this.dominio,
    this.prefixo,
    required this.slug,
    this.titulo,
    this.descricao,
    this.urlImage,
    this.urlDesktop,
    this.urlPlayStore,
    this.urlAppStore,
    this.androidPackage,
    this.iosBundleId,
    this.scheme,
    this.appPath,
    this.parametrosPersonalizados,
    this.onlyWeb = false,
    this.comportamento = ComportamentoLink.manual,
  });

  LinkModel.fromMap(Map<String, dynamic> map)
    : id = map['id'],
      dominio = map['dominio'] ?? '',
      prefixo = map['prefixo'],
      slug = map['slug'] ?? '',
      titulo = map['titulo'],
      descricao = map['descricao'],
      urlImage = map['urlImage'],
      urlDesktop = map['urlDesktop'],
      urlPlayStore = map['urlPlayStore'],
      urlAppStore = map['urlAppStore'],
      androidPackage = map['androidPackage'],
      iosBundleId = map['iosBundleId'],
      scheme = map['scheme'],
      appPath = map['appPath'],
      parametrosPersonalizados = map['parametrosPersonalizados'] != null
          ? Map<String, dynamic>.from(map['parametrosPersonalizados'])
          : null,
      onlyWeb = map['onlyWeb'] ?? false,
      comportamento = ComportamentoLink.fromString(map['comportamento']);

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'dominio': dominio, 'slug': slug};

    if (id != null) json['id'] = id;
    if (prefixo != null) json['prefixo'] = prefixo;
    if (titulo != null) json['titulo'] = titulo;
    if (descricao != null) json['descricao'] = descricao;
    if (urlImage != null) json['urlImage'] = urlImage;
    if (urlDesktop != null) json['urlDesktop'] = urlDesktop;
    if (urlPlayStore != null) json['urlPlayStore'] = urlPlayStore;
    if (urlAppStore != null) json['urlAppStore'] = urlAppStore;
    if (androidPackage != null) json['androidPackage'] = androidPackage;
    if (iosBundleId != null) json['iosBundleId'] = iosBundleId;
    if (scheme != null) json['scheme'] = scheme;
    if (appPath != null) json['appPath'] = appPath;
    if (parametrosPersonalizados != null) {
      json['parametrosPersonalizados'] = parametrosPersonalizados;
    }
    json['onlyWeb'] = onlyWeb;
    json['comportamento'] = comportamento.valor;

    return json;
  }
}

enum ComportamentoLink {
  manual(
    'manual',
    'Manual (padrão)',
    'Mostra uma página com botão para o usuário escolher',
  ),

  automatico(
    'automatico',
    'Automático',
    'Abre o app imediatamente sem intervenção do usuário',
  ),

  inteligente(
    'inteligente',
    'Inteligente',
    'Detecta a origem e escolhe automaticamente o melhor comportamento',
  );

  final String valor;
  final String label;
  final String descricao;

  const ComportamentoLink(this.valor, this.label, this.descricao);

  static ComportamentoLink fromString(String? valor) {
    switch (valor) {
      case 'automatico':
        return ComportamentoLink.automatico;
      case 'inteligente':
        return ComportamentoLink.inteligente;
      case 'manual':
      default:
        return ComportamentoLink.manual;
    }
  }

  static ComportamentoLink get padrao => ComportamentoLink.manual;

  @override
  String toString() => valor;
}
