class LinkModel {
  final String slug;
  final String? titulo;
  final String? descricao;
  final String? urlImage;
  final Map<String, String>? parametrosPersonalizados;
  final bool? onlyWeb;

  LinkModel({
    required this.slug,
    this.titulo,
    this.descricao,
    this.urlImage,
    this.parametrosPersonalizados,
    this.onlyWeb,
  });

  factory LinkModel.fromJson(Map<String, dynamic> json) {
    return LinkModel(
      slug: json['slug'],
      titulo: json['titulo'],
      descricao: json['descricao'],
      urlImage: json['urlImage'],
      parametrosPersonalizados: (json['parametrosPersonalizados'] as Map?)?.map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      ),
      onlyWeb: json['onlyWeb'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slug': slug,
      'titulo': titulo,
      'descricao': descricao,
      'urlImage': urlImage,
      'parametrosPersonalizados': parametrosPersonalizados,
      'onlyWeb': onlyWeb,
    };
  }
}
