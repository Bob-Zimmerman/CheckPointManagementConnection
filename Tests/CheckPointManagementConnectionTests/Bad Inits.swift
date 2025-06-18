//
//  Bad Inits.swift
//  CheckPointManagementConnection
//
//  Created by Bob Zimmerman on 2024-12-10.
//

import Foundation
import Testing
@testable import CheckPointManagementConnection

@Suite(.serialized, .tags(.serverRequired)) struct BadInits {
	@Test func badApiKey() async {
		await #expect(throws: CPMError.badCredentials) { _ = try await CheckPointManagement(
			url: TestData.url,
			apiKey: TestData.badPassword,
			readOnly: false) }
	}
	
	@Test func badDomain() async {
		await #expect(throws: CPMError.badCredentials) { _ = try await CheckPointManagement(
			url: TestData.url,
			domain: TestData.badDomain,
			username: TestData.username,
			password: TestData.password,
			readOnly: false) }
	}
	
	@Test func badPassword() async {
		await #expect(throws: CPMError.badCredentials) { _ = try await CheckPointManagement(
			url: TestData.url,
			username: TestData.username,
			password: TestData.badPassword,
			readOnly: false) }
	}
	
	@Test func badUsername() async {
		await #expect(throws: CPMError.badCredentials) { _ = try await CheckPointManagement(
			url: TestData.url,
			username: TestData.badUsername,
			password: TestData.password,
			readOnly: false) }
	}
	
	@Test func noApi() async {
		await #expect(throws: CPMError.connectionProhibited) { _ = try await CheckPointManagement(
			url: TestData.url,
			username: TestData.noApiUser,
			password: TestData.password,
			readOnly: false) }
	}
}

extension UnitTests {
	@Test func badRawInit() async {
		await #expect(throws: CPMError.badCredentials) { _ = try await CheckPointManagement(
			serverUrl: TestData.url,
			loginBody: [:]) }
	}
	
	@Test func noAuthentication() async {
		await #expect(throws: CPMError.badCredentials) { _ = try await CheckPointManagement(
			serverUrl: TestData.url,
			loginBody: ["user": TestData.username,
						"read-only": true]) }
	}
	
	@Test func nonHttpResponse() async {
		await #expect { _ = try await CheckPointManagement(
			serverUrl: TestData.badUrl,
			loginBody: ["user": TestData.username,
						"password": TestData.password,
						"read-only": true])
		} throws: { (error) in
			let error = error as NSError
			try #require((NSCocoaErrorDomain, 4864) == (error.domain, error.code))
			return true
		}
	}
}
