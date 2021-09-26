import 'package:flutter/material.dart';
import 'package:auro_wallet/utils/format.dart';
import 'package:auro_wallet/utils/UI.dart';
import 'package:auro_wallet/utils/i18n/index.dart';
import 'package:auro_wallet/common/components/backgroundContainer.dart';
import 'package:qr_code_tools/qr_code_tools.dart';
import 'dart:io'; // For Platform.isX
import 'dart:async'; // For Platform.isX
import 'package:rxdart/rxdart.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scan/scan.dart';



class ScanPage extends StatefulWidget {
  const ScanPage();
  static final String route = '/account/scan';
  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  ScanController controller = ScanController();
  StateSetter? stateSetter;
  IconData lightIcon = Icons.flash_on;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller.pause();
    } else if (Platform.isIOS) {
      controller.resume();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _getQrByGallery() {
    final ImagePicker _picker = ImagePicker();
    Stream<XFile?>.fromFuture(
        _picker.pickImage(source: ImageSource.gallery))
        .flatMap((XFile? file) {
          if (file != null) {
            return Stream<String>.fromFuture(
              QrCodeToolsPlugin.decodeFrom(file.path),
            );
          }
          return Stream<String>.value('');
    }).listen((String data) {
      if (data.isNotEmpty) {
        _onScan(data);
      }
    }).onError((dynamic error, dynamic stackTrace) {
    });
  }
  Future _onScan(String? txt) async {
    if (txt == null) {
      return;
    }
    final Map<String, String> dic = I18n.of(context).main;
    String address = '';
    String chainType = '';
    final String data = txt.trim();
    List<String> ls = data.split(':');
    if (ls.length > 0) {
      if (ls.length > 1) {
        if (ls[0].toLowerCase() != 'mina' || !Fmt.isAddress(ls[1])) {
          UI.toast(dic['notValidAddress']!);
        } else {
          chainType = ls[0];
          address = ls[1];
        }
      } else {
        if (!Fmt.isAddress(ls[0])) {
          UI.toast(dic['notValidAddress']!);
        } else {
          address = ls[0];
        }
      }
    }
    if (address.length > 0) {
      print('address detected in Qr');
      Navigator.of(context).pop(QRCodeAddressResult(address: address, chainType: chainType));
    }
  }
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: null,
      body: BackgroundContainer(
        AssetImage(
          'assets/images/public/scan_bg.png',
        ),
        Stack(
          children: [
            ScanView(
              controller: controller,
              scanAreaScale: .7,
              scanLineColor: Theme.of(context).primaryColor,
              onCapture: _onScan,
            ),
            AppBar(
              title: Text(I18n.of(context).main['scan']!, style: TextStyle(color: Colors.white),),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              iconTheme: IconThemeData(
                color: Colors.white, //change your color here
              ),
            ),
            Positioned(
              left: 60,
              bottom: 60,
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  stateSetter = setState;
                  return MaterialButton(
                      child: Icon(lightIcon,size: 40,color: Theme.of(context).primaryColor,),
                      onPressed: (){
                        controller.toggleTorchMode();
                        if (lightIcon == Icons.flash_on){
                          lightIcon = Icons.flash_off;
                        }else {
                          lightIcon = Icons.flash_on;
                        }
                        stateSetter!((){});
                      }
                  );
                },
              ),
            ),
            Positioned(
              right: 60,
              bottom: 60,
              child: MaterialButton(
                  child: Icon(Icons.image,size: 40,color: Theme.of(context).primaryColor,),
                  onPressed: _getQrByGallery
              ),
            )
          ],
        ),
        fit: BoxFit.cover,
      )
    );
  }
}

class QRCodeAddressResult {
  QRCodeAddressResult({required this.chainType,required this.address});
  final String chainType;
  final String address;
}
