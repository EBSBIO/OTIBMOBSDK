//
// Created by Serge Rybchinsky on 2019-04-19.
// Copyright (c) 2019 Vitalii Poponov. All rights reserved.
//

import Foundation

public struct EbsVerificationDetails {
	enum CodingKeys: String {
		case resSecret = "res_secret"
	}

	public var resSecret: String
}
