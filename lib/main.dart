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
			),
			home: const ChatScreen(),
		);
	}
}

// Classe da tela de chat que tem seus estados, que devem ser gerenciados pelo StatefulWidget
class ChatScreen extends StatefulWidget {
	// Construtor
	const ChatScreen({super.key});

	// Método que cria o estado da tela de chat
	@override
	State<ChatScreen> createState() => _ChatScreenState();
}

// Classe que é o estado da tela de chat
// Essa classe é responsável por gerenciar o estado da tela de chat
class _ChatScreenState extends State<ChatScreen> {
	// Controlador de texto para o campo de mensagem, para ler e limpar o texto
	final TextEditingController _messageController = TextEditingController();

	// Lista de mensagens do chat
	final List<ChatMessage> _messages = [];

	late final GenerativeModel _model;
	late final ChatSession _chat;
	bool isLoading = false;

	// Chave api
	static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

	@override
	void initState() {
		super.initState();
		if (_apiKey.isEmpty) {
			throw Exception('GEMINI_API_KEY não está definida');
		}

		final systemInstruction = Content.system(
			"Você é o Mr. G, um assistente virtual de conhecimento vasto e modos impecáveis. "
			"Suas respostas devem ser sempre EXTREMAMENTE FORMAIS E ERUDITAS. "
			"Utilize um vocabulário rico e estruturas frasais complexas"
			"Tente ter respostas de tamanho moderado, mas não muito curtas"
			"De maneira esporádica e sutil, inclua uma pequena anedota ou um gracejo intelectual ao final de suas respostas, mantendo sempre a compostura."
			"Exemplo de gracejo: '...como diria um elétron entediado, é hora de realizar um salto quântico para o próximo tópico.' "
			"Nunca use gírias ou linguagem casual, somente em gracejos."
		);

		_model = GenerativeModel(
			model: 'gemini-2.0-flash',
			apiKey: _apiKey,
			systemInstruction: systemInstruction,
		);

		_chat = _model.startChat();
	}

	// Lidar com envio de mensagens no chat
	Future<void> _handleSubmitted(String text, {Uint8List? imageBytes}) async {
		if (text.isEmpty && imageBytes == null) {
			return;
		}

		// Limpa o campo de mensagem
		_messageController.clear();
		setState(() {
			isLoading = true;
			_messages.insert(0, ChatMessage(text: text, isUser: true));
		});

		try {
			// Prepara o conteudo da mensagem
			final content = [
				if (imageBytes != null) DataPart("image/jpeg", imageBytes),
				if (text.isNotEmpty) TextPart(text),
			];

			var response = await _chat.sendMessage(Content.multi(content));
			var responseText = response.text;

			if (responseText == null){
				_showError('Erro ao processar a mensagem');
				return;
			}

			setState(() {
				_messages.insert(0, ChatMessage(text: responseText, isUser: false));
			});
		} catch (e) {
			_showError('Erro ao processar a mensagem: ${e.toString()}');
		} finally {
			setState(() {
				isLoading = false;
			});
		}
	}

	// Método para exibir mensagens de erro
	void _showError(String message) {
		showDialog(
			context: context,
			builder: (context) {
				return AlertDialog(
					title: const Text('Oh, céus!'),
					content: SingleChildScrollView(
						child: Text(message),
					),
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

	// Função para pegar uma imagem da galeria
  	Future<void> _pickImage() async {
		final ImagePicker picker = ImagePicker();
		final XFile? image = await picker.pickImage(source: ImageSource.gallery);
		if (image != null) {
			final imageBytes = await image.readAsBytes();
			// Envia a imagem com o texto que estiver no campo
			_handleSubmitted(_messageController.text, imageBytes: imageBytes);
		}
  }

	// Esse método é responsável por construir a interface do usuário
	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Mr. G, O assistente erudito'),
				backgroundColor: Colors.deepPurple.shade100,
			),
			body: Column(
				children: <Widget>[
					// Area onde as mensagens são exibidas
					Expanded(
						child: ListView.builder(
							padding: const EdgeInsets.all(8.0),
							reverse: true, // Inverter a ordem das mensagens (chat comeca de baixo para cima)
							itemCount: _messages.length,
							itemBuilder: (_, int index) => _messages[index],
						),
					),
					const Divider(height: 1.0),
					// Area onde o usuário digita a mensagem
					_buildTextComposer(),
				],
			),
		);
	}

	// Método que cria o campo de texto para digitar a mensagem
	Widget _buildTextComposer() {
		return IconTheme(
			data: IconThemeData(color: Theme.of(context).colorScheme.primary),
			child: Container(
				margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
				child: Row(
					children: <Widget>[
						// Botão para selecionar uma imagem
						IconButton(
							icon: const Icon(Icons.photo_library),
							onPressed: isLoading ? null : _pickImage,
						),

						// Campo de texto para digitar a mensagem
						Expanded(
							child: TextField(
								controller: _messageController,
								onSubmitted: isLoading ? null : (text) => _handleSubmitted(text),
								decoration: const InputDecoration(hintText: 'Enviar uma mensagem para o Mr. G...'),
								enabled: !isLoading, // Desabilita o campo de texto se estiver carregando
							),
						),

						// Botão para enviar a mensagem
						IconButton(
							icon: isLoading ? const CircularProgressIndicator() : const Icon(Icons.send),
							onPressed: () => _handleSubmitted(_messageController.text),
						),
					],
				),
			),
		);
	}
}

// Classe que representa uma mensagem no chat
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
				// Alinha mensagem do usuario a direita e do mr g a esquerda

				mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
				children: <Widget>[
					// Icone do mr g
					if (!isUser)
						const CircleAvatar(child: Text('G')),

					// Espaço entre o icone e a mensagem
					if (!isUser)
						const SizedBox(width: 8.0),

					// Conteudo da mensagem
					Flexible(
						child: Container(
							padding: const EdgeInsets.all(12.0),
							decoration: BoxDecoration(
								color: isUser ? Colors.deepPurple.shade100 : Colors.grey.shade200,
								borderRadius: BorderRadius.circular(8.0),
							),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									if (imageBytes != null)
										Image.memory(imageBytes!, width: 200.0),
									if (imageBytes == null && text.isNotEmpty)
										const SizedBox(height: 8.0),
									if (imageBytes == null && text.isNotEmpty)
										Text(text, style: const TextStyle(fontSize: 16.0)),
								]
							)
						),
					),

					// Espaço entre a mensagem e o icone
					if (isUser)
						const SizedBox(width: 8.0),

					// Icone do usuario
					if (isUser)
						const CircleAvatar(
							child: Icon(Icons.person),
						),

					// Conteudo da mensagem
				],
			),
		);
	}
}
