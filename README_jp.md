# Watson Visual Recognition と Core ML

[Watson Visual Recognition][vizreq] と [Core ML][core_ml] を使用して、画像をオフラインで判定します。

ディープ・ニューラル・ネットワークモデルは、Watson Visual Recognition によってクラウド上でトレーニングします。その後、アプリケーションは CoreML によってオフラインで使用できるモデルをダウンロードして、画像を判定します。アプリケーションを起動する度に、モデルへの更新があるかどうかをチェックし、更新がある場合はダウンロードします。

![App Screenshot][screenshot_iphone]

## はじめに
下記のバージョンのソフトウェアがマシンにインストールされていることを確認してください。 **Core MLをサポートするために必要です。**

- **MacOS 10.11 El Capitan** またはそれ以降
- **iOS 11** またはそれ以降 (iPhone や iPad の実機でアプリケーションをデバッグ実行する場合)
- **[Xcode 9][xcode_download]** またはそれ以降
- **[Carthage 0.29][carthage_instructions]** またはそれ以降

> **Carthage のインストール**
>
> Homebrew がインストールされていない場合は、`.pkg` インストーラーで Carthage をインストールする方法が簡単です。[ここ][carthage_download]からダウンロードできます。

## ファイルの取得
GitHubから git clone でリポジトリをローカルにクローンするか、リポジトリの.zipファイルを直接ダウンロードしてファイルを展開してください。

## Watson Studio での Visual Recognition の設定
1. Watson Studio ([dataplatform.ibm.com][watson_studio_url]) にログインする。 このリンク先では、IBM Cloud アカウントを作成したり、Watson Studio にサインアップしたり、ログインすることができる。

## カスタムモデルのトレーニング
カスタムモデルを作成するための詳細な手順については [Core ML & Watson Visual Recognition Code Pattern][code_pattern] を参照してください。

## Watson Swift SDK のインストール
Watson Swift SDK を使用すると、カスタム Core ML モデルを追跡したり、IBM Cloud からカスタムで用意した情報をデバイスにダウンロードしたりすることが行えるようになります。

Carthage依存関係マネージャを使用して、Watson Swift SDKをダウンロードします。

1. ターミナルを起動し、このプロジェクトの作業ディレクトリに移動する。
2. 次のコマンドを実行して、Watson Swift SDKをダウンロードする。

    ```bash
    carthage update --platform iOS
    ```

## アプリケーションの設定
1. XCode でプロジェクトを開いてください。
2. トレーニングしたモデルの **Model ID** をコピーし、[`CameraViewController.swift`][camera_view_controller]  の `modelId` に入力する。 
3. Visual Recognition Service の資格情報から **"apikey"** をコピーし、 [`Credentials.plist`][credentials_plist] ファイルの `apiKey` に入力する。

## アプリケーションの実行
1. XCode で `Core ML Vision` スキームを選択する。
1. シミュレータまたは実機上でアプリケーションを実行する。
> **Note:** Visual Recognition のステータスは **Ready** になっている必要があります。Watson Studio 上に作成した Visual Recognition の概要ページのでステータスを確認してください。

## 次に試してほしいこと

独自データの利用について：  
手持ちの画像を Visual Recognition でトレーニングしてください。Visual Recognition の詳細については、下記のリソースのリンクを参照してください。

## リソース

- [Visual Recognition docs](https://console.bluemix.net/docs/services/visual-recognition/getting-started.html)
- [Watson Swift SDK](https://github.com/watson-developer-cloud/swift-sdk)
- [Apple machine learning][core_ml] and [Core ML documentation](https://developer.apple.com/documentation/coreml)
- [Watson console](https://bluemix.net/developer/watson) on IBM Cloud

[code_pattern]: https://watson-developer-cloud.github.io/watson-vision-coreml-code-pattern/
[watson_studio_url]: https://dataplatform.ibm.com
[carthage_download]: https://github.com/Carthage/Carthage/releases
[carthage_instructions]: https://github.com/Carthage/Carthage#installing-carthage
[vizreq]: https://www.ibm.com/watson/services/visual-recognition/
[core_ml]: https://developer.apple.com/machine-learning/
[vizreq_with_coreml]: https://github.com/watson-developer-cloud/visual-recognition-coreml/
[vizreq_tooling]: https://watson-visual-recognition.ng.bluemix.net/
[xcode_download]: https://developer.apple.com/xcode/downloads/

[camera_view_controller]: /Core%20ML%20Vision/CameraViewController.swift
[credentials_plist]: /Core%20ML%20Vision/Credentials.plist

[screenshot_iphone]: /Screenshots/iPhone.png
