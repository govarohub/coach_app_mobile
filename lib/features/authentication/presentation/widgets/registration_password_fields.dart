import 'package:flutter/material.dart';

class RegistrationPasswordFields extends StatefulWidget {
  const RegistrationPasswordFields({
    super.key,
    required this.passwordController,
    required this.confirmationController,
  });

  final TextEditingController passwordController;
  final TextEditingController confirmationController;

  @override
  State<RegistrationPasswordFields> createState() =>
      _RegistrationPasswordFieldsState();
}

class _RegistrationPasswordFieldsState
    extends State<RegistrationPasswordFields> {
  static const _minimumPasswordLength = 6;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: widget.passwordController,
          obscureText: _obscurePassword,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: 'Contraseña',
            suffixIcon: IconButton(
              tooltip: _obscurePassword
                  ? 'Mostrar contraseña'
                  : 'Ocultar contraseña',
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.length < _minimumPasswordLength) {
              return 'La contraseña debe tener al menos 6 caracteres.';
            }

            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: widget.confirmationController,
          obscureText: _obscureConfirmation,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            labelText: 'Repetir contraseña',
            suffixIcon: ListenableBuilder(
              listenable: Listenable.merge([
                widget.passwordController,
                widget.confirmationController,
              ]),
              builder: (context, child) {
                final password = widget.passwordController.text;
                final confirmation = widget.confirmationController.text;
                final valid = password.length >= _minimumPasswordLength &&
                    password == confirmation;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (confirmation.isNotEmpty)
                      Icon(
                        valid ? Icons.check_circle : Icons.cancel,
                        color: valid ? Colors.green.shade700 : Colors.red.shade700,
                        semanticLabel: valid
                            ? 'Contraseñas válidas y coincidentes'
                            : 'Contraseñas no válidas o diferentes',
                      ),
                    IconButton(
                      tooltip: _obscureConfirmation
                          ? 'Mostrar contraseña repetida'
                          : 'Ocultar contraseña repetida',
                      onPressed: () {
                        setState(() {
                          _obscureConfirmation = !_obscureConfirmation;
                        });
                      },
                      icon: Icon(
                        _obscureConfirmation
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Repite tu contraseña.';
            }
            if (value != widget.passwordController.text) {
              return 'Las contraseñas no coinciden.';
            }

            return null;
          },
        ),
      ],
    );
  }
}
