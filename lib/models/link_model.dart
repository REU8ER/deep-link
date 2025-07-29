class LinkModel {
  late String slug;
  String? titulo;
  String? descricao;
  String? urlImage;
  String? appPath;
  Map<String, String>? parametrosPersonalizados;
  bool? onlyWeb;

  String? _link;
  String? get link => _link ?? '';

  LinkModel({
    required this.slug,
    this.titulo,
    this.descricao,
    this.urlImage,
    this.parametrosPersonalizados,
    this.appPath,
    this.onlyWeb,
  });

  LinkModel.fromMap(Map<String, dynamic> map) {
    slug = map['slug'];
    titulo = map['titulo'];
    descricao = map['descricao'];
    urlImage = map['urlImage'];
    parametrosPersonalizados = (map['parametrosPersonalizados'] as Map?)?.map(
      (k, v) => MapEntry(k.toString(), v.toString()),
    );
    appPath = map['appPath'];
    onlyWeb = map['onlyWeb'] ?? false;
    _link = map['link'];
  }

  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'titulo': titulo,
      'descricao': descricao,
      'urlImage': urlImage,
      'parametrosPersonalizados': parametrosPersonalizados,
      'appPath': appPath,
      'onlyWeb': onlyWeb,
    };
  }
}
