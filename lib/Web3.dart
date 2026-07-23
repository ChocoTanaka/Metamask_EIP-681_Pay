import 'dart:convert';

Blockchain chain_now = Blockchain.pol;

Stablecoin coin_now = coin_pol.JPYC;

Stablecoin coin_noti = coin_pol.JPYC;

enum Blockchain{
  eth(
    "Ethereum",
    1,
    [
      coin_eth.JPYC,
      coin_eth.USDC
    ],
    coin_eth.JPYC,
    "https://eth.drpc.org",
    "wss://eth.drpc.org",
  ),
  pol(
      "Polygon",
      137,
      [
        coin_pol.JPYC,
        coin_pol.USDC,
        coin_pol.xSGD,
        coin_pol.IDRX
      ],
    coin_pol.JPYC,
    "https://polygon.drpc.org",
    "wss://polygon.drpc.org",
  );

  final String Name;
  final int ChainId;
  final List<Stablecoin> Coins;
  final Stablecoin first;
  final String rpc;
  final String ws;
  const Blockchain(this.Name, this.ChainId, this.Coins, this.first, this.rpc, this.ws);

}

sealed class Stablecoin {
  final String Name;
  final String Address;
  final int Div;

  Stablecoin(this.Name, this.Address, this.Div);
}

enum coin_eth implements Stablecoin{
  JPYC("JPYC", '0xE7C3D8C9a439feDe00D2600032D5dB0Be71C3c29', 18),
  USDC("USDC", '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48', 6);

  final String Name;
  final String Address;
  final int Div;

  const coin_eth(this.Name, this.Address, this.Div);

}

enum coin_pol implements Stablecoin{
  JPYC("JPYC", '0xE7C3D8C9a439feDe00D2600032D5dB0Be71C3c29', 18),
  USDC("USDC", '0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359', 6),
  xSGD("XSGD", '0xDC3326e71D45186F113a2F448984CA0e8D201995', 6),
  IDRX("XIDR", '0x2c826035c1C36986117A0e949bD6ad4baB54afE2', 6);

  final String Name;
  final String Address;
  final int Div;

  const coin_pol(this.Name, this.Address, this.Div);
  
}

void checkAddress(String address, Stablecoin coin_check){
  for (var coin in chain_now.Coins){
    if (address ==coin.Address){
      coin_check = coin;
    }
  }
}

String Checkname(String address){
  for (var chain in Blockchain.values){
    for(var coin in chain.Coins){
      if(coin.Address == address){
        return coin.Name;
      }
    }
  }
  return 'Undefined Stable Coin';
}

BigInt parseInputToBigInt(String input, int decimals) {
  if (!input.contains('.')) {
    // 小数点がない場合（例: "3"）はそのまま後ろにゼロを付けるだけ
    return BigInt.parse(input) * BigInt.from(10).pow(decimals);
  }

  // 小数点で分割（例: "3.3" -> ["3", "3"]）
  List<String> parts = input.split('.');
  String integerPart = parts[0]; // "3"
  String decimalPart = parts[1]; // "3"

  // 小数点以下の桁数が指定（6桁）より長ければ切り捨て、短ければゼロで埋める
  if (decimalPart.length > decimals) {
    decimalPart = decimalPart.substring(0, decimals);
  } else {
    decimalPart = decimalPart.padRight(decimals, '0'); // "3" -> "300000"
  }

  // 結合して一つの巨大な整数文字列にする（"3" + "300000" = "3300000"）
  return BigInt.parse(integerPart + decimalPart);
}

enum UriCheckError {
  notEVMUri,
  differentNetwork,
  invalidToken,
  invalidFormat,
  invalidFunction,
}

String errorMessage(UriCheckError e) {
  switch (e) {
    case UriCheckError.notEVMUri:
      return 'Not ERC-681 Recipt';
    case UriCheckError.differentNetwork:
      return 'Invalid Network';
    case UriCheckError.invalidToken:
      return 'Invalid token';
    case UriCheckError.invalidFormat:
      return 'Invalid URI';
    case UriCheckError.invalidFunction:
      return 'Unsupported Function';
  }
}

