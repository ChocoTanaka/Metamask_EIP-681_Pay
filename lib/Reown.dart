import "package:flutter/material.dart";
import "package:reown_appkit/reown_appkit.dart";



Appkit appkit = Appkit();


String maskMiddle(String text, {int head = 6, int tail = 6}) {
  if (text.length <= head + tail) {
    return text; // 短すぎる場合はそのまま
  }
  return text.substring(0, head) +
      '...' +
      text.substring(text.length - tail);
}

Map<String, RequiredNamespace> r_Ns = {
  'eip155': RequiredNamespace(
    chains: ['eip155:1', 'eip155:137'], // eth,pol
    methods: [
      "eth_sendTransaction",
      "eth_signTransaction",

    ],
    events: [
      'accountsChanged',
    ],
  ),
};

class Appkit{

  String userAddress="";

  final ValueNotifier<String?> addressNotifier =
  ValueNotifier(null);


  ReownAppKitModal? appKitModal;

  Set<String> supportedWalletIds = <String>{
    'c57ca95b47569778a828d19178114f4db188b89b763c899ba0be274e97267d96', // MetaMask ID
    //'e3d6117850435b1359b81d7cef869f6851c00ad2125cadb04f4e003be8074af6', //myna
    '38633830ef578a1249c345848a8d6487551a346b923d21ce197ea57f423f3113', //hashport
    'c03dfee351b6fcc421b4494ea33b9d4b92a984f87aa76d1663bb28705e95034a', // uni
    '18388be9ac2d02726dbac9777c96efaac06d744b2f6d580fccdd4127a6d01fd1' // Rabby
  };

  Future appKitInit(BuildContext context) async {

    final appKit = await ReownAppKit.createInstance(
        projectId: const String.fromEnvironment("ProjectId"),
        relayUrl: 'wss://relay.walletconnect.com',
        metadata: const PairingMetadata(
          name: "STABLECOIN Sub-Payment System",
          description: "Generate ERC-681",
          url: "https://github.com/ChocoTanaka/Metamask_EIP-681_Pay",
          icons: ["https://raw.githubusercontent.com/ChocoTanaka/Metamask_EIP-681_Pay/master/icon_stablepay_512.png"],
          redirect: Redirect(
              native: 'stinvoice://wc',
              linkMode: true
          ),
        ),
    );

    appKitModal = ReownAppKitModal(
        context: context,
        appKit: appKit,
        optionalNamespaces: r_Ns,
        featuredWalletIds: supportedWalletIds,
        includedWalletIds: supportedWalletIds,
    );



    print("Connecting to Relay...");
// initを呼ぶ前にCoreの状態を確認
    print("Relay Endpoint: ${appKitModal?.appKit?.core.relayUrl}");

    try {
      await appKitModal?.init();
    } on ReownAppKitModalException catch (e) {
      print("AppKitModal専用エラー: ${e.message}"); // ここに具体的な理由が出るはずです
    } catch (e) {
      print("その他のエラー: $e");
    }
    final isConnected = appKitModal?.appKit?.core.relayClient.isConnected ?? false;
    print("AppKit Initialized: $isConnected");


    appKitModal?.appKit?.onSessionConnect.subscribe((_) async{

      final session = appKitModal?.session;

      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 300));

        if (session != null) {
          break;
        }
      }

      if (session == null) {
        print('session timeout');
        return;
      } else {
        final accounts =
            session.namespaces!['eip155']?.accounts ?? [];

        if (accounts.isEmpty) return;

        final address = accounts.first.split(':')[2];
        userAddress = address;
        addressNotifier.value = address;
        print(session);
      }
    });
  }

  void Openview() async{
    if (appKitModal?.session != null) {
      await appKitModal?.disconnect();
    }
    print("WC URI: ${appKitModal?.wcUri}");
    await appKitModal?.openModalView();
  }

  void Disconnect() async{
    await appKitModal?.disconnect();
  }
}