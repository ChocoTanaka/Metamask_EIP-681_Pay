import "package:flutter/material.dart";
import "package:reown_appkit/reown_appkit.dart";

String? userAddress="";

class Appkit{

  final ValueNotifier<String?> addressNotifier =
  ValueNotifier(null);


  ReownAppKitModal? appKitModal;

  Set<String> supportedWalletIds = <String>{
    'c57ca95b47569778a828d19178114f4db188b89b763c899ba0be274e97267d96', // MetaMask ID
  };

  Future appKitInit(BuildContext context) async {

    final appKit = await ReownAppKit.createInstance(
        projectId: const String.fromEnvironment("ProjectId"),
        relayUrl: 'wss://relay.walletconnect.com',
        metadata: const PairingMetadata(
          name: "JPYC Invoice App",
          description: "Generate EIP-681",
          url: "https://github.com/ChocoTanaka/Metamask_EIP-681_Pay",
          icons: ["https://raw.githubusercontent.com/ChocoTanaka/Metamask_EIP-681_Pay/master/cable_50dp.png"],
          redirect: Redirect(
            native: 'jpycinvoice://',
          ),
        ),
    );

    appKitModal = ReownAppKitModal(
        context: context,
        appKit: appKit,
        includedWalletIds: supportedWalletIds,
        featuredWalletIds: supportedWalletIds,
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


    appKitModal?.appKit?.onSessionConnect.subscribe((_) {
      final session = appKitModal?.session;
      if (session == null) {
        print('session is null');
        return;
      } else {
        final accounts =
            session.namespaces!['eip155']?.accounts ?? [];

        if (accounts.isEmpty) return;

        final address = accounts.first.split(':')[2];
        userAddress = address;
        addressNotifier.value = address;
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