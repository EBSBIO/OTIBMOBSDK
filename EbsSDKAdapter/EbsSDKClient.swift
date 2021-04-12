//
//  EbsSDKClient.swift
//  EbsSDKAdapter
//
//  Created by Serge Rybchinsky on 23/04/2019.
//  Copyright © 2019 Serge Rybchinsky. All rights reserved.
//

import Foundation

extension EbsSDKClient {

	/// EBS verification completion handler
	public typealias RequestEBSVerificationCompletion = (RequestEBSVerificationResult) -> Void

	/// Enum describes EBS Verification result
	public enum RequestEBSVerificationResult {
		case success(details: EbsVerificationDetails)
		case failure(error: RequestEBSVerificationError)
		case cancel
	}

	/// Enum describes EBS Verification errors
	public enum RequestEBSVerificationError {
		case ebsNotInstalled
		case verificationFailed
		case sdkIsNotConfigured
		case unknown
	}
}

extension EbsSDKClient {

	private struct Constants {
		/// Url to EBS's app store page
		static let appStoreUrl = "itms-apps://itunes.apple.com/app/id1436489633"

		/// EBS BundleURLSchemes
		static let ebsBundleURLSchemes = "ebs://"
	}

	/// Structure describes keys which are using in URL
	private struct EbsRequestKeys {

		/// Scheme mobile application of Credit organization
		static let applicationSchemeKey = "appScheme"

		/// Mobile application title of Credit organization
		static let titleKey = "title"

		/// Information system about Mobile application of Credit organization
		static let infoSystemKey = "info_system"

		/// Cancel result identifier
		static let cancelKey = "cancel"
	}

	/// Text resources
	private struct Texts {
		static let ebsNotInstalledMessage = "Для авторизации необходимо установить приложение Единая биометрическая система"
		static let ebsNotInstalledCancelButtonTitle = "Отмена"
		static let ebsNotInstalledTitle = "Установить"
		static let ebsApplicationTitle = "Единая биометрическая система"
	}

	private enum State {
		case none
		case ebsVerification(completion: RequestEBSVerificationCompletion)
	}
}

public class EbsSDKClient {

	//MARK: - Public variables

	/// Shared instance of SDK client
	public static let shared = EbsSDKClient(application: Application())

	/// Describes ebs app is installed or not
	public var ebsAppIsInstalled: Bool {
		guard var urlComponents = URLComponents(string: Constants.ebsBundleURLSchemes) else {
			return false
		}

		let queryItems = [
			URLQueryItem(name: EbsRequestKeys.applicationSchemeKey, value: appUrlScheme),
			URLQueryItem(name: EbsRequestKeys.titleKey, value: self.appTitle),
			URLQueryItem(name: EbsRequestKeys.infoSystemKey, value: infoSystem)]

		urlComponents.queryItems = queryItems

		if let url = urlComponents.url, application.canOpenURL(url) {
			return true
		}
		else {
			return false
		}
	}
	
	//MARK: - Private variables

	private var application: UIApplicationProtocol
	private var appUrlScheme: String?
	private var appTitle: String?
	private var infoSystem: String?
	private var presentingController: UIViewController?
	private var ebsVerificationState: State = .none

	//MARK: - Inits

	//TODO: Make it public for unit tests only
	private init(application: UIApplicationProtocol) {
		self.application = application
	}

	//MARK: - Public

	/// Сonfigures SDK for specific app
	///  - Parameter appUrlScheme: Url scheme of the app
	///  - Parameter appTitle: Name of the app
	///  - Parameter infoSystem: System information about the app
	///  - Parameter presenting: Current view controller. Needs for show alert when ebs is not installed
	public func set(scheme: String, title: String, infoSystem: String, presenting controller: UIViewController?) {
		self.appUrlScheme = scheme
		self.appTitle = title
		self.infoSystem = infoSystem
		self.presentingController = controller
	}

	/// Requests EBS verification and returns EBS verification token
	///  - Parameter sessionId: EBS session identifier
	///  - Parameter completion: Completion handler
	public func requestEBSVerification(sessionDetails: EbsSessionDetails, completion: @escaping RequestEBSVerificationCompletion) {
		ebsVerificationState = .ebsVerification(completion: completion)
		openUrlIfNeeded(sessionDetails: sessionDetails)
	}

