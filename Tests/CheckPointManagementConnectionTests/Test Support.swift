//
//  Test Support.swift
//  CheckPointManagementConnection
//
//  Created by Bob Zimmerman on 2024-12-10.
//
// This file contains data which is used to drive the various tests. I use it to
// ensure my tests all connect to a consistent place with consistent good or bad
// credentials.

import Foundation
import Testing

extension Tag {
	@Tag static var local: Self
	@Tag static var serverRequired: Self
}

enum TestData {
	static let url = URL(string: "https://standingsmartcenter.mylab.test/")!
	static let username = "PasswordUser"
	static let password = "1qaz!QAZ"
	static let uuidZero = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
	
	/// Some names of specific things which must exist:
	static let noApiUser = "NoApi" // Has to be a valid user with no API permission
	static let policyPackageName = "Standard"
	static let firewallName = "BerlinFW"
	
	/// And a few constants for bad things which must not exist in the config:
	static let badUrl = URL(string: "data:text/plain,Hello World")!
	static let badDomain = "Fake Domain Which Doesn't Exist"
	static let badUsername = "This user doesn't exist"
	static let badPassword = "2wsx@WSX"
}
