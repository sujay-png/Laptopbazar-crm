import 'package:crmapp/accounts/accounts_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


final accountsOptimisticProvider =
    StateProvider<Function(InvoiceModel)?>((_) => null);