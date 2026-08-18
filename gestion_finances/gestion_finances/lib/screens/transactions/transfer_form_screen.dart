import 'package:flutter/widgets.dart';

import '../../core/constants.dart';
import 'transaction_form_screen.dart';

/// Simple raccourci : ouvre le formulaire de transaction pré-rempli
/// en mode "Transfert" entre deux comptes.
class TransferFormScreen extends StatelessWidget {
  const TransferFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TransactionFormScreen(initialType: TxType.transfer);
  }
}
