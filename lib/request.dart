import 'dart:async';
import 'dart:convert';
import 'Web3.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'package:web_socket_channel/io.dart'; // WebSocketを使う場合
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

String RPC = 'https://polygon.drpc.org';
String ws = 'wss://polygon.drpc.org';


class Erc20Watcher{
  Web3Client? client;

  StreamSubscription<FilterEvent>? _sub;

  Erc20Watcher._();

  static final instance = Erc20Watcher._();

  Future<void> test(String wsUrl) async{
    final channel = IOWebSocketChannel.connect(wsUrl);

    channel.stream.listen(
          (msg) => print(msg),
      onError: (e) => print("WS ERROR: $e"),
      onDone: () => print("WS DONE"),
    );

    channel.sink.add('{"id":1,"method":"eth_blockNumber","params":[]}');
  }

  Future<void> start(String rpcUrl, String wsUrl,String myAddressHex) async {

    client?.dispose();

    client = Web3Client(
      rpcUrl,
      Client(),
      socketConnector: () {
        print("WebSocket Connected");
        return IOWebSocketChannel.connect(wsUrl).cast<String>();
      },

    );

    final myAddress = EthereumAddress.fromHex(myAddressHex);

    final transferTopic =
    bytesToHex(
      keccakUtf8("Transfer(address,address,uint256)"),
      include0x: true,
    );

    final myTopic =
        "0x${myAddress.without0x.toLowerCase().padLeft(64, '0')}";

    final channel = IOWebSocketChannel.connect(wsUrl);

    channel.stream.listen(
      onMessage,
      onError: (e) => print("WS ERROR: $e"),
      onDone: () => print("WS DONE"),
    );

    channel.sink.add(jsonEncode({
      "id": 2,
      "jsonrpc": "2.0",
      "method": "eth_subscribe",
      "params": [
        "logs",
        {
          "topics": [
            transferTopic,
            null,
            myTopic,
          ]
        }
      ]
    }));

  }

  Future<void> onMessage(dynamic message)async {
    final json = jsonDecode(message);

    // 購読開始時の応答は無視
    if (json["method"] != "eth_subscription") {
      return;
    }

    final result = json["params"]["result"];

    final contract = EthereumAddress.fromHex(result["address"]);

    final from = EthereumAddress.fromHex(
        "0x${result["topics"][1].substring(26)}");

    final to = EthereumAddress.fromHex(
        "0x${result["topics"][2].substring(26)}");

    final value = BigInt.parse(
        result["data"].substring(2),
        radix: 16);

    final txHash = result["transactionHash"];

    print("Contract: $contract");
    print("From: $from");
    print("To: $to");
    print("Value: $value");
    print("TxHash: $txHash");

    checkAddress(contract.toString(), coin_noti);

    // symbol, decimals を取得
    // 通知
    await LocalNotificationService._().showPayment(symbol: coin_noti.Name, amount: ShowAmount(value, coin_noti.Div));
  }

  Future<void>  dispose() async{
    await _sub?.cancel();
    await client!.dispose();
  }

}

class LocalNotificationService {
  LocalNotificationService._();

  static final instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(settings: settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  Future<void> showPayment({
    required String symbol,
    required String amount,
  }) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'payment',
        'Payment',
        channelDescription: 'Payment received',
        importance: Importance.high,
        priority: Priority.defaultPriority,
        largeIcon: DrawableResourceAndroidBitmap('@drawable/stablepay')
      ),
    );

    await _plugin.show(
      id : 0,
      title : 'Payment Confirmed',
      body : 'You got $amount $symbol.',
      notificationDetails: details,
    );
  }
}