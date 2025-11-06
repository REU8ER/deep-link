# Deep Link

Flutter package para gerenciamento de deep links com integração a API backend para criar, buscar e escutar links dinâmicos.

## Features

- ✅ Criar deep links via API com autenticação por token
- ✅ Receber e processar deep links quando o app é aberto
- ✅ Suporte a múltiplos domínios e prefixos organizacionais
- ✅ Parsing automático de URLs (HTTPS e custom schemes)
- ✅ Configuração de destinos por plataforma (Android/iOS/Web)
- ✅ Parâmetros personalizados para tracking e analytics
- ✅ Três modos de comportamento: Manual, Automático e Inteligente
- ✅ Suporte a custom schemes com fallback offline
- ✅ URL-safe: separador `~-` não requer encoding

## Índice

1. [Instalação](#instalação)
2. [Configuração Inicial](#configuração-inicial)
   - [Android](#configuração-android)
   - [iOS](#configuração-ios)
3. [Guia Rápido](#guia-rápido)
4. [Uso Completo](#uso-completo)
5. [Referência da API](#referência-da-api)

---

## Instalação

### 1. Adicione o pacote ao seu `pubspec.yaml`:

```yaml
dependencies:
  deep_link: ^0.0.4
```

### 2. Instale as dependências:

```bash
flutter pub get
```

---

## Configuração Inicial

### Configuração Android

#### 1. Configure o AndroidManifest.xml

Edite o arquivo `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest>
  <application>
    <activity
      android:name=".MainActivity"
      android:launchMode="singleTask"
      android:taskAffinity="com.example.app">
      
      <!-- Deep Link com HTTPS (App Links) -->
      <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data
          android:scheme="https"
          android:host="exemplo.com" />
      </intent-filter>

      <!-- Deep Link com Custom Scheme -->
      <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="meuapp" />
      </intent-filter>
      
    </activity>
  </application>
</manifest>
```

#### 2. Entenda as opções de `launchMode`:

| Opção | Comportamento | Quando usar |
|-------|---------------|-------------|
| **`singleTask`** | Abre o app em uma nova task, limpando a pilha anterior | ✅ **Recomendado** - O app abre limpo, substituindo o app anterior |
| **`singleTop`** (padrão) | Reutiliza a instância atual se existir no topo da pilha | Quando quiser que o deep link abra por cima do app atual |

**Exemplo com `singleTask`:**
```xml
<activity
  android:name=".MainActivity"
  android:launchMode="singleTask"
  android:taskAffinity="com.example.app">
```

**Exemplo com `singleTop` (padrão do Flutter):**
```xml
<activity
  android:name=".MainActivity"
  android:launchMode="singleTop">
```

⚠️ **Importante**: 
- Use `singleTask` + `taskAffinity` se quiser que o app aberto pelo deep link **substitua** o app atual
- Use `singleTop` se quiser que o deep link abra **por cima** do app atual (mantém navegação anterior)

#### 3. Configure o App Links (opcional, mas recomendado)

Para que links HTTPS abram seu app automaticamente sem dialog de escolha:

1. Crie o arquivo `.well-known/assetlinks.json` no seu domínio:

```json
[{
  "relation": ["delegate_permission/common.handle_all_urls"],
  "target": {
    "namespace": "android_app",
    "package_name": "com.example.app",
    "sha256_cert_fingerprints": [
      "SHA256_DO_SEU_CERTIFICADO"
    ]
  }
}]
```

2. Acesse em: `https://seudominio.com/.well-known/assetlinks.json`

---

### Configuração iOS

#### 1. Configure o Info.plist

Edite o arquivo `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLName</key>
    <string>com.example.app</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>meuapp</string>
    </array>
  </dict>
</array>
```

#### 2. Configure Universal Links (opcional, mas recomendado)

1. Adicione o domínio associado em `ios/Runner/Runner.entitlements`:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
  <string>applinks:exemplo.com</string>
</array>
```

2. Crie o arquivo `.well-known/apple-app-site-association` no seu domínio:

```json
{
  "applinks": {
    "apps": [],
    "details": [{
      "appID": "TEAM_ID.com.example.app",
      "paths": ["*"]
    }]
  }
}
```

3. Acesse em: `https://seudominio.com/.well-known/apple-app-site-association`

---

## Guia Rápido

### Do zero até criar e receber um deep link em 5 passos:

#### Passo 1: Instale o pacote

```yaml
dependencies:
  deep_link: ^0.0.4
```

#### Passo 2: Configure o Android/iOS (veja [Configuração Inicial](#configuração-inicial))

#### Passo 3: Inicialize no `main.dart`

```dart
import 'package:deep_link/deep_link.dart';

void main() {
  // Inicializar com token de autenticação
  DeepLink.init(
    baseUrl: 'https://us-central1-deep-link-hub.cloudfunctions.net',
    apiToken: 'SEU_TOKEN_AQUI', // Use Firebase Remote Config em produção
  );
  
  runApp(MyApp());
}
```

#### Passo 4: Escute deep links no app

```dart
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _deepLink = DeepLink();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    // Escuta links enquanto app está aberto
    _deepLink.listen((linkData) {
      print('Deep link recebido: ${linkData.appPath}');
      
      // Navegar para a tela correta
      if (linkData.appPath?.startsWith('produto/') == true) {
        final id = linkData.appPath!.split('/').last;
        // Navigator.push(...);
      }
    });

    // Verifica se app foi aberto via deep link
    _deepLink.checkInitialLink((linkData) {
      print('App aberto via deep link: ${linkData.appPath}');
      // Processar link inicial
    });
  }

  @override
  void dispose() {
    _deepLink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}
```

#### Passo 5: Crie um deep link

```dart
// Em qualquer lugar do app
final link = await DeepLink.createLink(
  LinkModel(
    dominio: 'exemplo.com',
    prefixo: 'p',
    slug: 'produto-123',
    titulo: 'Meu Produto',
    descricao: 'Confira este produto incrível',
    scheme: 'meuapp',
    appPath: 'produto/123',
  ),
);

print('Link criado: https://exemplo.com/p/produto-123');
print('ID: ${link.id}'); // exemplo.com~-p~-produto-123

// Compartilhar o link
Share.share('https://exemplo.com/p/produto-123');
```

✅ **Pronto!** Agora quando alguém clicar no link `https://exemplo.com/p/produto-123`, o app será aberto e você receberá os dados no `listen()`.

---

## Uso Completo

---

## Uso Completo

### 1. Inicialização (com Token de Autenticação)

O token é **obrigatório** para criar links e garante que apenas apps autorizados possam criar links no sistema.

```dart
import 'package:deep_link/deep_link.dart';

// 1. Inicializar (uma vez no app)
void main() {
  DeepLink.init(
    baseUrl: 'https://us-central1-deep-link-hub.cloudfunctions.net',
    apiToken: FirebaseRemoteConfig.instance.getString('deep_link_token'),
  );
  runApp(MyApp());
}
```

⚠️ **IMPORTANTE**: 
- O `apiToken` deve ser mantido em **segurança**
- Nunca commite o token no código
- Use variáveis de ambiente ou Firebase Remote Config para armazená-lo
- O token é validado pelo backend em cada requisição de criação de link

### 2. Criar um Link (Requer Autenticação)

```dart
// Criar link de produto
final link = await DeepLink.createLink(
  LinkModel(
    dominio: 'exemplo.com',
    prefixo: 'p', // prefixo de produtos
    slug: 'produto-123',
    titulo: 'Produto Incrível',
    descricao: 'Confira este produto',
    urlImage: 'https://exemplo.com/produto.jpg',
    urlDesktop: 'https://meusite.com/produtos/123',
    urlPlayStore: 'https://play.google.com/store/apps/details?id=com.meuapp',
    urlAppStore: 'https://apps.apple.com/app/id123456789',
    androidPackage: 'com.meuapp',
    iosBundleId: 'com.meuapp.ios',
    scheme: 'meuapp',
    appPath: 'produto/123',
    comportamento: ComportamentoLink.automatico, // Novo! Define o comportamento do link
    parametrosPersonalizados: {
      'utm_source': 'app',
      'promo_id': 'black-friday',
    },
  ),
);

print('Link criado: ${link.id}');
// Link ID: exemplo.com~-p~-produto-123
// Link URL: https://exemplo.com/p/produto-123
```

#### Comportamentos do Link

O campo `comportamento` define como o link se comporta quando acessado:

```dart
// Manual (padrão): Mostra página com botão para o usuário escolher
comportamento: ComportamentoLink.manual

// Automático: Abre o app imediatamente (similar ao Branch.io)
comportamento: ComportamentoLink.automatico

// Inteligente: Detecta a origem (WhatsApp, navegador, etc) e escolhe automaticamente
comportamento: ComportamentoLink.inteligente
```

### 3. Receber Deep Links (Não Requer Token)

A recepção de links é **pública** e não precisa de autenticação:

```dart
void initDeepLinks() {
  final deepLink = DeepLink();
  
  // Escutar links enquanto app está rodando
  deepLink.listen((linkData) {
    print('Deep link recebido:');
    print('- Domínio: ${linkData.dominio}');
    print('- Prefixo: ${linkData.prefixo}');
    print('- Slug: ${linkData.slug}');
    print('- App Path: ${linkData.appPath}');
    
    // Navegar para tela correta
    if (linkData.appPath == 'produto/123') {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ProdutoScreen(id: '123'),
      ));
    }
  });
  
  // Verificar se app foi aberto via deep link
  deepLink.checkInitialLink((linkData) {
    // Processar link inicial
  });
}

@override
void dispose() {
  DeepLink().dispose(); // Importante para evitar memory leak
  super.dispose();
}
```

**Como funciona:**
- `listen()` - Escuta deep links enquanto o app está aberto (foreground/background)
- `checkInitialLink()` - Captura o link que abriu o app quando ele estava fechado
- Suporta **HTTPS** deep links e **custom schemes**

### 4. Buscar Link Existente (Não Requer Token)

```dart
try {
  final link = await DeepLink.getLink('exemplo.com~-p~-produto-123');
  print('Título: ${link.titulo}');
  print('Descrição: ${link.descricao}');
} catch (e) {
  print('Erro: $e');
}
```

## Segurança e Autenticação

### Como Funciona o Token?

1. **Backend gera o token** - O sistema backend (Firebase Functions) gera tokens únicos para cada app autorizado
2. **App armazena com segurança** - Use Firebase Remote Config, variáveis de ambiente, ou secure storage
3. **Token é enviado no header** - Em cada requisição POST para criar links, o token é enviado como `Authorization: Bearer {token}`
4. **Backend valida** - O backend verifica se o token é válido e se o app tem permissão para criar links no domínio especificado

### Tratamento de Erros de Autenticação

```dart
try {
  final link = await DeepLink.createLink(meuLink);
  print('✅ Link criado com sucesso');
} on Exception catch (e) {
  if (e.toString().contains('Token de autenticação inválido')) {
    // Token expirado ou inválido - solicitar novo token
    print('❌ Token inválido - solicitar novo');
  } else if (e.toString().contains('Permissão negada')) {
    // App não tem permissão para este domínio
    print('❌ Sem permissão para criar link neste domínio');
  } else if (e.toString().contains('Token não inicializado')) {
    // Esqueceu de chamar DeepLink.init()
    print('❌ DeepLink não foi inicializado');
  }
}
```

### Onde NÃO usar o Token

O token **não é necessário** para:
- ✅ Buscar links existentes (`getLink()`)
- ✅ Receber deep links (`listen()`, `checkInitialLink()`)
- ✅ Navegar pelo app usando deep links

O token é **obrigatório** apenas para:
- 🔒 Criar novos links (`createLink()`)
- 🔒 Atualizar links (quando implementado)
- 🔒 Deletar links (quando implementado)

---

## Referência da API

### Formato do ID do Link

Os links seguem o formato: `dominio~-prefixo~-slug`

O separador `~-` (til-hífen) foi escolhido por ser **URL-safe** e não requerer encoding.

**Exemplos:**
- `exemplo.com~-p~-produto-123` → https://exemplo.com/p/produto-123
- `exemplo.com~-~-sem-prefixo` → https://exemplo.com/sem-prefixo
- `meusite.com~-i~-convite-user` → https://meusite.com/i/convite-user

### Suporte a Custom Schemes

O pacote suporta múltiplos formatos de deep links:

#### 1. HTTPS Deep Link (Recomendado)
```
https://exemplo.com/promo/amigo
```
- Funciona em todos os dispositivos
- Requer configuração de App Links/Universal Links
- Busca dados na API automaticamente

#### 2. Custom Scheme com ID no Path
```
meuapp://link/exemplo.com~-promo~-amigo
```
- Abre o app diretamente
- Busca dados na API pelo ID

#### 3. Custom Scheme com Query Params (Fallback Offline)
```
meuapp://open?id=exemplo.com~-promo~-amigo&appPath=produto/123&titulo=Promo
```
- Funciona offline
- Dados básicos no próprio link
- Fallback quando API não está disponível

### ComportamentoLink Enum

Define como o link se comporta quando acessado:

| Modo | Valor | Comportamento |
|------|-------|---------------|
| **Manual** | `manual` | (Padrão) Mostra página com botão para usuário escolher |
| **Automático** | `automatico` | Abre o app imediatamente, sem interação |
| **Inteligente** | `inteligente` | Detecta origem (WhatsApp, navegador) e escolhe automaticamente |

```dart
// Usar no LinkModel
LinkModel(
  // ... outros campos
  comportamento: ComportamentoLink.automatico,
);
```

### Campos do LinkModel

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| `dominio` | String | ✅ Sim | Domínio do link (ex: exemplo.com) |
| `slug` | String | ✅ Sim | Identificador único do link |
| `titulo` | String | ✅ Sim | Título para Open Graph/compartilhamento |
| `prefixo` | String? | Não | Prefixo organizacional (ex: p, i, promo) |
| `descricao` | String? | Não | Descrição para Open Graph |
| `urlImage` | String? | Não | URL da imagem de preview |
| `urlDesktop` | String? | Não | URL de destino para desktop/web |
| `urlPlayStore` | String? | Não | URL da Play Store |
| `urlAppStore` | String? | Não | URL da App Store |
| `androidPackage` | String? | Não | Package name do app Android |
| `iosBundleId` | String? | Não | Bundle ID do app iOS |
| `scheme` | String? | Não | Custom scheme (ex: meuapp) |
| `appPath` | String? | Não | Caminho interno do app (ex: produto/123) |
| `onlyWeb` | bool | Não | Se true, sempre redireciona para web |
| `comportamento` | ComportamentoLink | Não | Modo de abertura (padrão: manual) |
| `parametrosPersonalizados` | Map? | Não | Query params extras (UTM, etc) |

---

## Troubleshooting

### Deep links não estão abrindo o app

**Android:**
- ✅ Verifique se o `android:host` no AndroidManifest.xml corresponde ao seu domínio
- ✅ Confirme que o `android:scheme` está configurado (https para App Links, ou custom scheme)
- ✅ Para App Links, verifique se o arquivo `assetlinks.json` está acessível
- ✅ Teste com: `adb shell am start -a android.intent.action.VIEW -d "https://seudominio.com/p/produto-123"`

**iOS:**
- ✅ Verifique se o `CFBundleURLSchemes` no Info.plist está configurado
- ✅ Para Universal Links, confirme o arquivo `apple-app-site-association` está acessível
- ✅ Teste em dispositivo físico (Simulator pode não funcionar corretamente)

### App abre mas não recebe os dados do link

- ✅ Confirme que você chamou `deepLink.listen()` no `initState()`
- ✅ Verifique se você chamou `deepLink.checkInitialLink()` para links que abrem o app fechado
- ✅ Não esqueça de chamar `deepLink.dispose()` no `dispose()`

### Erro "Token não inicializado"

- ✅ Certifique-se de chamar `DeepLink.init()` no `main()` antes de `runApp()`
- ✅ Verifique se o `apiToken` não está vazio ou null

### Link criado mas não funciona

- ✅ Verifique se o link foi criado com sucesso (sem erros)
- ✅ Confirme que o domínio no `LinkModel` corresponde ao configurado no AndroidManifest/Info.plist
- ✅ Teste o link em um dispositivo real (não apenas no emulador)

---

## Contribuindo

Issues e Pull Requests são bem-vindos!

### Licença

MIT License