	/// Processes url with receive from EBS. Should be invoked in AppDelegate.application(_ app:, open:, options:)
	///  - Parameter openUrl: The URL resource to open
	///  - Parameter options: A dictionary of URL handling options.
	public func processEbsVerification(openUrl: URL, options: [UIApplication.OpenURLOptionsKey: Any]) {
		switch ebsVerificationState {
		case .ebsVerification(let completion):

			guard let urlComponents = URLComponents(string: openUrl.absoluteString), let queryItems = urlComponents.queryItems else {
				completion(.failure(error: .unknown))
				return
			}

			if let resSecret = getValue(from: queryItems, for: EbsVerificationDetails.CodingKeys.resSecret) {
				completion(.success(details: EbsVerificationDetails(resSecret: resSecret)))
				return
			}

			if getValue(from: queryItems, for: EbsRequestKeys.cancelKey) != nil {
				completion(.cancel)
				return
			}

			completion(.failure(error: .verificationFailed))

		case .none:
			break
		}
	}

	/// Opens EBS app in App store
	public func openEbsInAppStore() {
		guard  let url = URL(string: Constants.appStoreUrl) else { return }
		application.open(url)
	}
	
	private func openUrlIfNeeded(sessionDetails: EbsSessionDetails) {
		guard
				let appUrlScheme = self.appUrlScheme,
				var urlComponents = URLComponents(string: Constants.ebsBundleURLSchemes),
				let appTitle = appTitle,
				let infoSystem = infoSystem else {
			showSDKIsNotConfigured()
			return
		}

		let queryItems = [
			URLQueryItem(name: EbsRequestKeys.applicationSchemeKey, value: appUrlScheme),
			URLQueryItem(name: EbsRequestKeys.titleKey, value: appTitle),
			URLQueryItem(name: EbsSessionDetails.CodingKeys.sid.rawValue, value: sessionDetails.sid),
			URLQueryItem(name: EbsSessionDetails.CodingKeys.dboKoUri.rawValue, value: sessionDetails.dboKoUri),
			URLQueryItem(name: EbsSessionDetails.CodingKeys.dboKoPublicUri.rawValue, value: sessionDetails.dboKoPublicUri),
			URLQueryItem(name: EbsSessionDetails.CodingKeys.adapterUrl.rawValue, value: sessionDetails.adapterUrl),
			URLQueryItem(name: EbsRequestKeys.infoSystemKey, value: infoSystem)]

		urlComponents.queryItems = queryItems

		DispatchQueue.main.async {
			if let url = urlComponents.url, self.application.canOpenURL(url) {
				self.application.open(url)
			}
			else {
				self.showEbsNotInstalledAlert(ebsVerificationState: self.ebsVerificationState)
			}
		}
	}

	private func showSDKIsNotConfigured() {
		switch ebsVerificationState {
		case .ebsVerification(let completion):
			completion(RequestEBSVerificationResult.failure(error: .sdkIsNotConfigured))
		case .none:
			break
		}
	}

	private func showEbsNotInstalledAlert(ebsVerificationState: State) {

		if let presentingController = presentingController {
			let alert = UIAlertController(title: Texts.ebsApplicationTitle, message: Texts.ebsNotInstalledMessage, preferredStyle: .alert)
			let cancel = UIAlertAction(title: Texts.ebsNotInstalledCancelButtonTitle, style: .cancel, handler: nil)
			alert.addAction(cancel)
			let install = UIAlertAction(title: Texts.ebsNotInstalledTitle, style: .default) { _ in
				if let url = URL(string: Constants.appStoreUrl) {
					self.application.open(url)
				}
			}
			alert.addAction(install)
			presentingController.present(alert, animated: true, completion: nil)
		}
		
		switch ebsVerificationState {
		case .ebsVerification(let completion):
			completion(RequestEBSVerificationResult.failure(error: .ebsNotInstalled))
		case .none:
			break
		}
	}

	// MARK: Private URLQueryItem array parsing helpers

	private func getValue(from queryItems: [URLQueryItem], for key: EbsVerificationDetails.CodingKeys) -> String? {
		return getValue(from: queryItems, for: key.rawValue)
	}

	private func getValue(from queryItems: [URLQueryItem], for key: String) -> String? {
		return queryItems.first(where: { $0.name == key })?.value
	}
}
