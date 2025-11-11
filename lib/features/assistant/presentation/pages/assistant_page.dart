import 'package:flutter/material.dart';
import '../../data/faqs.dart';
import '../../data/llm_client.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
// app_text_styles import removed (not used in this file)
import '../../../../core/constants/app_config.dart';

class AssistantPage extends StatefulWidget {
  const AssistantPage({super.key});

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  final List<_Message> _messages = [];
  final _controller = TextEditingController();
  bool _isTyping = false;
  bool _useAi = false;
  String? _apiKey;

  void _send(String text) async {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_Message(text: text.trim(), isUser: true));
      _isTyping = true;
    });
    _controller.clear();

    if (_useAi && _apiKey != null && _apiKey!.isNotEmpty) {
      try {
        final aiReply = await fetchOpenAIReply(_apiKey!, text.trim());
        setState(() {
          _messages.add(_Message(text: aiReply, isUser: false));
          _isTyping = false;
        });
        return;
      } catch (e) {
        // Fallback to local FAQ on error
        final fallback = 'No pude conectar con el servicio de IA: ${e.toString()}. Uso respuesta local.';
        setState(() {
          _messages.add(_Message(text: fallback, isUser: false));
          _isTyping = false;
        });
        // continue to show local answer below
      }
    }

    // Local FAQ fallback
    Future.delayed(AppDimens.durationMedium, () {
      final answer = _findBestAnswer(text.trim().toLowerCase());
      setState(() {
        _messages.add(_Message(text: answer, isUser: false));
        _isTyping = false;
      });
    });
  }

  String _findBestAnswer(String query) {
    // Simple keyword matching: return the first FAQ containing a key.
    for (final entry in pediatricFaqs.entries) {
      if (query.contains(entry.key)) return entry.value;
    }
    // If nothing matched, give a helpful generic answer and suggestion.
    return 'No estoy seguro; podría necesitar más detalles. Puedes especificar la edad del niño, cuánto tiempo lleva el síntoma o si hay fiebre. Si es una emergencia (respiración dificultosa, convulsiones, sangrado incontrolado), busca atención de urgencia.';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<String?> _askForApiKey() async {
    final c = TextEditingController(text: _apiKey ?? '');
    final res = await showDialog<String?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ingresar API key (OpenAI)'),
        content: TextField(controller: c, decoration: const InputDecoration(hintText: 'sk-...'), obscureText: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(null), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(c.text.trim()), child: const Text('Guardar')),
        ],
      ),
    );
    return res;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.defaultAssistantName),
        backgroundColor: AppColors.primary,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingMedium, vertical: AppDimens.paddingSmall),
              child: Row(
                children: [
                  const Text('Usar IA:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: AppDimens.paddingSmall),
                  Switch(value: _useAi, onChanged: (v) async {
                    if (v && (_apiKey == null || _apiKey!.isEmpty)) {
                      final key = await _askForApiKey();
                      if (key == null || key.isEmpty) return;
                      setState(() => _apiKey = key);
                    }
                    setState(() => _useAi = v);
                  }),
                  const SizedBox(width: AppDimens.paddingMedium),
                  if (_apiKey != null && _apiKey!.isNotEmpty)
                    Expanded(child: Text('API: ****' + (_apiKey!.length > 4 ? _apiKey!.substring(_apiKey!.length - 4) : _apiKey!), style: const TextStyle(color: AppColors.textBlack54))),
                  IconButton(
                    onPressed: () async {
                      final key = await _askForApiKey();
                      if (key != null) setState(() => _apiKey = key);
                    },
                    icon: const Icon(Icons.vpn_key),
                    tooltip: 'Ingresar/editar API key',
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppDimens.paddingMedium),
                itemCount: _messages.length,
                itemBuilder: (context, i) {
                  final m = _messages[i];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: m.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        if (!m.isUser)
                          const CircleAvatar(radius: 16, backgroundColor: AppColors.primary, child: Icon(Icons.local_hospital_rounded, color: AppColors.textWhite, size: 18)),
                        const SizedBox(width: AppDimens.paddingSmall),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingMedium, vertical: AppDimens.paddingSmall),
                            decoration: BoxDecoration(
                              color: m.isUser ? AppColors.textWhite : const Color(0xFFF8F3F1),
                              borderRadius: BorderRadius.circular(AppDimens.borderRadiusLarge),
                              boxShadow: [BoxShadow(color: AppColors.overlayLight, blurRadius: 6)],
                            ),
                            child: Text(m.text, style: const TextStyle(color: Colors.black87)),
                          ),
                        ),
                        const SizedBox(width: AppDimens.paddingSmall),
                        if (m.isUser)
                          const CircleAvatar(radius: 16, backgroundColor: Colors.black12, child: Icon(Icons.person, color: Colors.black54, size: 18)),
                      ],
                    ),
                  );
                },
              ),
            ),
            if (_isTyping)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppDimens.paddingMedium, vertical: AppDimens.paddingSmall),
                child: Align(alignment: Alignment.centerLeft, child: Text(AppConfig.typingIndicatorText, style: TextStyle(color: Colors.black54))),
              ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingSmall, vertical: AppDimens.paddingSmall),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _send,
                      decoration: InputDecoration(
                        hintText: AppConfig.chatInitialMessage,
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: AppDimens.paddingMedium, vertical: AppDimens.paddingMedium),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.borderRadiusMedium), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppDimens.paddingSmall),
                  ElevatedButton(
                    onPressed: () => _send(_controller.text),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isUser;
  _Message({required this.text, required this.isUser});
}
