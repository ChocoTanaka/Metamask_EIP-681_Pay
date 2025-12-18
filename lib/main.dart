import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:qr_flutter/qr_flutter.dart';
import "package:reown_appkit/reown_appkit.dart";

void main() async{
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  // 横向きに変更
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const MPSs());
}

class MPSs extends StatelessWidget {
  const MPSs({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MetaMask Payment Sub-system',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MPSs_Stateful(title: 'MetaMask Payment Sub-system'),
    );
  }
}

class MPSs_Stateful extends StatefulWidget {
  const MPSs_Stateful({super.key, required this.title});


  final String title;

  @override
  State<MPSs_Stateful> createState() => _MPSsState();
}

class _MPSsState extends State<MPSs_Stateful> {
  final TextEditingController amountController = TextEditingController();
  String? generatedUri;
  bool isConnected = false;
  bool isConnecting = false;
  String? userAddress="";
  int amount = 0;
  bool isShow = false;
  final String JPYCAddress = "0xE7C3D8C9a439feDe00D2600032D5dB0Be71C3c29";

  late ReownAppKitModal _appKitModal;

  Future AppkitInit() async{
    _appKitModal = ReownAppKitModal(
      context: context, // required BuildContext
      projectId: dotenv.env['Project_Id'],
      metadata: const PairingMetadata(
        name: "JPYC Invoice App",
        description: "Generate EIP-681",
        url: "https://github.com/ChocoTanaka/metamask_payment_subsystem",
        icons: ["https://raw.githubusercontent.com/ChocoTanaka/metamask_payment_subsystem/master/cable_50dp.png"],
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
    await _appKitModal.init();
  }

  Future disp() async{
    await _appKitModal.disconnect();
  }

  @override
  void initState(){
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    AppkitInit();
  }

  @override
  void dispose() {
    userAddress = "";
    //disp();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(

        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),
      body: Center(
          child:Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: amountController,
                      onChanged: (text)=> setState(() {
                        amount =int.parse(amountController.text);
                      }),
                      decoration: const InputDecoration(
                        labelText: 'Amount (JPYC)',
                        border: UnderlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "JPYC",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black, width: 2), // 黒い枠線
                ),
                child: isShow == false
                    ? SizedBox(
                  width: 250,
                  height: 250,
                )
                    : QrImageView(
                  data: generatedUri!,
                  size: 240,
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: 300,
                height:75,
                child: ElevatedButton(
                    onPressed:() {
                      if(userAddress != "" && amount !=0){
                        setState(() {
                          final BigInt amountWei = BigInt.from(amount * 1e18);
                          final uri =
                              'ethereum:$JPYCAddress@137/transfer?address=$userAddress&uint256=$amountWei';
                          print(uri);
                          generatedUri = uri;

                          isShow = !isShow;
                        });
                      }else{
                        null;
                      }
                    },
                    child: Text(
                      isShow ? "RESET" : "SET",
                      style: TextStyle(
                          fontSize: 30,
                          color: Colors.black
                      ),
                    )
                ),
              )
            ],
          )
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {

          _appKitModal.onModalConnect.subscribe((_) {
            final session = _appKitModal.session;

            if (session == null) {
              print('session is null');
              return;
            } else {
              final accounts =
                  session.namespaces!['eip155']?.accounts ?? [];

              if (accounts.isEmpty) return;

              final address = accounts.first.split(':')[2];

              setState(() {
                userAddress = address;
                isConnected = true;
              });
            }
          });
          _appKitModal.openModalView();
        },
        child: const Icon(Icons.cable),
        backgroundColor: userAddress != "" ? Colors.blue : Colors.grey[200],
      ),
    );
  }
}
