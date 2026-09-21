import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart' hide Order, Transaction;
import '../engine/order_engine.dart';
import '../generated/protocol.dart';

class WhatsAppService {
  final String accessToken;
  final String phoneNumberId;
  final OrderEngine orderEngine;

  WhatsAppService({
    required this.accessToken,
    required this.phoneNumberId,
    required this.orderEngine,
  });

  // State cache for conversational memory: phone -> state map
  static final Map<String, Map<String, dynamic>> _sessionMemory = {};

  Future<void> handleIncomingMessage(Session session, Map<String, dynamic> body) async {
    final entry = body['entry']?[0];
    final changes = entry?['changes']?[0];
    final value = changes?['value'];
    final messages = value?['messages'];

    if (messages == null || messages.isEmpty) return;

    final message = messages[0];
    final fromPhone = message['from']?.toString();
    final messageType = message['type']?.toString();

    if (fromPhone == null) return;

    // Extract text from interactive list reply, interactive button reply, or normal text
    String incomingText = '';
    if (messageType == 'text') {
      incomingText = message['text']?['body']?.toString().trim() ?? '';
    } else if (messageType == 'interactive') {
      final interactive = message['interactive'];
      if (interactive?['type'] == 'button_reply') {
        incomingText = interactive['button_reply']?['id']?.toString() ?? '';
      } else if (interactive?['type'] == 'list_reply') {
        incomingText = interactive['list_reply']?['id']?.toString() ?? '';
      }
    }

    await _processStateMachine(session, fromPhone, incomingText);
  }

