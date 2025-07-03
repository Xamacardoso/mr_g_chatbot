# 🤖 Mr. G Chatbot

> Mr. G é um assistente virtual erudito, construído em Flutter, que utiliza a API Gemini da Google para responder perguntas de forma extremamente formal, com vocabulário rico e até mesmo gracejos intelectuais. O app permite enviar mensagens de texto e imagens, recebendo respostas inteligentes e contextualizadas.

## 💡 Recursos

- Chat com interface moderna e responsiva
- Suporte a envio de imagens (análise de imagem pelo modelo Gemini)
- Respostas em streaming (texto aparece enquanto o bot "digita")
- Mensagens do usuário e do bot bem diferenciadas
- Preview de imagem antes do envio, com opção de remover
- Mensagens do Mr. G sempre formais e eruditas


## ⬇️ Instalação

1. **Clone o repositório:**
   ```sh
   git clone https://github.com/seu-usuario/mr_g_chatbot.git
   cd mr_g_chatbot
   ```
2. **Instale as dependências:**
   ```sh
   flutter pub get
   ```
3. **Execute o app com sua chave de API:**
   ```sh
   flutter run --dart-define=GEMINI_API_KEY=SUA_CHAVE_API
   ```
   - Substitua `your_google_gemini_api_key` pela sua chave da [Google AI Studio](https://aistudio.google.com/app/apikey)

## 💻 Como usar

- Digite sua mensagem no campo inferior e pressione o botão de enviar.
- Para enviar uma imagem, clique no ícone de galeria, selecione a imagem e envie junto com (ou sem) texto.
- O Mr. G responderá de forma formal, podendo analisar imagens e texto.
- O balão do Mr. G mostra um cursor piscando enquanto ele está "digitando".

## 🔗 Dependências principais

- [flutter](https://flutter.dev/)
- [google_generative_ai](https://pub.dev/packages/google_generative_ai)
- [image_picker](https://pub.dev/packages/image_picker)

## 🖌️ Personalização

- O modelo Gemini pode ser alterado na inicialização do `GenerativeModel`.


## 🙋 Créditos

> Desenvolvido por [Xamã Cardoso](https://github.com/Xamacardoso) com Flutter e Gemini API.
