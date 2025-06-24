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
	static let badCredentialsExemplars: [(Int, Data)] = [
		(500, Data("""
{
  "code":"generic_error",
  "message":"Authentication to server failed."
}
""".utf8)),	// APIv1 (R80) bad username, bad password, bad domain
		(400, Data("""
{
  "code":"err_login_failed",
  "message":"Authentication to server failed."
}
""".utf8))	// APIv1.1-v2 (R80.10-R82) bad username, bad password, bad domain
	]
}

// Exemplars of code/body combinations we expect to return the accountLocked error.
extension UnitTests {
	static let accountLockedExemplars: [(Int, Data)] = [
		(500, Data("""
{
  "code":"generic_error",
  "message":"Administrator account is locked."
}
""".utf8)),	// APIv1 (R80) locked admin account
		(400, Data("""
{
  "code":"err_login_failed",
  "message":"Administrator account is locked."
}
""".utf8)) // APIv1.1-v2 (R80.10-R82) locked admin account
	]
}

// Exemplars of code/body combinations we expect to return the connectionProhibited error.
extension UnitTests {
	/*
	 curl -kv https://standingsmartcenter.mylab.test/web_api/login \
	 -H "Content-Type:application/json" \
	 -d '{"user":"NoApi","password":"1qaz!QAZ"}'
	 */
	static let connectionProhibitedExemplars: [(Int, Data)] = [
		(500, Data("""
{
  "code":"generic_error",
  "message":"API authentication to server 10.0.1.251 failed. Check that you have permission to login through API"
}
""".utf8)),	// APIv1 (R80) no API permission
		(400, Data("""
{
  "code":"err_login_failed",
  "message":"API authentication to server 10.0.1.251 failed. Check that you have permission to login through API"
}
""".utf8))	// APIv1.1-v2 (R80.10-R82) no API permission
	]
}

// Exemplars for the unknownApiVersion error.
extension UnitTests {
	static let unknownApiVersionExemplars: [(Int, Data)] = [
		(400, Data("""
{
  "code":"err_unknown_api_version",
  "message":"Unknown API version: 2"
}
""".utf8))
	]
}

// Exemplars for the invalidObject error.
extension UnitTests {
	static let invalidObjectExemplars: [(Int, Data)] = [
		(404, Data("""
{
  "code":"generic_err_object_not_found",
  "message":"Requested object [00000000-0000-0000-0000-000000000000] not found"
}
""".utf8))
	]
}

// Exemplars for the validationFailed error.
extension UnitTests {
	static let validationFailedExemplars: [(Int, Data)] = [
		(500, Data("""
{
  "code":"generic_error",
  "message":"Validation failed with 1 warning and 1 error",
  "warnings":[{"message":"Multiple objects have the same IP address 10.20.30.40"}],
  "errors":[{"message":"More than one object named 'TestHost' exists."}]}
""".utf8)),	// APIv1
		(400, Data("""
{
  "code":"err_validation_failed",
  "message":"Validation failed with 1 warning and 1 error",
  "warnings":[{"message":"Multiple objects have the same IP address 10.20.30.40"}],
  "errors":[{"message":"More than one object named 'TestHost' exists."}]
}
""".utf8))	// APIv1.1
	]
}

// Exemplars for policyInstallationFailed.
extension UnitTests {
	static let policyInstallationFailedExemplars: [(Int, Data)] = [
		(500, Data("""
{
  "code":"err_policy_installation_failed",
  "message":"Unable to start policy installation: Policy installation on a gateway HoustonFW (Threat policy) is already in progress"
}
""".utf8)),	// APIv1
		(409, Data("""
{
  "code":"err_policy_installation_failed",
  "message":"Unable to start policy installation: Policy installation on a gateway HoustonFW (Threat policy) is already in progress"
}
""".utf8))	// APIv1.1-v2
	]
}