  Future<void> _processStateMachine(Session session, String phone, String input) async {
    final state = _sessionMemory[phone] ?? {'step': 'START'};

    // Find or create user by phone
    var user = await User.db.findFirstRow(
      session,
      where: (u) => u.phone.equals(phone),
    );

    final normalizedInput = input.toUpperCase();

    if (normalizedInput == 'MENU' || normalizedInput == 'RESET' || state['step'] == 'START') {
      if (user == null) {
        state['step'] = 'REGISTER';
        _sessionMemory[phone] = state;
        await _sendButtons(
          to: phone,
          bodyText: 'Welcome to AVOTEK VTU! 🚀\nYour fast, reliable top-up portal. You do not have an account yet with $phone. Would you like to create one?',
          buttons: [
            {'id': 'CMD_REGISTER', 'title': 'Create Account'},
            {'id': 'CMD_HELP', 'title': 'Support'},
          ],
        );
        return;
      }

      state['step'] = 'MAIN_MENU';
      _sessionMemory[phone] = state;
      await _sendMainMenu(phone, user.name);
      return;
    }

    switch (state['step']) {
      case 'REGISTER':
        if (input == 'CMD_REGISTER' || input.isNotEmpty) {
          final name = input == 'CMD_REGISTER' ? 'WhatsApp User' : input;
          final now = DateTime.now();
          user = await User.db.insertRow(
            session,
            User(
              phone: phone,
              name: name,
              kycStatus: 'tier1',
              referralCode: 'AVO${phone.substring(phone.length - 4)}',
              createdAt: now,
            ),
          );

          // Create wallet with dedicated virtual account
          final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
          final accNumber = '90${cleanPhone.substring(cleanPhone.length - 8)}';
          await Wallet.db.insertRow(
            session,
            Wallet(
              userId: user.id!,
              balance: 0.0,
              currency: 'NGN',
              virtualAccountNumber: accNumber,
              virtualAccountBank: 'Wema Bank / Moniepoint',
              virtualAccountName: 'AVOTEK - $name',
              updatedAt: now,
            ),
          );

          state['step'] = 'MAIN_MENU';
          _sessionMemory[phone] = state;
          await _sendTextMessage(to: phone, message: '🎉 Account created successfully, $name!');
          await _sendMainMenu(phone, name);
        }
        break;

      case 'MAIN_MENU':
        if (input == 'CMD_BALANCE') {
          final wallet = await Wallet.db.findFirstRow(
            session,
            where: (w) => w.userId.equals(user!.id!),
          );
          final balance = wallet?.balance ?? 0.0;
          await _sendTextMessage(
            to: phone,
            message: '💰 *AVOTEK Wallet Balance*\n\nAvailable: *₦${balance.toStringAsFixed(2)}*\nCurrency: NGN\n\nSend *MENU* for options.',
          );
        } else if (input == 'CMD_FUND') {
          final wallet = await Wallet.db.findFirstRow(
            session,
            where: (w) => w.userId.equals(user!.id!),
          );
          final accNo = wallet?.virtualAccountNumber ?? 'Pending';
          final bank = wallet?.virtualAccountBank ?? 'Wema Bank';
          final accName = wallet?.virtualAccountName ?? user?.name ?? 'AVOTEK User';

          await _sendTextMessage(
            to: phone,
            message: '💳 *Fund Your Wallet Instantly*\n\nTransfer to your dedicated virtual account:\n\n• Bank: *$bank*\n• Account Number: *$accNo*\n• Account Name: *$accName*\n\nYour wallet credits automatically upon transfer!',
          );
        } else if (input == 'CMD_AIRTIME') {
          state['step'] = 'AIRTIME_NETWORK';
          _sessionMemory[phone] = state;
          await _sendButtons(
            to: phone,
            bodyText: 'Select Network Provider for Airtime:',
            buttons: [
              {'id': 'NET_MTN', 'title': 'MTN'},
              {'id': 'NET_AIRTEL', 'title': 'Airtel'},
              {'id': 'NET_GLO', 'title': 'Glo'},
            ],
          );
        } else if (input == 'CMD_DATA') {
          state['step'] = 'DATA_NETWORK';
          _sessionMemory[phone] = state;
          await _sendButtons(
            to: phone,
            bodyText: 'Select Network Provider for Data:',
            buttons: [
              {'id': 'NET_MTN', 'title': 'MTN'},
              {'id': 'NET_AIRTEL', 'title': 'Airtel'},
              {'id': 'NET_GLO', 'title': 'Glo'},
            ],
          );
        } else if (input == 'CMD_HISTORY') {
          final transactions = await Transaction.db.find(
            session,
            where: (t) => t.userId.equals(user!.id!),
            orderBy: (t) => t.createdAt,
            orderDescending: true,
            limit: 5,
          );
          if (transactions.isEmpty) {
            await _sendTextMessage(to: phone, message: 'No transactions found on your account.');
          } else {
            final buffer = StringBuffer('📊 *Recent Transactions*\n\n');
            for (final tx in transactions) {
              final sign = tx.type == 'fund' ? '+' : '-';
              buffer.writeln('• $sign₦${tx.amount.toStringAsFixed(2)} | ${tx.narration ?? tx.type} (${tx.status})');
            }
            buffer.writeln('\nSend *MENU* to return.');
            await _sendTextMessage(to: phone, message: buffer.toString());
          }
        } else {
          await _sendMainMenu(phone, user?.name ?? 'Customer');
        }
        break;

      case 'AIRTIME_NETWORK':
        state['network'] = input.replaceAll('NET_', '');
        state['step'] = 'AIRTIME_PHONE';
        _sessionMemory[phone] = state;
        await _sendTextMessage(
          to: phone,
          message: 'Enter recipient phone number (or type *ME* for $phone):',
        );
        break;

      case 'AIRTIME_PHONE':
        state['recipient'] = input.toUpperCase() == 'ME' ? phone : input;
        state['step'] = 'AIRTIME_AMOUNT';
        _sessionMemory[phone] = state;
        await _sendTextMessage(
          to: phone,
          message: 'Enter amount to recharge (e.g. 500, 1000, 2000):',
        );
        break;

      case 'AIRTIME_AMOUNT':
        final amount = double.tryParse(input) ?? 0.0;
        if (amount < 50) {
          await _sendTextMessage(to: phone, message: 'Minimum airtime amount is ₦50. Please enter a valid amount:');
          return;
        }
        state['amount'] = amount;
        state['step'] = 'AIRTIME_CONFIRM';
        _sessionMemory[phone] = state;

        await _sendButtons(
          to: phone,
          bodyText: 'Confirm purchase:\n• Service: Airtime\n• Network: ${state['network']}\n• Phone: ${state['recipient']}\n• Amount: ₦$amount\n\nDebit your wallet?',
          buttons: [
            {'id': 'CONFIRM_YES', 'title': 'Yes, Buy Now'},
            {'id': 'CONFIRM_NO', 'title': 'Cancel'},
          ],
        );
        break;

      case 'AIRTIME_CONFIRM':
        if (input == 'CONFIRM_YES') {
          final network = state['network'] as String;
          final recipient = state['recipient'] as String;
          final amount = state['amount'] as double;
          final idempotencyKey = 'WA-AIR-${DateTime.now().millisecondsSinceEpoch}-$phone';

          await _sendTextMessage(to: phone, message: '⏳ Processing airtime order...');

          final result = await orderEngine.processOrder(
            session: session,
            userId: user!.id!,
            serviceType: 'airtime',
            networkProvider: network,
            recipientIdentifier: recipient,
            amount: amount,
            sellPrice: amount,
            channel: 'whatsapp',
            idempotencyKey: idempotencyKey,
          );

          if (result.success) {
            await _sendTextMessage(
              to: phone,
              message: '✅ *Airtime Purchase Successful!*\n\n₦$amount sent to $recipient ($network).\nRef: ${result.order.providerReference ?? result.order.id}\n\nSend *MENU* for main options.',
            );
          } else {
            await _sendTextMessage(
              to: phone,
              message: '❌ *Order Failed:*\n${result.message}\nAny wallet debit has been automatically refunded.\nSend *MENU* to try again.',
            );
          }
        } else {
          await _sendTextMessage(to: phone, message: 'Order cancelled.');
          await _sendMainMenu(phone, user?.name ?? 'Customer');
        }
        state['step'] = 'MAIN_MENU';
        _sessionMemory[phone] = state;
        break;

      default:
        state['step'] = 'MAIN_MENU';
        _sessionMemory[phone] = state;
        await _sendMainMenu(phone, user?.name ?? 'Customer');
    }
  }

