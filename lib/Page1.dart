import 'dart:io';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:reown_appkit/appkit_modal.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'Reown.dart';
import 'package:flutter/material.dart';
import 'Web3.dart';

class Page1 extends StatefulWidget {
  const Page1({super.key, required this.title, required this.address});

  final String address;
  final String title;

  @override
  State<Page1> createState() => _MPSsState_Read();
}

class _MPSsState_Read extends State<Page1> {
  int i_situ = 0;
  String Text_Error="";
  String Read_Text = "";
  String URI = "";
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  final _controller = MobileScannerController(
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.normal, // 連続検知を防ぐために速度を調整
      autoStart: true
  );



  @override
  void dispose() {
    // 画面を離れる時に必ずリソースを解放する
    _controller.dispose();
    super.dispose();
  }

  Future<void> CheckTx(BuildContext context, Erc681Request tx_R) async {
    await showDialog(context: context, builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Tx Check'),
        content: SizedBox(
          width: double.maxFinite,
          height: 200,
          child: Container(
            width: 300,
            decoration: BoxDecoration(
              border: Border.all(
                  color: Colors.black // 枠線の色を設定
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 10,
                ),
                Text(
                  "Address:  ${maskMiddle(tx_R.to)}",
                  style: TextStyle(
                    fontSize: 20.0,
                  ),
                  overflow: TextOverflow.ellipsis, // 長いテキストを省略
                ),
                tx_R.tag !="" ?
                  Text(
                    "tag:  ${filltag(tx_R.tag)}",
                    style: TextStyle(
                      fontSize: 16.0,
                    ),
                  )
                : SizedBox(),
                Text(
                    "${ShowAmount(tx_R.amount, coin_now.Div)}  ${coin_now.Name}",
                    style: TextStyle(
                    fontSize: 20.0,
                  ),
                ),
                Text(
                  "Network:  ${chain_now.Name}",
                  style: TextStyle(
                    fontSize: 20.0,
                  ),
                ),
                SizedBox(
                  height: 10,
                )
              ],
            ),
          ),
        ),
        actions: <Widget>[
          GestureDetector(
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontSize: 24,
              ),
            ),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          SizedBox(width: 30),
          GestureDetector(
            child: const Text(
              'OK',
              style: TextStyle(
                fontSize: 24,
              ),
            ),
            onTap: () async {
              final tx = buildTransaction(
                from: appkit.userAddress,
                tokenAddress: tx_R.token,
                to: tx_R.to,
                amount: tx_R.amount,
                tag: tx_R.tag
              );

              final response = await appkit.appKitModal?.request(
                topic: appkit.appKitModal?.session!.topic,
                chainId: 'eip155:${chain_now.ChainId}',
                request: SessionRequestParams(
                    method: "eth_sendTransaction",
                    params: [tx]
                ),
              );
              // 成功すると、トランザクションハッシュが返ってきます
              print('Transaction Hash: $response');
              Navigator.pop(context);
            },
          )
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(

        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),
      body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Row(
                children: [
                  Text(
                    "Address:",
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    appkit.userAddress.isNotEmpty ? maskMiddle(appkit.userAddress, head: 6, tail: 6) : "Not Connected",
                    style: const TextStyle(fontSize: 22),
                    overflow: TextOverflow.ellipsis,
                  )
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Read ERC-681 Recipt",
                style: TextStyle(
                  fontSize: 24.0,
                ),
              ),
              Text(
                Text_Error,
                style: TextStyle(
                    fontSize: 22.0,
                    color: Colors.greenAccent[200]
                ),
              ),
              Camera_Viewer(),
              URI.isNotEmpty ?
              ElevatedButton(
                  onPressed: () async {
                    if(URI.isNotEmpty && appkit.userAddress !=""){
                      setState(() {
                        Text_Error = "";
                        Read_Text = "Check Phase...";
                      });
                      final Tx = parseErc681(URI);
                      URI = "";
                      CheckTx(context,Tx).then((result) async{
                        await Future.delayed(const Duration(milliseconds: 1500));
                        setState(() {
                          i_situ = 0;
                          Read_Text = "";
                        });
                      });
                    }
                  },
                  child: Text(
                    "Check",
                    style: TextStyle(
                      fontSize: 24.0,
                    ),
                  ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: (URI.isNotEmpty && appkit.userAddress !="") ? Colors.deepPurple[200] : Colors.grey
                )
              )
                  :
              const Padding(padding: EdgeInsets.all(10)),
            ],
          )
      );
  }

  SizedBox Camera_Viewer(){
    switch(i_situ){
      case 0:
        return SizedBox(
            height:300,
            width:300,
            child: Center(
                child:ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: appkit.userAddress !="" ? Colors.deepPurple[200] : Colors.grey
                  ),
                  onPressed: () async{
                    if(appkit.userAddress !="") {
                      setState(() {
                        i_situ = 1;
                      });
                    }
                  },
                  child: Text(
                    "Read_Start",
                    style: TextStyle(
                      fontSize: 26.0,
                    ),
                  ),
                )
            )
        );
      case 1:
        return SizedBox(
          height:300,
          width:300,
          child: MobileScanner(
            controller: _controller, // ここで指定
            onDetect: (capture) async {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;

              // 最初のバーコードを取得
              final String? code = barcodes.first.rawValue;
              if (code == null) return;

              // i_situ が 1（待機中）の時だけ処理を行う
              if (i_situ == 1) {
                // 1. まずカメラを止める（Webでの安定動作に重要）
                await _controller.stop();
                // 1. 読み取り開始状態へ
                setState(() {
                  i_situ = 2;
                  Read_Text = "Now reading Tx...";
                });

                print("Scanned Code: $code");

                // 2. バリデーションチェック
                final error = validateRawUri(code);

                if (error != null) {
                  // --- エラーの場合 ---
                  setState(() {
                    Text_Error = errorMessage(error);
                    URI = "";
                  });

                  await Future.delayed(const Duration(milliseconds: 1500));

                  if (mounted) {
                    // カメラを再開
                    await _controller.start();
                    setState(() {
                      Text_Error = "";
                      i_situ = 1; // 読み取り待機に戻す
                    });
                  }
                } else {
                  // --- 成功の場合 ---
                  setState(() {
                    Text_Error = "";
                  });

                  await Future.delayed(const Duration(milliseconds: 1500));

                  if (mounted) {
                    setState(() {
                      URI = code;
                      Read_Text = "Checking Phase";
                      // 必要に応じてここで i_situ を次のステップへ進める
                    });
                  }
                }
              }
            },
          ),
        );
      case 2:
        return SizedBox(
            height:300,
            width:300,
            child: Center(
              child:Text(
                Read_Text,
                style: TextStyle(
                  fontSize: 26.0,
                ),
              ),
            )
        );
      default:
        return SizedBox(
            height:300,
            width:300,
            child: Center(
                child:ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: appkit.userAddress !="" ? Colors.deepPurple[200] : Colors.grey
                  ),
                  onPressed: () {
                    setState(() {
                      if(appkit.userAddress !=""){
                        i_situ = 1;
                      }
                    });
                  },
                  child: Text(
                    "Read_Start",
                    style: TextStyle(
                      fontSize: 36.0,
                    ),
                  ),
                )
            )
        );
    }
  }
}

