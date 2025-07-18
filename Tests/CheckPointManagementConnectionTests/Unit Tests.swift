//
//  Unit Tests.swift
//  CheckPointManagementConnection
//
//  Created by Bob Zimmerman on 2024-12-10.
//

import Foundation
import Testing
@testable import CheckPointManagementConnection

@Suite(.tags(.local)) struct UnitTests {
	@Test func getUserDataLoginBody() throws {
		let loginResponseDict: [String: Sendable] = [ "api-server-version": "1.9.1",
													  "session-timeout": 600,
													  "sid": "",
													  "url": "data:text/plain,Hello World" ]
		let loginResponseData = try JSONSerialization.data(withJSONObject: loginResponseDict)
		let loginResponse = try JSONDecoder().decode(CPMLoginResponse.self, from: loginResponseData)
		#expect(try ("admin", true) == CheckPointManagement.getUserData(
			["user": "admin", "read-only": true], response: loginResponse))
	}
	
	@Test func getUserDataLoginResponse() throws {
		let loginResponseDict: [String: Sendable] = [ "api-server-version": "1.9.1",
													  "read-only": true,
													  "session-timeout": 600,
													  "sid": "",
													  "url": "data:text/plain,Hello World",
													  "user-name": "admin"]
		let loginResponseData = try JSONSerialization.data(withJSONObject: loginResponseDict)
		let loginResponse = try JSONDecoder().decode(CPMLoginResponse.self, from: loginResponseData)
		#expect(try ("admin", true) == CheckPointManagement.getUserData([:], response: loginResponse))
	}
	
	@Test func getUserDataNeither() throws {
		let loginResponseDict: [String: Sendable] = [ "api-server-version": "1.9.1",
													  "session-timeout": 600,
													  "sid": "",
													  "url": "data:text/plain,Hello World" ]
		let loginResponseData = try JSONSerialization.data(withJSONObject: loginResponseDict)
		let loginResponse = try JSONDecoder().decode(CPMLoginResponse.self, from: loginResponseData)
		#expect(throws: CPMError.unknownError) { try CheckPointManagement.getUserData([:], response: loginResponse) }
	}
	
	@Test func handleApiErrors200() throws {
		#expect(try Data([0]) == CheckPointManagement.handleApiReturnErrors((Data([0]), HTTPURLResponse(
			url: TestData.badUrl,
			statusCode: 200,
			httpVersion: "2",
			headerFields: nil)!)))
	}
	
	@Test(arguments: UnitTests.badCredentialsExemplars)
	func badCredentials(exemplar: (code: Int, body: Data)) {
		#expect(throws: CPMError.badCredentials) {
			try CheckPointManagement.handleApiReturnErrors((exemplar.body, HTTPURLResponse(
				url: TestData.badUrl,
				statusCode: exemplar.code,
				httpVersion: "2",
				headerFields: nil)!)) }
	}
	
	@Test(arguments: UnitTests.accountLockedExemplars)
	func accountLocked(exemplar: (code: Int, body: Data)) {
		#expect(throws: CPMError.accountLocked) {
			try CheckPointManagement.handleApiReturnErrors((exemplar.body, HTTPURLResponse(
				url: TestData.badUrl,
				statusCode: exemplar.code,
				httpVersion: "2",
				headerFields: nil)!)) }
	}
	
	@Test(arguments: UnitTests.connectionProhibitedExemplars)
	func connectionProhibited(exemplar: (code: Int, body: Data)) {
		#expect(throws: CPMError.connectionProhibited) {
			try CheckPointManagement.handleApiReturnErrors((exemplar.body, HTTPURLResponse(
				url: TestData.badUrl,
				statusCode: exemplar.code,
				httpVersion: "2",
				headerFields: nil)!)) }
	}
	
	@Test(arguments: UnitTests.unknownApiVersionExemplars)
	func unknownApiVersion(exemplar: (code: Int, body: Data)) {
		#expect(throws: CPMError.unknownApiVersion) {
			try CheckPointManagement.handleApiReturnErrors((exemplar.body, HTTPURLResponse(
				url: TestData.badUrl,
				statusCode: exemplar.code,
				httpVersion: "2",
				headerFields: nil)!)) }
	}
	
	@Test(arguments: UnitTests.invalidObjectExemplars)
	func invalidObject(exemplar: (code: Int, body: Data)) {
		#expect(throws: CPMError.invalidObject) {
			try CheckPointManagement.handleApiReturnErrors((exemplar.body, HTTPURLResponse(
				url: TestData.badUrl,
				statusCode: exemplar.code,
				httpVersion: "2",
				headerFields: nil)!)) }
	}
	
	@Test(arguments: UnitTests.validationFailedExemplars)
	func validationFailed(exemplar: (code: Int, body: Data)) {
		#expect {
			try CheckPointManagement.handleApiReturnErrors((exemplar.body, HTTPURLResponse(
				url: TestData.badUrl,
				statusCode: exemplar.code,
				httpVersion: "2",
				headerFields: nil)!)) } throws: { (error) in
					let error = error as NSError
					try #require((CPMError.validationFailed.domain, CPMError.validationFailed.code) == (error.domain, error.code))
					return true
				}
	}
	
	@Test(arguments: UnitTests.policyInstallationFailedExemplars)
	func policyInstallationFailed(exemplar: (code: Int, body: Data)) {
		#expect {
			try CheckPointManagement.handleApiReturnErrors((exemplar.body, HTTPURLResponse(
				url: TestData.badUrl,
				statusCode: exemplar.code,
				httpVersion: "2",
				headerFields: nil)!)) } throws: { (error) in
					let error = error as NSError
					try #require((CPMError.policyInstallationFailed.domain, CPMError.policyInstallationFailed.code)
								 == (error.domain, error.code))
					return true
				}
	}
	
	@Test func handleApiErrors503() {
		#expect(throws: CPMError.apiDown) { try CheckPointManagement.handleApiReturnErrors((Data([0]), HTTPURLResponse(
			url: TestData.badUrl,
			statusCode: 503,
			httpVersion: "2",
			headerFields: nil)!)) }
	}
	
	@Test func handleApiErrorsBadResponse() throws {
		#expect { try CheckPointManagement.handleApiReturnErrors((Data([0]), URLResponse(
			url: TestData.badUrl,
			mimeType: "text/plain",
			expectedContentLength: 11,
			textEncodingName: nil))) } throws: { (error) in
				let error = error as NSError
				try #require((NSCocoaErrorDomain, 4864) == (error.domain, error.code))
				return true
			}
	}
	
	@Test func unhandledErrorGeneric() {
		#expect(throws: CPMError.unknownError) { try CheckPointManagement.handleApiReturnErrors((Data([0]), HTTPURLResponse(
			url: TestData.badUrl,
			statusCode: 0,
			httpVersion: "2",
			headerFields: nil)!)) }
	}
	
	@Test func unhandledErrorWithDetails() {
		#expect { try CheckPointManagement.handleApiReturnErrors((Data("""
  {"code":"err_fake_code","message":"Fake error message.","errors":[{"message":"Something is very wrong!"}]}
""".utf8), HTTPURLResponse(
			url: TestData.badUrl,
			statusCode: 0,
			httpVersion: "2",
			headerFields: nil)!)) } throws: { (error) in
				let error = error as NSError
				try #require((CPMError.unknownError.domain, CPMError.unknownError.code) == (error.domain, error.code))
				return true
			}
	}
	
	@Test func firstTaskBadData() throws {
		#expect(throws: (any Error).self) { try CheckPointManagement.getFirstTask(Data([0])) }
	}
	
	@Test func firstTaskBadJson() throws {
		#expect(try nil == CheckPointManagement.getFirstTask(
			JSONSerialization.data(withJSONObject: [["": ""]])))
	}
	
	@Test func firstTaskNoOuterArray() throws {
		#expect(try nil == CheckPointManagement.getFirstTask(
			JSONSerialization.data(withJSONObject: ["": ""])))
	}
	
	@Test func taskIdBadData() throws {
		#expect(throws: (any Error).self) { try CheckPointManagement.getTaskId(Data([0])) }
	}
	
	@Test func taskIdBadJson() throws {
		#expect(try nil == CheckPointManagement.getTaskId(
			JSONSerialization.data(withJSONObject: ["": ""])))
	}
	
	@Test func taskIdJsonArray() throws {
		#expect(try nil == CheckPointManagement.getTaskId(
			JSONSerialization.data(withJSONObject: [["": ""]])))
	}
	
	@Test func taskStatusMissingKey() throws {
		#expect("in progress" == CheckPointManagement.getTaskStatus([:]))
	}
	
	@Test func taskStatusNil() throws {
		#expect("in progress" == CheckPointManagement.getTaskStatus(nil))
	}
	
	@Test func decodeDateInSeconds() throws {
		let jsonData = Data("""
{
  "iso-8601" : "2025-03-16T14:56+0000",
  "posix" : 1742137014
}
""".utf8)
		let date: Date = try JSONDecoder().decode(CPMDate.self, from: jsonData).posix
		#expect(1 > abs(date.distance(to: Date(timeIntervalSince1970: 1742137014))))
	}
	
	@Test func decodeDateInMilliseconds() throws {
		let jsonData = Data("""
{
  "posix" : 1728954737923,
  "iso-8601" : "2024-10-15T01:12+0000"
}
""".utf8)
		let date: Date = try JSONDecoder().decode(CPMDate.self, from: jsonData).posix
		#expect(1 > abs(date.distance(to: Date(timeIntervalSince1970: 1728954738))))
	}
	
	@Test func buildPolicyPushParameters() {
		let sixBools: [Bool] = Array(1...6).map { _ in Bool.random() }
		let pushParameters = PolicyPushParameters(
		access: sixBools[0],
		desktopSecurity: sixBools[1],
		qos: sixBools[2],
		threatPrevention: sixBools[3],
		installOnAllClusterMembersOrFail: sixBools[4],
		prepareOnly: sixBools[5])
		#expect(sixBools[0] == pushParameters.access)
		#expect(sixBools[1] == pushParameters.desktopSecurity)
		#expect(sixBools[2] == pushParameters.qos)
		#expect(sixBools[3] == pushParameters.threatPrevention)
		#expect(sixBools[4] == pushParameters.installOnAllClusterMembersOrFail)
		#expect(sixBools[5] == pushParameters.prepareOnly)
	}
}