  Future<void> _sendMainMenu(String phone, String name) async {
    await _sendButtons(
      to: phone,
      bodyText: 'Hello $name 👋\nWelcome to *AVOTEK* Quick Top-Up.\nChoose an action below:',
      buttons: [
        {'id': 'CMD_AIRTIME', 'title': 'Buy Airtime'},
        {'id': 'CMD_DATA', 'title': 'Buy Data'},
        {'id': 'CMD_BALANCE', 'title': 'Check Balance'},
      ],
    );
  }

  Future<void> _sendTextMessage({required String to, required String message}) async {
    if (accessToken.isEmpty || phoneNumberId.isEmpty) return;
    try {
      final url = Uri.parse('https://graph.facebook.com/v19.0/$phoneNumberId/messages');
      await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'messaging_product': 'whatsapp',
          'to': to,
          'type': 'text',
          'text': {'body': message},
        }),
      );
    } catch (_) {}
  }

  Future<void> _sendButtons({
    required String to,
    required String bodyText,
    required List<Map<String, String>> buttons,
  }) async {
    if (accessToken.isEmpty || phoneNumberId.isEmpty) return;
    try {
      final url = Uri.parse('https://graph.facebook.com/v19.0/$phoneNumberId/messages');
      await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'messaging_product': 'whatsapp',
          'to': to,
          'type': 'interactive',
          'interactive': {
            'type': 'button',
            'body': {'text': bodyText},
            'action': {
              'buttons': buttons
                  .map((b) => {
                        'type': 'reply',
                        'reply': {'id': b['id'], 'title': b['title']},
                      })
                  .toList(),
            },
          },
        }),
      );
    } catch (_) {}
  }
}
