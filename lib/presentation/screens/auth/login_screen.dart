import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toktok/presentation/providers/auth_provider.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isRegistering = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if ( !_formKey.currentState!.validate() ) return;

    final auth = context.read<AuthProvider>();
    final email = _emailController.text;
    final password = _passwordController.text;

    isRegistering
      ? auth.register( email, password )
      : auth.login( email, password );
  }

  @override
  Widget build(BuildContext context) {

    final auth = context.watch<AuthProvider>();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints( maxWidth: 400 ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    const Icon( Icons.play_circle_fill, size: 72 ),
                    const SizedBox( height: 12 ),
                    Text( 'TokTik', textAlign: TextAlign.center, style: textTheme.headlineMedium ),
                    const SizedBox( height: 8 ),
                    Text(
                      isRegistering ? 'Crea tu cuenta' : 'Inicia sesión para continuar',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox( height: 32 ),

                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [ AutofillHints.email ],
                      decoration: const InputDecoration( labelText: 'Correo', border: OutlineInputBorder() ),
                      validator: (value) => ( value == null || !value.contains('@') )
                        ? 'Escribe un correo válido'
                        : null,
                    ),
                    const SizedBox( height: 16 ),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration( labelText: 'Contraseña', border: OutlineInputBorder() ),
                      validator: (value) => ( value == null || value.length < 6 )
                        ? 'Mínimo 6 caracteres'
                        : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox( height: 16 ),

                    if ( auth.errorMessage != null )
                      Padding(
                        padding: const EdgeInsets.only( bottom: 16 ),
                        child: Text(
                          auth.errorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle( color: Theme.of(context).colorScheme.error ),
                        ),
                      ),

                    FilledButton(
                      onPressed: auth.isLoading ? null : _submit,
                      child: auth.isLoading
                        ? const SizedBox( height: 20, width: 20, child: CircularProgressIndicator( strokeWidth: 2 ) )
                        : Text( isRegistering ? 'Registrarme' : 'Entrar' ),
                    ),
                    const SizedBox( height: 8 ),

                    TextButton(
                      onPressed: () => setState(() => isRegistering = !isRegistering ),
                      child: Text( isRegistering
                        ? '¿Ya tienes cuenta? Inicia sesión'
                        : '¿No tienes cuenta? Regístrate' ),
                    ),

                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
