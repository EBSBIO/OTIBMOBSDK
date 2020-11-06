//
// Created by Serge Rybchinsky on 2019-06-06.
// Copyright (c) 2019 Serge Rybchinsky. All rights reserved.
//

import Foundation

//TODO: Make it public for unit tests only
internal protocol UIApplicationProtocol {
	@available(iOS 10.0, *)
	func open(_ url: URL)

	@available(iOS 3.0, *)
	func canOpenURL(_ url: URL) -> Bool
}

internal class Application: UIApplicationProtocol {
	func canOpenURL(_ url: URL) -> Bool {
		return UIApplication.shared.canOpenURL(url)
	}

	func open(_ url: URL) {
		UIApplication.shared.open(url)
	}
}