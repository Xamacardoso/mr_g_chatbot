import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() {
  runApp(const MrGChatApp());
}

// Classe principal da aplicação
class MrGChatApp extends StatelessWidget {
  const MrGChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MrG Chat',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        // Adicionando um tema escuro opcional (você pode alterná-lo no futuro)
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        colorScheme: ColorScheme.dark(
          primary: Colors.deepPurple.shade300,
          secondary: Colors.deepPurple.shade300,
        ),
      ),
      themeMode: ThemeMode.light, // Mude para ThemeMode.dark ou ThemeMode.system
      home: const ChatScreen(),
    );
  }
}

// Classe da tela de chat
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];

  late final GenerativeModel _model;
  late final ChatSession _chat;
  bool isLoading = false;
  Uint8List? _imageBytesPreview;

  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  @override
  void initState() {
    super.initState();
    if (_apiKey.isEmpty) {
      // Em um app real, mostre um diálogo de erro
      throw Exception('GEMINI_API_KEY não está definida');
    }

    final systemInstruction = Content.system(
        "Você é o Mr. G, um assistente virtual de conhecimento vasto e modos impecáveis. "
        "Suas respostas devem ser sempre EXTREMAMENTE FORMAIS E ERUDITAS. "
        "Utilize um vocabulário rico e estruturas frasais complexas"
        "Tente ter respostas de tamanho moderado, mas não muito curtas e nem muito longas"
        "De maneira esporádica e sutil, inclua uma pequena anedota ou um gracejo intelectual ao final de suas respostas, mantendo sempre a compostura."
        "Exemplo de gracejo: '...como diria um elétron entediado, é hora de realizar um salto quântico para o próximo tópico.' "
        "Nunca use gírias ou linguagem casual, somente em gracejos.");

    _model = GenerativeModel(
      // ALTERADO: Usando um nome de modelo estável e conhecido.
      model: 'gemini-1.5-flash-latest',
      apiKey: _apiKey,
      systemInstruction: systemInstruction,
    );

    _chat = _model.startChat();
  }

  // ALTERADO: Lidar com envio de mensagens com STREAMING
  Future<void> _handleSubmitted(String text) async {
    if (text.isEmpty && _imageBytesPreview == null) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    final imageBytesToSend = _imageBytesPreview;
    _messageController.clear();

    // Adiciona a mensagem do usuário à lista e limpa o preview da imagem
    setState(() {
      _messages.insert(0, ChatMessage(text: text, isUser: true, imageBytes: imageBytesToSend));
      _imageBytesPreview = null;
    });

    // Adiciona um balão de mensagem VAZIO para o Mr. G. É aqui que o texto do stream será construído.
    setState(() {
      _messages.insert(0, ChatMessage(text: "", isUser: false));
    });

    // Prepara o conteúdo para a API
    final content = [
      if (imageBytesToSend != null) DataPart("image/jpeg", imageBytesToSend),
      if (text.isNotEmpty) TextPart(text),
    ];

    try {
      // Inicia o stream
      final stream = _chat.sendMessageStream(Content.multi(content));
      String fullResponseText = "";

      // Ouve o stream e atualiza o balão do Mr. G a cada pedaço de texto
      await for (var response in stream) {
        var chunk = response.text ?? "";
        fullResponseText += chunk;

        setState(() {
          // Substitui o balão do Mr. G (que está em _messages[0]) por uma nova instância com o texto atualizado.
          _messages[0] = ChatMessage(text: fullResponseText, isUser: false);
        });
      }
    } catch (e) {
      _showError('Ocorreu um contratempo em meus circuitos: ${e.toString()}');
      // Se der erro, remove o balão vazio do Mr. G que foi adicionado
      setState(() {
        if (_messages.isNotEmpty && !_messages.first.isUser && _messages.first.text.isEmpty) {
          _messages.removeAt(0);
        }
      });
    } finally {
      // Reativa a UI quando o stream termina
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Oh, céus!'),
          content: SingleChildScrollView(child: Text(message)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Compreendo'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final imageBytes = await image.readAsBytes();
      setState(() {
        _imageBytesPreview = imageBytes;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mr. G, O Assistente Erudito'),
        backgroundColor: Colors.deepPurple.shade100,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 0, 0, 0),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (_, int index) => _messages[index],
            ),
          ),
          const Divider(height: 1.0),
          if (_imageBytesPreview != null) _buildImagePreview(),
          _buildTextComposer(),
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(30.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.photo_library, color: Theme.of(context).colorScheme.primary),
            onPressed: isLoading ? null : _pickImage,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              onSubmitted: isLoading ? null : _handleSubmitted,
              decoration: const InputDecoration.collapsed(
                hintText: 'Dirija-se ao Mr. G...',
              ),
              enabled: !isLoading,
            ),
          ),
          IconButton(
            icon: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.0, color: Theme.of(context).colorScheme.primary),
                  )
                : Icon(Icons.send, color: Theme.of(context).colorScheme.primary),
            onPressed: isLoading ? null : () => _handleSubmitted(_messageController.text),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    // Seu widget _buildImagePreview não precisa de alterações.
    // Ele já funciona perfeitamente com a nova lógica.
    if (_imageBytesPreview == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Imagem selecionada para análise',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
                ),
                const SizedBox(height: 16.0),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.0),
                  child: Image.memory(
                    _imageBytesPreview!,
                    width: 80.0,
                    height: 80.0,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.cancel, color: Colors.black54),
            onPressed: () {
              setState(() {
                _imageBytesPreview = null;
              });
            },
          ),
        ],
      ),
    );
  }
}

// Lógica para mostrar o cursor ou o texto
class ChatMessage extends StatelessWidget {
  const ChatMessage({
    super.key,
    required this.text,
    required this.isUser,
    this.imageBytes,
  });

  final String text;
  final bool isUser;
  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: <Widget>[
          if (!isUser) const CircleAvatar(child: Text('G')),
          if (!isUser) const SizedBox(width: 8.0),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: BoxDecoration(
                color: isUser ? Colors.deepPurple.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageBytes != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Image.memory(
                          imageBytes!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  
                  // LÓGICA ALTERADA AQUI
                  if (text.isEmpty && !isUser)
                    // Se a mensagem for do Mr. G e o texto estiver vazio, mostra o cursor
                    const BlinkingCursor()
                  else
                    // Caso contrário, mostra o texto
                    Text(text, style: const TextStyle(fontSize: 16.0)),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8.0),
          if (isUser) const CircleAvatar(child: Icon(Icons.person)),
        ],
      ),
    );
  }
}

// Um cursor que pisca para o efeito "digitando"
class BlinkingCursor extends StatefulWidget {
  const BlinkingCursor({super.key});

  @override
  State<BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<BlinkingCursor> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true); // Faz a animação repetir (piscar)
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 5,
        height: 18,
        color: Colors.black54,
        margin: const EdgeInsets.symmetric(vertical: 2.0),
      ),
    );
  }
}