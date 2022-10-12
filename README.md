# qrcode_recognition

二维码内容识别

## Getting Started

### to use
```
QrcodeDescriptor.recognition("https://xxxxxxx").then((result) {
    print("recognition: $result");
});

QrcodeDescriptor.recognition("file://xxxxxxx").then((result) {
    print("recognition: $result");
});

QrcodeDescriptor.recognition("/xxx/xxx/xxx.png").then((result) {
    print("recognition: $result");
});

QrcodeDescriptor.recognition("base64 字符串").then((result) {
    print("recognition: $result");
});
```
参数 img: 支持base64、url、filePath三种方式

