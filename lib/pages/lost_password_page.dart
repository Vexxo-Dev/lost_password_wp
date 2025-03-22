import 'package:flutter/material.dart';
import '../services/wordpress_service.dart';

class LostPasswordPage extends StatefulWidget {
  final String baseUrl;
  final String consumerKey;
  final String consumerSecret;

  const LostPasswordPage({
    Key? key,
    required this.baseUrl,
    required this.consumerKey,
    required this.consumerSecret,
  }) : super(key: key);

  @override
  State<LostPasswordPage> createState() => _LostPasswordPageState();
}

class _LostPasswordPageState extends State<LostPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  late final WordPressService _wordPressService;

  @override
  void initState() {
    super.initState();
    _wordPressService = WordPressService(
      baseUrl: widget.baseUrl,
      consumerKey: widget.consumerKey,
      consumerSecret: widget.consumerSecret,
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _message = null;
      });

      try {
        final success = await _wordPressService.requestPasswordReset(_emailController.text);
        setState(() {
          _message = success
              ? 'Password reset instructions have been sent to your email.'
              : 'Failed to send password reset instructions. Please try again.';
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _message = 'An error occurred. Please try again later.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Enter your email address and we\'ll send you instructions to reset your password.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Send Reset Instructions'),
              ),
              if (_message != null) ...[
                const SizedBox(height: 16),
                Text(
                  _message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _message!.contains('Failed') ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
} 