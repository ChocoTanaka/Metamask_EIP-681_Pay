import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'Reown.dart';
import 'Web3.dart';


class Page2 extends StatefulWidget {
  const Page2({super.key, required this.title});


  final String title;

  @override
  State<Page2> createState() => _MPSsState_Write();
}

class _MPSsState_Write extends State<Page2> {
  final TextEditingController amountController = TextEditingController();
  String? generatedUri;
  int amount = 0;
  bool isShow = false;

  Appkit appkit = Appkit();


  @override
  void initState(){
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      appkit.appKitInit(context);
    });
  }

  @override
  void dispose() {
    appkit.Disconnect();
    super.dispose();
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
                    Text(
                      "Address:",
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(width: 10),
                    ValueListenableBuilder(
                        valueListenable: appkit.addressNotifier,
                        builder: (context, address, _){
                          return Text(
                            address != null ? maskMiddle(userAddress, head: 6, tail: 6) : "Not Connected",
                            style: const TextStyle(fontSize: 22),
                            overflow: TextOverflow.ellipsis,
                          );
                        }
                    )
                  ],
                ),
                const SizedBox(height: 40),
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
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.black
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
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

    );
  }
}