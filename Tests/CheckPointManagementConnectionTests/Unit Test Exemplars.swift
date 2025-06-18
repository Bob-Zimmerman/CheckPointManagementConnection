//
//  Exemplar Errors.swift
//  CheckPointManagementConnection
//
//  Created by Bob Zimmerman on 2025-06-18.
//

import Foundation

// Exemplars of code/body combinations we expect to return the badCredentials error.
extension UnitTests {
	/*
	 curl -kv https://standingsmartcenter.mylab.test/web_api/login \
	 -H "Content-Type:application/json" \
	 -d '{"user":"PasswordUser","password":"2wsx@WSX"}'
	 */
	static let badCredentialsExemplars = [
		(400, Data("""
{
  "code" : "err_login_failed",
  "message" : "Authentication to server failed."
}
""".utf8)) // R82 bad username, bad password, bad domain
	]
}

// Exemplars of code/body combinations we expect to return the accountLocked error.
extension UnitTests {
	static let accountLockedExemplars = [
		(400, Data("""
{
  "code" : "err_login_failed",
  "message" : "Administrator account is locked."
}
""".utf8)) // R82 locked admin account
	]
}

// Exemplars of code/body combinations we expect to return the connectionProhibited error.
extension UnitTests {
	/*
	 curl -kv https://standingsmartcenter.mylab.test/web_api/login \
	 -H "Content-Type:application/json" \
	 -d '{"user":"NoApi","password":"1qaz!QAZ"}'
	 */
	static let connectionProhibitedExemplars = [
		(400, Data("""
{
  "code": "err_login_failed",
  "message": "API authentication to server 10.0.1.251 failed. Check that you have permission to login through API"
}
""".utf8))	// R82 no API permission
	]
}
