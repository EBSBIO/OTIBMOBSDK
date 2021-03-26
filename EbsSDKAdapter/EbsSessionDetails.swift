//
// Created by Serge Rybchinsky on 2019-04-19.
// Copyright (c) 2019 Vitalii Poponov. All rights reserved.
//

import Foundation

public struct EbsSessionDetails {

	enum CodingKeys: String {
		case sid = "sid"
		case dboKoUri = "dbo_ko_uri"
		case dboKoPublicUri = "dbo_ko_public_uri"
		case adapterUrl = "adapter_url"
	}

	/// Session identifier
	var sid: String

	/// URL "API for obtaining the result of verification of  DBO KO",
	/// where Adapter should return the result of bio verification  and user's PDn.
	var dboKoUri: String

	// Public URL DBO KO, where Adapter should redirect user when bio verification have finished successfully or with error.
	var dboKoPublicUri: String

	// Adapter url for bio verification.
	var adapterUrl: String

	public init(sid: String, dboKoUri: String, dboKoPublicUri: String, adapterUrl: String) {
		self.sid = sid
		self.dboKoUri = dboKoUri
		self.dboKoPublicUri = dboKoPublicUri
		self.adapterUrl = adapterUrl
	}
}
