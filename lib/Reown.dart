import "package:flutter/material.dart";
import "package:reown_appkit/reown_appkit.dart";

class Appkit{

  ReownAppKitModal? appKitModal;

  Future appKitInit(BuildContext context) async {
    appKitModal = ReownAppKitModal(
      context: context, // required BuildContext
      projectId: const String.fromEnvironment("ProjectId"),
      metadata: const PairingMetadata(
        name: "JPYC Invoice App",
        description: "Generate EIP-681",
        url: "https://github.com/ChocoTanaka/Metamask_EIP-681_Pay",
        icons: ["https://raw.githubusercontent.com/ChocoTanaka/Metamask_EIP-681_Pay/master/cable_50dp.png"],
        redirect: Redirect(
          native: 'metamask://',
          universal: 'https://metamask.app.link',
          linkMode: true|false,
        ),
      ),
      optionalNamespaces: {
        'eip155': RequiredNamespace(
          chains: ['eip155:137'], // Polygon mainnet
          methods: [
            'eth_sendTransaction',
            'eth_sign',
            'personal_sign',
          ],
          events: [
            'accountsChanged',
            'chainChanged',
          ],
        ),
      },
    );
    await appKitModal?.init();
    print("init complete");

  }

  void Openview() async{
    if (appKitModal?.session != null) {
      await appKitModal?.disconnect();
    }

    await appKitModal?.openModalView();
  }
}