//
//  EbsSDKAdapterTests.swift
//  EbsSDKAdapterTests
//
//  Created by Serge Rybchinsky on 23/04/2019.
//  Copyright © 2019 Serge Rybchinsky. All rights reserved.
//

import XCTest
@testable import EbsSDKAdapter

// +
// 1. Освной кейс. Успешный результат
// sdk.set(...) Настройка сдк
// sdk.requestEBSVerification(...) запрос верификации
// sdk.process(...) Обработка ответа от ЕБС
// sdk.requestEBSVerification должен вернуть .success c res_secret из ЕБС в МП КО

// 2. Освной кейс. Верефикация отменена.
// sdk.set(...) Настройка сдк
// sdk.requestEBSVerification(...) запрос верификации
// sdk.process(...) Обработка ответа от ЕБС
// sdk.requestEBSVerification должен вернуть .cancel из ЕБС в МП КО

// 3. Освной кейс. Верефикация окончена с ошибкой.
// sdk.set(...) Настройка сдк
// sdk.requestEBSVerification(...) запрос верификации
// sdk.process(...) Обработка ответа от ЕБС
// sdk.requestEBSVerification должен вернуть .failure из ЕБС в МП КО

// 4. Освной кейс. МП ЕБС не установлен
// sdk.set(...) Настройка сдк
// sdk.requestEBSVerification(...) запрос верификации
// sdk.requestEBSVerification должен вернуть .failure(.ebsIsNotInstalled) из ЕБС в МП КО

// 4. Освной кейс. SDK несконфигурирован
// sdk.requestEBSVerification(...) запрос верификации
// sdk.requestEBSVerification должен вернуть .failure(.sdkIsNotConfigured) из ЕБС в МП КО

class EbsSDKAdapterTests: XCTestCase {
	
	private var mockApp: MockApplication!
	private var sdk: EbsSDKClient!
	
	private let appSchemeKey = "appScheme"
	private let testAppScheme = "com.test.app"
	private let ebsAppSource = "com.waveaccess.Ebs"
	private let appStoreUrl = "itms-apps://itunes.apple.com/app/id1024941703"
	
	private var ebsSessionDetails: EbsSessionDetails {
		return EbsSessionDetails(sid: UUID(), dboKoUri: "dboKoUri", dboKoPublicUri: "dboKoPublicUri", adapterUrl: "adapterUrl")
	}
	
	private func getUrlForProcess(items: [URLQueryItem]) -> URL {
		let urlComponents = NSURLComponents(string: "\(testAppScheme)://")!
		urlComponents.queryItems = [URLQueryItem(name: self.appSchemeKey, value: self.testAppScheme)] + items
		return urlComponents.url!
	}
	
	override func setUp() {
		mockApp = MockApplication()
		sdk = EbsSDKClient(application: mockApp)
	}
	
	override func tearDown() {
		// Put teardown code here. This method is called after the invocation of each test method in the class.
	}
	
	func testField_EbsAppIsInstalled() {
		mockApp.canOpenURLExpected = false
		XCTAssertEqual(sdk.ebsAppIsInstalled, false)
		
		mockApp.canOpenURLExpected = true
		XCTAssertEqual(sdk.ebsAppIsInstalled, true)
	}
	
	func testOpenEbsInAppStore() {
		let expectationOpenEbs = self.expectation(description: "Waiting while SDK opens mp EBS app store page")
		expectationOpenEbs.expectedFulfillmentCount = 1
		
		sdk.set(scheme: testAppScheme, title: "testApp", infoSystem: "testInfo", presenting: nil)
		mockApp.urlDidOpen = { (url) in
			guard url == URL(string: self.appStoreUrl)! else {
				XCTAssertThrowsError("Unexpected url: \(url)")
				return
			}
			
			expectationOpenEbs.fulfill()
		}
		
		sdk.openEbsInAppStore()
		wait(for: [expectationOpenEbs], timeout: 5)
	}
	
	// MARK: - Main case
	// 1.
	func testMainCase() {
		testMainCase(expectedResult: .success(details: .init(resSecret: "")), items: [URLQueryItem(name: EbsVerificationDetails.CodingKeys.resSecret.rawValue, value: UUID().uuidString)])
	}
	