UriCheckError? validateRawUri(String uri) {

  try {
    final req = parseErc681(uri);
    if (!uri.startsWith('ethereum:')) {
      return UriCheckError.notEVMUri;
    }

    if (req.chainId != Blockchain.eth.ChainId && req.chainId != Blockchain.pol.ChainId) {
      return UriCheckError.differentNetwork;
    }

    String checkAddress = Checkname(req.token);
    if(checkAddress == 'Undefined Stable Coin'){
      return UriCheckError.invalidToken;
    }

    if (req.function != "transfer") {
      return UriCheckError.invalidFunction;
    }
  }catch(e){
    return UriCheckError.invalidFormat;
  }

  return null; // OK
}

bool isValidDecimals(BigInt amount, int div) {
  final base = BigInt.from(10).pow(div);
  return amount % base == BigInt.zero;
}

String buildErc20TransferData(String to, BigInt amount, String tag) {
  // function selector
  final methodId = 'a9059cbb';

  // address（20byte → 32byte）
  final toClean = to.replaceFirst('0x', '');
  final toPadded = toClean.padLeft(64, '0');

  // amount（uint256 → 32byte）
  final amountHex = amount.toRadixString(16);
  final amountPadded = amountHex.padLeft(64, '0');

  String dat = '0x$methodId$toPadded$amountPadded';

  if(tag.isNotEmpty){
    dat += toHex(tag);
  }

  return dat;
}

String toHex(String tag) {
  final bytes = utf8.encode(tag);   // 文字列 → バイト列
  final hex = bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
  return hex.padRight(64,'0');
}


Map<String, dynamic> buildTransaction({
  required String from,
  required String tokenAddress,
  required String to,
  required BigInt amount,
  required String tag
}) {
  final data = buildErc20TransferData(to, amount,tag);

  return {
    "from": from,
    "to": tokenAddress,
    "data": data,
    "value": "0x0",
    "chainId": "0x${chain_now.ChainId.toRadixString(16)}",
  };
}


class Erc681Request {
  final String token;
  final int chainId;
  final String function;
  final String to;
  final BigInt amount;
  final String tag;

  Erc681Request({
    required this.token,
    required this.chainId,
    required this.function,
    required this.to,
    required this.amount,
    required this.tag
  });
}

Erc681Request parseErc681(String uri) {
  final noScheme = uri.replaceFirst('ethereum:', '');

  final parts = noScheme.split('?');
  final path = parts[0];
  final query = Uri.splitQueryString(parts[1]);

  // 0x...@chainId/transfer
  final pathParts = path.split('/');
  final addressAndChain = pathParts[0];
  final function = pathParts[1];

  final addrSplit = addressAndChain.split('@');

  final token = addrSplit[0];
  checkAddress(token, coin_now);
  final chainId = int.parse(addrSplit[1]);
  if(chainId == Blockchain.eth.ChainId){
    chain_now = Blockchain.eth;
  }
  if(chainId == Blockchain.pol.ChainId){
    chain_now = Blockchain.pol;
  }
  print("now id:${chain_now.ChainId}");
  print("now id:${chainId}");

  final to = query['address']!;
  final amount = parseScientific(query['uint256']!);

  final tag = query.containsKey('tag') ? query['tag']! : "";

  return Erc681Request(
    token: token,
    chainId: chainId,
    function: function,
    to: to,
    amount: amount,
    tag: tag
  );
}

BigInt parseScientific(String input) {
  if (!input.contains('e')) {
    return BigInt.parse(input);
  }

  final parts = input.split('e');
  final base = BigInt.parse(parts[0]);
  final exponent = int.parse(parts[1]);

  return base * BigInt.from(10).pow(exponent);
}

String ShowAmount(BigInt Amount, int Div){
  final s = Amount.toString().padLeft(Div + 1, '0');

  var integer = s.substring(0, s.length - Div);
  var decimal = s.substring(s.length - Div);

  // 末尾ゼロ削除
  decimal = decimal.replaceFirst(RegExp(r'0+$'), '');

  // 先頭ゼロ削除（重要）
  integer = integer.replaceFirst(RegExp(r'^0+'), '');
  if (integer.isEmpty) integer = '0';

  return decimal.isEmpty ? integer : '$integer.$decimal';
}

String filltag(String tag) {
  if(tag.length == 16){
    List<String> tags = [tag.substring(4*0,4*1),tag.substring(4*1,4*2),tag.substring(4*2,4*3),tag.substring(4*3,4*4)];
    return '${tags[0]} - ${tags[1]} - ${tags[2]} - ${tags[3]}';
  }
  return "Invalid tag";
}
