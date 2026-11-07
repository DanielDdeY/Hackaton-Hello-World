import 'package:flutter/material.dart';

import '../../domain/entities/service_post_data.dart';

extension PaymentMethodLabel on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.yape => 'Yape',
    PaymentMethod.plin => 'Plin',
    PaymentMethod.cash => 'Efectivo',
    PaymentMethod.bcpTransfer => 'Transferencia BCP',
    PaymentMethod.interbankTransfer => 'Transferencia Interbank',
    PaymentMethod.bbvaTransfer => 'Transferencia BBVA',
    PaymentMethod.scotiabankTransfer => 'Transferencia Scotiabank',
    PaymentMethod.card => 'Tarjeta',
  };
}

class PaymentMethodsSheet extends StatefulWidget {
  const PaymentMethodsSheet({super.key, required this.initialSelection});

  final Set<PaymentMethod> initialSelection;

  @override
  State<PaymentMethodsSheet> createState() => _PaymentMethodsSheetState();
}

class _PaymentMethodsSheetState extends State<PaymentMethodsSheet> {
  late final Set<PaymentMethod> _selection = {...widget.initialSelection};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FractionallySizedBox(
      heightFactor: 0.88,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Semantics(
                header: true,
                child: Text(
                  'Medios de pago',
                  style: theme.textTheme.titleLarge,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final method in PaymentMethod.values)
                    CheckboxListTile(
                      title: Text(method.label),
                      value: _selection.contains(method),
                      onChanged: (checked) => setState(() {
                        if (checked == true) {
                          _selection.add(method);
                        } else {
                          _selection.remove(method);
                        }
                      }),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: FilledButton(
                onPressed: () => Navigator.pop(context, Set.of(_selection)),
                child: const Text('Aplicar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
