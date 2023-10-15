# EbsSDKAdapter

[![CI Status](https://img.shields.io/travis/sergey.rybchinsky@waveaccess.ru/EbsSDKAdapter.svg?style=flat)](https://travis-ci.org/sergey.rybchinsky@waveaccess.ru/EbsSDKAdapter)
[![Version](https://img.shields.io/cocoapods/v/EbsSDKAdapter.svg?style=flat)](https://cocoapods.org/pods/EbsSDKAdapter)
[![License](https://img.shields.io/cocoapods/l/EbsSDKAdapter.svg?style=flat)](https://cocoapods.org/pods/EbsSDKAdapter)
[![Platform](https://img.shields.io/cocoapods/p/EbsSDKAdapter.svg?style=flat)](https://cocoapods.org/pods/EbsSDKAdapter)


SDK ЕБС обеспечивает:
1.	Проверку наличия мобильного приложения для идентификации (МП ЕБС).
2.	Формирование запроса на прохождение биометрической верификации в ЕБС.
3.	Взаимодействие пользовательского приложения и МП ЕБС для биометрической верификации.

## Installation

EbsSDK is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
source 'https://github.com/EBSBIO/OTIBMOBSDK'

...

pod 'EbsSDKAdapter', '~> 2.0'
```

## Author

sergey.rybchinsky@waveaccess.ru, sergey.rybchinsky@waveaccess.ru

## License

EbsSDKAdapter is available under the MIT license. See the LICENSE file for more info.

## Usage

1. Добавьте в info.plist в LSApplicationQueriesSchemes ключ ebs
2. Добавьте в URL Types URL схему с названием вашего приложения
3. в методе requestAuthorization в параметр urlScheme внесите указанное в п.2 название приложение
4. в AppDelegate добавьте метод  application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool и в него добавьте метод sdk processEbsVerification(openUrl: URL, options: String), пример: EbsSDKClient.shared.process(openUrl: URL, options: [UIApplication.OpenURLOptionsKey: Any])

## Dependencies

Приложение не использует дополнительные библиотеки для своей работы.
Для разрабатываемого приложения должен быть зарегистрирована URL-Scheme для возможности перехода в приложение с приложения МП ЕБС https://developer.apple.com/library/content/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/Inter-AppCommunication/Inter-AppCommunication.html.
Для разрабатываемого приложения должен быть добавлен ключ в info.plist в LSApplicationQueriesSchemes с значением ebs.


## Introduction
To be added