	// 2.
	func testMainCase_VerificationCancelled() {
		testMainCase(expectedResult: .cancel, items: [URLQueryItem(name: "cancel", value: "cancel")])
	}
	
	// 3.
	func testMainCase_VerificationFinishedWithError() {
		testMainCase(expectedResult: .failure(error: .unknown), items: [])
	}
	
	private func testMainCase(expectedResult: EbsSDKClient.RequestEBSVerificationResult, items: [URLQueryItem]) {
		let expectationVerificationResult = self.expectation(description: "Waiting requestEBSVerification result. Expected: \(expectedResult)")
		expectationVerificationResult.expectedFulfillmentCount = 1
		
		let expectationOpenEbs = self.expectation(description: "Waiting while SDK opens mp EBS")
		expectationOpenEbs.expectedFulfillmentCount = 1
		
		mockApp.canOpenURLExpected = true
		
		sdk.set(scheme: testAppScheme, title: "testApp", infoSystem: "testInfo", presenting: nil)
		mockApp.urlDidOpen = { (_) in
			expectationOpenEbs.fulfill()
			
			let processingUrl = self.getUrlForProcess(items: items)
			self.sdk.processEbsVerification(openUrl: processingUrl, from: self.ebsAppSource)
		}
		
		sdk.requestEBSVerification(sessionDetails: self.ebsSessionDetails) { result in
			guard expectedResult.isSimpleEqual(result) else {
				XCTAssertThrowsError("Unexpected result: \(result)")
				return
			}
			
			expectationVerificationResult.fulfill()
		}
		
		wait(for: [expectationVerificationResult, expectationOpenEbs], timeout: 5)
	}
	
	// 4.
	func testMainCase_EbsIsNotInstalled() {
		let expectationVerificationResult = self.expectation(description: "Waiting requestEBSVerification result. Expected .ebsNotInstalled error ")
		expectationVerificationResult.expectedFulfillmentCount = 1
		
		mockApp.canOpenURLExpected = false
		
		sdk.set(scheme: testAppScheme, title: "testApp", infoSystem: "testInfo", presenting: nil)
		sdk.requestEBSVerification(sessionDetails: self.ebsSessionDetails) { result in
			switch result {
			case .failure(let error):
				guard case .ebsNotInstalled = error else {
					XCTAssertThrowsError("Unexpected error: \(error)")
					return
				}
				
				expectationVerificationResult.fulfill()
				
			case .cancel, .success:
				XCTAssertThrowsError("Unexpected result: \(result)")
			}
		}
		
		wait(for: [expectationVerificationResult], timeout: 5)
	}
	
	// 5.
	func testMainCase_SdkIsNotConfigured() {
		let expectationVerificationResult = self.expectation(description: "Waiting requestEBSVerification result. Expected .sdkIsNotConfigured error")
		expectationVerificationResult.expectedFulfillmentCount = 1
		
		mockApp.canOpenURLExpected = false
		
		sdk.requestEBSVerification(sessionDetails: self.ebsSessionDetails) { result in
			switch result {
			case .failure(let error):
				guard case .sdkIsNotConfigured = error else {
					XCTAssertThrowsError("Unexpected error: \(error)")
					return
				}
				
				expectationVerificationResult.fulfill()
				
			case .cancel, .success:
				XCTAssertThrowsError("Unexpected result: \(result)")
			}
		}
		
		wait(for: [expectationVerificationResult], timeout: 5)
	}
}

extension EbsSDKClient.RequestEBSVerificationResult {
	public func isSimpleEqual(_ other: EbsSDKClient.RequestEBSVerificationResult) -> Bool {
		switch (self, other) {
		case (.cancel, .cancel): return true
		case (.failure, .failure): return true
		case (.success, .success): return true
		default: return false
		}
	}
}

class MockApplication: UIApplicationProtocol {
	public var urlDidOpen: ((URL) -> Void)?
	public var canOpenURLExpected: Bool = false
	
	func open(_ url: URL) {
		urlDidOpen?(url)
	}
	
	func canOpenURL(_ url: URL) -> Bool {
		if url.scheme != "ebs" {
			XCTAssertThrowsError("Scheme of url must be \"ebs:\"")
		}
		
		return canOpenURLExpected
	}
}
