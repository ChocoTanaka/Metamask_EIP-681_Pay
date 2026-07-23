import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'Reown.dart';
import 'Web3.dart';
import 'request.dart';


class Page2 extends StatefulWidget {
  const Page2({super.key, required this.title, required this.address});

  final String address;
  final String title;

  @override
  State<Page2> createState() => _MPSsState_Write();
}

class _MPSsState_Write extends State<Page2> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController tag1 = TextEditingController();
  final TextEditingController tag2 = TextEditingController();
  final TextEditingController tag3 = TextEditingController();
  final TextEditingController tag4 = TextEditingController();

  late String tag1_s = "",tag2_s = "",tag3_s = "",tag4_s ="";
  String? generatedUri;
  String amount = "";
  bool isShow = false;
  bool isTag = false;

  String URI(BigInt Wei, String tag){
    String uri = 'ethereum:${coin_now.Address}@${chain_now.ChainId}/transfer?address=${appkit.userAddress}&uint256=$Wei';
    if(tag.isNotEmpty && tag.length ==16){
      uri += '&tag=$tag';
    }
    return uri;
  }


  @override
  void initState(){
    super.initState();

  }

  @override
  void dispose(){
    Erc20Watcher.instance.dispose();
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
                      "Chain:",
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(width: 30),
                    DropdownButton<Blockchain>(
                      value: chain_now,
                      items: Blockchain.values.map((Blockchain chain){
                        return DropdownMenuItem(
                          value: chain,
                          child: Text(
                              chain.Name,
                              style: TextStyle(
                                fontSize: 24,
                              )
                          ), // enumに定義したラベルを表示
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          coin_now = value!.first;
                          chain_now = value;
                          print(coin_now.Name);
                        });

                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      "Address:",
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(width: 30),
                    Text(
                      appkit.userAddress.isNotEmpty ? maskMiddle(appkit.userAddress, head: 6, tail: 6) : "Not Connected",
                      style: const TextStyle(fontSize: 22),
                      overflow: TextOverflow.ellipsis,
                    )
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Switch(
                        value: isTag,
                        onChanged: (bool val){
                          setState(() {
                            isTag = val;
                          });
                        }
                    ),
                    isTag == true
                      ? Flexible(
                      child: Row(
                        children: <Widget>[
                          Text(
                            "tag:",
                            style: const TextStyle(fontSize: 20),
                          ),
                          Expanded(
                            child: TextFormField(
                                textAlign: TextAlign.center,
                                controller: tag1,
                                onChanged: (text)=> setState(() {
                                  tag1_s =tag1.text;
                                }),
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(4),
                                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]'),)
                                ]
                            ),
                          ),
                          Text(
                            "-",
                            style: const TextStyle(fontSize: 20),
                          ),
                          Expanded(
                            child: TextFormField(
                                textAlign: TextAlign.center,
                                controller: tag2,
                                onChanged: (text)=> setState(() {
                                  tag2_s =tag2.text;
                                }),
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(4),
                                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]'),)
                                ]
                            ),
                          ),
                          Text(
                            "-",
                            style: const TextStyle(fontSize: 20),
                          ),
                          Expanded(
                            child: TextFormField(
                                textAlign: TextAlign.center,
                                controller: tag3,
                                onChanged: (text)=> setState(() {
                                  tag3_s =tag3.text;
                                }),
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(4),
                                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]'),)
                                ]
                            ),
                          ),
                          Text(
                            "-",
                            style: const TextStyle(fontSize: 20),
                          ),
                          Expanded(
                            child: TextFormField(
                                textAlign: TextAlign.center,
                                controller: tag4,
                                onChanged: (text)=> setState(() {
                                  tag4_s =tag4.text;
                                }),
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  fontSize: 18,
                                ),
                                inputFormatters: [
                                  LengthLimitingTextInputFormatter(4),
                                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]'),)
                                ]
                            ),
                          )
                        ],
                      )
                    )
                      : SizedBox(
                      )
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: amountController,
                        onChanged: (text)=> setState(() {
                          amount =amountController.text;
                        }),
                        decoration: InputDecoration(
                          labelText: 'Amount (${coin_now.Name})',
                          border: const UnderlineInputBorder(),
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(
                          fontSize: 22,
                        ),
                        inputFormatters: [
                          // 修正版：小数点以下が0桁（ドットだけ）の状態も許容する
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,6}')),
                        ]
                      ),
                    ),
                    const SizedBox(height: 30),
                    DropdownButton<Stablecoin>(
                      value: coin_now,
                      items: chain_now.Coins.map((Stablecoin coin){
                        return DropdownMenuItem(
                          value: coin,
                          child: Text(
                              coin.Name,
                              style: TextStyle(
                                fontSize: 24,
                              )
                          ), // enumに定義したラベルを表示
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          coin_now = value!;
                          print(coin_now.Name);
                        });
                      },
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
                const SizedBox(height: 10),
                Container(
                  width: 300,
                  height:60,
                  child: ElevatedButton(
                      onPressed:() {
                        if(appkit.userAddress != "" && amount !=0){
                          setState(() {
                            final BigInt amountWei = parseInputToBigInt(amount,coin_now.Div);
                            final tag = tag1_s+tag2_s+tag3_s+tag4_s;
                            final uri =
                                URI(amountWei,tag);
                            print(uri);
                            generatedUri = uri;

                            isShow = !isShow;
                            if(isShow == true){
                              //Erc20Watcher.instance.test(ws);

                              Erc20Watcher.instance.start(chain_now.rpc, chain_now.ws, appkit.userAddress);
                            }
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