import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../animations/animations.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/shimmer_widgets.dart';
import '../widgets/transaction_item.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transactionProvider.notifier).fetchHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(transactionProvider);
    final userId = ref.watch(authProvider).user?.id ?? 0;

    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        color: cs.primary,
        backgroundColor: cs.surfaceContainerHighest,
        onRefresh: () => ref.read(transactionProvider.notifier).fetchHistory(),
        child: txState.isLoading
            ? ListView.builder(
                itemCount: 6,
                itemBuilder: (_, __) => const TransactionItemSkeleton(),
              )
            : txState.transactions.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 32),
                    itemCount: txState.transactions.length,
                    itemBuilder: (_, i) => TransactionItem(
                      transaction: txState.transactions[i],
                      currentUserId: userId,
                      index: i,
                    ),
                  ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: FadeSlideIn(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: BoxShape.circle,
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Icon(Icons.receipt_long_outlined,
                  color: cs.onSurfaceVariant, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'No transactions yet',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your transaction history will appear here',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
