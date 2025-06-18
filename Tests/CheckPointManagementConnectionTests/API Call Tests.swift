//
//  API Call Tests.swift
//  CheckPointManagementConnection
//
//  Created by Bob Zimmerman on 2024-12-10.
//

import Foundation
import Testing
@testable import CheckPointManagementConnection

@Suite(.serialized, .tags(.serverRequired)) struct ApiCallTests {
	internal var managementConnection: CheckPointManagement?
	
	init() async throws {
		do { managementConnection = try await CheckPointManagement(
			url: TestData.url,
			username: TestData.username,
			password: TestData.password,
			readOnly: false)
		} catch { Issue.record("Error: \(String(describing: error))") }
	}
	
	func tearDown() async throws {
		try await managementConnection?.discard()
		try await managementConnection?.logout()
	}
	
	@Test func discardWithSessionId() async throws {
		await #expect(throws: CPMError.invalidObject) {
			try await managementConnection?.discard(sessionUUID: TestData.uuidZero) }
		try await tearDown()
	}
	
	@Test func keepalive() async throws {
		let managementConnection = try #require(managementConnection)
		try await managementConnection.keepalive()
		try await tearDown()
	}
	
	@Test func publish() async throws {
		let managementConnection = try #require(managementConnection)
		let taskId = try #require(await managementConnection.publish())
		_ = try await managementConnection.syncTask(taskId, checkInterval: 1, maxDuration: 20)
		try await tearDown()
	}
	
	@Test func pushPolicyInvalid() async throws {
		await #expect(throws: CPMError.invalidObject) {
			_ = try await managementConnection?.pushPolicy(
				TestData.uuidZero,
				to: [TestData.uuidZero],
				pushParameters: PolicyPushParameters(
					access: true,
					desktopSecurity: false,
					qos: false,
					threatPrevention: true,
					installOnAllClusterMembersOrFail: true,
					prepareOnly: false)) }
		try await tearDown()
	}
	
	@Test func pushPolicy() async throws {
		let managementConnection = try #require(managementConnection)
		let policyData = try await managementConnection.makeRawApiCall(
			apiPoint: "/show-package", requestBody: ["name": TestData.policyPackageName])
		let policyDict = try #require(JSONSerialization.jsonObject(with: policyData) as? [String: Sendable])
		let policyUuid = try #require(UUID(uuidString: policyDict["uid"] as? String ?? ""))
		let fwData = try await managementConnection.makeRawApiCall(
			apiPoint: "/show-simple-cluster", requestBody: ["name": TestData.firewallName])
		let fwDict = try #require(JSONSerialization.jsonObject(with: fwData) as? [String: Sendable])
		let fwUuid = try #require(UUID(uuidString: fwDict["uid"] as? String ?? ""))
		_ = try await managementConnection.pushPolicy(
			policyUuid,
			to: [fwUuid],
			pushParameters: PolicyPushParameters(
				access: true,
				desktopSecurity: false,
				qos: false,
				threatPrevention: true,
				installOnAllClusterMembersOrFail: true,
				prepareOnly: false))
		try await tearDown()
	}
	
	@Test func timerKeepalive() async throws {
		let managementConnection = try #require(managementConnection)
		await managementConnection.fireTimer()
		try await Task.sleep(nanoseconds: 1_000_000_000)
		try await tearDown()
	}
}

@Suite(.serialized, .tags(.serverRequired)) struct ApiCallTestsSelfContained {
	@Test func discardReadOnly() async throws {
		let connection = try await CheckPointManagement(
			url: TestData.url,
			username: TestData.username,
			password: TestData.password,
			readOnly: true)
		await #expect(throws: CPMError.writeCallInReadOnlySession) {
			try await connection.discard() }
		try await connection.logout()
	}
	
	@Test func loginToDomain() async throws {
		let connection = try await CheckPointManagement(
			url: TestData.url,
			domain: "System Data",
			username: TestData.username,
			password: TestData.password,
			readOnly: false)
		try await connection.logout()
	}
	
	@Test func loginWithApiKey() async throws {
		// First, we make a new API key for the user.
		let systemDataSession = try await CheckPointManagement(
			url: TestData.url,
			domain: "System Data",
			username: TestData.username,
			password: TestData.password,
			readOnly: false)
		let apiKeyData = try await systemDataSession.makeRawApiCall(
			apiPoint: "/add-api-key",
			requestBody: ["admin-name": "apiKeyUser"])
		let apiKeyDict = try JSONSerialization.jsonObject(with: apiKeyData) as? [String: Sendable]
		let apiKey = try #require(apiKeyDict?["api-key"] as? String)
		let taskId = try #require(await systemDataSession.publish())
		_ = try await systemDataSession.syncTask(taskId, checkInterval: 1, maxDuration: 20)
		try await systemDataSession.logout()
		
		// Now we log in with the API key we just made.
		let apiKeySession = try await CheckPointManagement(
			url: TestData.url,
			apiKey: apiKey)
		try await apiKeySession.logout()
	}
	
	@Test func publishReadOnly() async throws {
		let connection = try await CheckPointManagement(
			url: TestData.url,
			username: TestData.username,
			password: TestData.password,
			readOnly: true)
		await #expect(throws: CPMError.writeCallInReadOnlySession) {
			try await connection.publish() }
		try await connection.logout()
	}
	
	@Test func pushPolicyReadOnly() async throws {
		let connection = try await CheckPointManagement(
			url: TestData.url,
			username: TestData.username,
			password: TestData.password,
			readOnly: true)
		await #expect(throws: CPMError.writeCallInReadOnlySession) {
			_ = try await connection.pushPolicy(
				TestData.uuidZero,
				to: [TestData.uuidZero],
				pushParameters: PolicyPushParameters(
					access: true,
					desktopSecurity: false,
					qos: false,
					threatPrevention: true,
					installOnAllClusterMembersOrFail: true,
					prepareOnly: false)) }
		try await connection.logout()
	}
}
