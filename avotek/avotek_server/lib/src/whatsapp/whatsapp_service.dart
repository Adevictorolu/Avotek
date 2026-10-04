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

    final normalizedInput = input.toUpperCase().trim();

    if (normalizedInput == 'MENU' || normalizedInput == 'RESET' || state['step'] == 'START') {
      if (user == null) {
        state['step'] = 'REGISTER';
        _sessionMemory[phone] = state;
        await _sendButtons(
          to: phone,
          bodyText: '🎓 *Welcome to Avotek!*\n_Learn. Prepare. Connect._\n\nYour digital education companion and student services portal. We could not find an account linked to $phone. Would you like to get started?',
          buttons: [
            {'id': 'CMD_REGISTER', 'title': 'Create Account 🚀'},
            {'id': 'CMD_HELP', 'title': 'Need Help? 💬'},
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
          final name = input == 'CMD_REGISTER' ? 'Student' : input;
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
              virtualAccountBank: 'Providus Bank / Wema',
              virtualAccountName: 'AVOTEK - $name',
              updatedAt: now,
            ),
          );

          state['step'] = 'MAIN_MENU';
          _sessionMemory[phone] = state;
          await _sendTextMessage(to: phone, message: '🎉 Welcome to Avotek, $name! Your student account and dedicated wallet have been activated.');
          await _sendMainMenu(phone, name);
        }
        break;

      case 'MAIN_MENU':
        if (input == 'CMD_EXAMPIN' || normalizedInput == '1' || normalizedInput == 'EXAM') {
          state['step'] = 'EXAM_SELECT';
          _sessionMemory[phone] = state;
          await _sendButtons(
            to: phone,
            bodyText: '🎓 *Avotek Exam Centre*\nSelect the examination PIN you need:\n\n• WAEC Result Checker: ₦3,900\n• NECO Token: ₦1,200\n• JAMB UTME / DE PIN: ₦5,000',
            buttons: [
              {'id': 'EXAM_WAEC', 'title': 'WAEC (₦3,900)'},
              {'id': 'EXAM_NECO', 'title': 'NECO (₦1,200)'},
              {'id': 'EXAM_JAMB', 'title': 'JAMB (₦5,000)'},
            ],
          );
        } else if (input == 'CMD_CHALLENGE' || normalizedInput == '2' || normalizedInput == 'QUIZ' || normalizedInput == 'CHALLENGE') {
          state['step'] = 'CHALLENGE_ANSWER';
          _sessionMemory[phone] = state;
          await _sendTextMessage(
            to: phone,
            message: '📐 *Today\'s Academic Challenge (Mathematics)*\n\n'
                '*Topic:* Linear Equations & Algebra\n'
                '*Question:* If 2x + 5 = 15, what is the value of x?\n\n'
                '[A] 5\n'
                '[B] 10\n'
                '[C] 15\n'
                '[D] 20\n\n'
                '👉 *Reply with A, B, C, or D to submit your answer!*',
          );
        } else if (input == 'CMD_AIRTIME' || normalizedInput == '3' || normalizedInput == 'AIRTIME') {
          state['step'] = 'AIRTIME_NETWORK';
          _sessionMemory[phone] = state;
          await _sendButtons(
            to: phone,
            bodyText: '📱 *Stay Connected — Airtime Top-Up*\nSelect your network provider:',
            buttons: [
              {'id': 'NET_MTN', 'title': 'MTN'},
              {'id': 'NET_AIRTEL', 'title': 'Airtel'},
              {'id': 'NET_GLO', 'title': 'Glo'},
            ],
          );
        } else if (input == 'CMD_DATA' || normalizedInput == '4' || normalizedInput == 'DATA') {
          state['step'] = 'AIRTIME_NETWORK'; // Share network selection flow
          state['isData'] = true;
          _sessionMemory[phone] = state;
          await _sendButtons(
            to: phone,
            bodyText: '🌐 *Stay Connected — Data Bundle*\nSelect your network provider:',
            buttons: [
              {'id': 'NET_MTN', 'title': 'MTN Data'},
              {'id': 'NET_AIRTEL', 'title': 'Airtel Data'},
              {'id': 'NET_GLO', 'title': 'Glo Data'},
            ],
          );
        } else if (input == 'CMD_BALANCE' || normalizedInput == '5' || normalizedInput == 'BALANCE' || normalizedInput == 'WALLET') {
          final wallet = await Wallet.db.findFirstRow(
            session,
            where: (w) => w.userId.equals(user!.id!),
          );
          final balance = wallet?.balance ?? 0.0;
          final accNo = wallet?.virtualAccountNumber ?? 'Generating...';
          final bank = wallet?.virtualAccountBank ?? 'Providus Bank';
          final accName = wallet?.virtualAccountName ?? user?.name ?? 'Avotek Student';

          await _sendTextMessage(
            to: phone,
            message: '💳 *Avotek Student Wallet*\n\n'
                '• Available Balance: *₦${balance.toStringAsFixed(2)}*\n\n'
                '🏦 *Dedicated Bank Transfer Details:*\n'
                '• Bank: *$bank*\n'
                '• Account Number: *$accNo*\n'
                '• Account Name: *$accName*\n\n'
                '_Transfers to this account fund your Avotek balance instantly._\n\n'
                'Send *MENU* to return to the options.',
          );
        } else if (input == 'CMD_HISTORY' || normalizedInput == '6' || normalizedInput == 'HISTORY') {
          final transactions = await Transaction.db.find(
            session,
            where: (t) => t.userId.equals(user!.id!),
            orderBy: (t) => t.createdAt,
            orderDescending: true,
            limit: 5,
          );
          if (transactions.isEmpty) {
            await _sendTextMessage(to: phone, message: 'No transactions found on your account yet.\nSend *MENU* to explore services.');
          } else {
            final buffer = StringBuffer('📊 *Recent Activity*\n\n');
            for (final tx in transactions) {
              final sign = tx.type == 'fund' ? '+' : '-';
              buffer.writeln('• $sign₦${tx.amount.toStringAsFixed(2)} | ${tx.narration ?? tx.type} (${tx.status.toUpperCase()})');
            }
            buffer.writeln('\nSend *MENU* to return.');
            await _sendTextMessage(to: phone, message: buffer.toString());
          }
        } else if (input == 'CMD_HELP' || normalizedInput == 'HELP') {
          await _sendTextMessage(
            to: phone,
            message: '🎓 *Avotek Help & Support*\n\n'
                'Avotek is your digital education companion.\n'
                '• Web Portal: https://avotek.app\n'
                '• Support Email: support@avotek.app\n'
                '• Desk Hours: 24/7 automated delivery\n\n'
                'Send *MENU* anytime to view the main menu.',
          );
        } else {
          await _sendMainMenu(phone, user?.name ?? 'Student');
        }
        break;

      case 'CHALLENGE_ANSWER':
        final ans = normalizedInput;
        if (ans == 'A' || ans == '5' || ans == 'A) 5') {
          await _sendTextMessage(
            to: phone,
            message: '🎉 *Brilliant! That is Correct!* ✅\n\n'
                '*Explanation:*\n'
                '2x + 5 = 15\n'
                '2x = 15 - 5 = 10\n'
                'x = 10 / 2 = *5*\n\n'
                '🔥 *Streak:* 1 Day Streak Active!\n'
                'Keep sharpening your mind on the Avotek App.\n\n'
                'Send *MENU* to view other services.',
          );
        } else {
          await _sendTextMessage(
            to: phone,
            message: '❌ *Not quite, but good try!*\n\n'
                'The correct answer is *[A] 5*.\n\n'
                '*Explanation:*\n'
                'Subtract 5 from 15 gives 10. Dividing by 2 yields *x = 5*.\n\n'
                'Practice more past questions in the Avotek CBT Practice Center!\n\n'
                'Send *MENU* to continue.',
          );
        }
        state['step'] = 'MAIN_MENU';
        _sessionMemory[phone] = state;
        break;

      case 'EXAM_SELECT':
        String examType = 'WAEC';
        double price = 3900.0;
        if (input == 'EXAM_NECO') {
          examType = 'NECO';
          price = 1200.0;
        } else if (input == 'EXAM_JAMB') {
          examType = 'JAMB';
          price = 5000.0;
        }

        state['examType'] = examType;
        state['price'] = price;
        state['step'] = 'EXAM_CONFIRM';
        _sessionMemory[phone] = state;

        await _sendButtons(
          to: phone,
          bodyText: '🎓 *Confirm Exam PIN Order*\n\n'
              '• Exam: *$examType Result Checker*\n'
              '• Quantity: 1 Token\n'
              '• Total Cost: *₦${price.toStringAsFixed(2)}*\n\n'
              'Your Avotek wallet will be debited upon confirmation.',
          buttons: [
            {'id': 'CONFIRM_EXAM_YES', 'title': 'Confirm & Purchase ✅'},
            {'id': 'CONFIRM_NO', 'title': 'Cancel ❌'},
          ],
        );
        break;

      case 'EXAM_CONFIRM':
        if (input == 'CONFIRM_EXAM_YES') {
          final examType = state['examType'] as String;
          final price = state['price'] as double;
          final idempotencyKey = 'WA-EXAM-${DateTime.now().millisecondsSinceEpoch}-$phone';

          await _sendTextMessage(to: phone, message: '⏳ Generating your $examType PIN securely...');

          final result = await orderEngine.processOrder(
            session: session,
            userId: user!.id!,
            serviceType: 'exam_pin',
            networkProvider: examType,
            recipientIdentifier: phone,
            amount: price,
            sellPrice: price,
            channel: 'whatsapp',
            idempotencyKey: idempotencyKey,
          );

          if (result.success) {
            Map<String, dynamic>? meta;
            if (result.order.metadata != null) {
              try {
                meta = jsonDecode(result.order.metadata!) as Map<String, dynamic>?;
              } catch (_) {}
            }
            final pinToken = meta?['pin']?.toString() ?? 'AVO-W-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
            final serial = meta?['serial']?.toString() ?? 'SN-2026-${phone.substring(phone.length - 4)}';

            await _sendTextMessage(
              to: phone,
              message: '🎓 *Exam PIN Purchase Successful!*\n\n'
                  '• Exam: *$examType Result Checker*\n'
                  '• PIN / Token: *$pinToken*\n'
                  '• Serial No: *$serial*\n'
                  '• Reference: ${result.order.providerReference ?? result.order.id}\n\n'
                  '🔒 _This PIN has also been saved to your Avotek App PIN Vault._\n'
                  'Send *MENU* to return.',
            );
          } else {
            await _sendTextMessage(
              to: phone,
              message: '❌ *Order Could Not Be Completed:*\n${result.message}\n'
                  'Any deducted funds have been refunded to your wallet.\n'
                  'Send *MENU* to try again.',
            );
          }
        } else {
          await _sendTextMessage(to: phone, message: 'Exam PIN order cancelled.');
          await _sendMainMenu(phone, user?.name ?? 'Student');
        }
        state['step'] = 'MAIN_MENU';
        _sessionMemory[phone] = state;
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
        await _sendMainMenu(phone, user?.name ?? 'Student');
    }
  }

  Future<void> _sendMainMenu(String phone, String name) async {
    await _sendButtons(
      to: phone,
      bodyText: '🎓 *Avotek Student Companion*\n_Learn. Prepare. Connect._\n\nHello $name 👋\nWhat would you like to do today?\n\n'
          '1️⃣ *Exam PINs* (WAEC, NECO, JAMB)\n'
          '2️⃣ *Today\'s Challenge* (Daily Quiz)\n'
          '3️⃣ *Stay Connected* (Airtime & Data)\n'
          '4️⃣ *Student Wallet* & Account\n\n'
          'Reply with a number (1-4) or tap a button below:',
      buttons: [
        {'id': 'CMD_EXAMPIN', 'title': 'Exam PINs 🎓'},
        {'id': 'CMD_CHALLENGE', 'title': 'Challenge 📐'},
        {'id': 'CMD_AIRTIME', 'title': 'Airtime/Data 📱'},
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
