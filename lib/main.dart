import 'package:flutter/material.dart';

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

	// Lidar com envio de mensagens no chat
	void _handleSubmitted(String text) {
		// Limpa o campo de mensagem
		_messageController.clear();

		setState(() {
			_messages.insert(0, ChatMessage(text: text, isUser: true));
		});
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
				margin: const EdgeInsets.symmetric(horizontal: 8.0),
				child: Row(
					children: <Widget>[
						// Campo de texto para digitar a mensagem
						Expanded(
							child: TextField(
								controller: _messageController,
								onSubmitted: _handleSubmitted,
								decoration: const InputDecoration(hintText: 'Enviar uma mensagem para o Mr. G...'),
							),
						),
						// Botão para enviar a mensagem
						IconButton(
							icon: const Icon(Icons.send),
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
	const ChatMessage({super.key, required this.text, required this.isUser});

	final String text;
	final bool isUser;

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
						const CircleAvatar(child: Text('Mr. G')),

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
							child: Text(text, style: const TextStyle(fontSize: 16.0)),
						),
					),

					// Espaço entre a mensagem e o icone
					if (isUser)
						const SizedBox(width: 8.0),

					// Icone do usuario
					if (isUser)
						const CircleAvatar(child: Text('Você'),
						),

					// Conteudo da mensagem
				],
			),
		);
	}
}
