//
//  CPM Data Types.swift
//  CheckPointManagementConnection
//
//  Created by Bob Zimmerman on 2024-12-10.
//

import Foundation

public let CPMAPIErrorDomain: String = "CPMAPIErrorDomain"

public enum CPMError: Error {
	public static let unknownError = NSError(domain: CPMAPIErrorDomain, code: -1, userInfo: [
		NSLocalizedDescriptionKey: NSLocalizedString("Unknown Error", comment: "A connection error indicating something has gone wrong, but I don't yet handle it."), // swiftlint:disable:this line_length
		NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Something has gone wrong in a way I have never seen before and don't currently handle.", comment: "Informative text describing a connection error.") ]) // swiftlint:disable:this line_length
	public static let apiDown = NSError(domain: CPMAPIErrorDomain, code: -2, userInfo: [
		NSLocalizedDescriptionKey: NSLocalizedString("API Appears to be Down", comment: "A connection error indicating the server responded to our request, but that the response indicated the service has failed."), // swiftlint:disable:this line_length
		NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("It looks like we can reach the server, but the API service is down. Please check the API status.", comment: "Informative text describing a connection error.") ]) // swiftlint:disable:this line_length
	public static let badCredentials = NSError(domain: CPMAPIErrorDomain, code: -400, userInfo: [
		NSLocalizedDescriptionKey: NSLocalizedString("Access Denied", comment: "A connection error indicating the user could not authenticate."), // swiftlint:disable:this line_length
		NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("It looks like the server refused to accept the credentials you provided. Please try entering your credentials again.", comment: "Informative text describing a connection error.") ]) // swiftlint:disable:this line_length
	public static let connectionProhibited = NSError(domain: CPMAPIErrorDomain, code: -403, userInfo: [
		NSLocalizedDescriptionKey: NSLocalizedString("Permission Denied", comment: "A connection error indicating the user was able to authenticate, but does not have permission to use the API."), // swiftlint:disable:this line_length
		NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("It looks like the server accepted your credentials, but your user does not have permission to use the API. Please confirm your permissions on the server.", comment: "Informative text describing a connection error.") ]) // swiftlint:disable:this line_length
	public static let tooManyRequests = NSError(domain: CPMAPIErrorDomain, code: -3, userInfo: [
		NSLocalizedDescriptionKey: NSLocalizedString("Too Many Requests", comment: "A connection error indicating the user has tried to log in too many times in quick succession."), // swiftlint:disable:this line_length
		NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("You have hit the server's rate limit. Please wait a few minutes or use the command 'api throttling off' on the server to disable the rate limiting.", comment: "Informative text describing a connection error.") ]) // swiftlint:disable:this line_length
	public static let writeCallInReadOnlySession = NSError(domain: CPMAPIErrorDomain, code: -4, userInfo: [
		NSLocalizedDescriptionKey: NSLocalizedString("Write Call in a Read-Only Session", comment: "An error indicating the user has tried to write something, but they're using a read-only session."), // swiftlint:disable:this line_length
		NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("Your session is read-only, but you made a call to write something. Try again after connecting in write mode.", comment: "Informative text describing a session error.") ]) // swiftlint:disable:this line_length
	public static let invalidObject = NSError(domain: CPMAPIErrorDomain, code: -5, userInfo: [
		NSLocalizedDescriptionKey: NSLocalizedString("Call made to change an invalid object", comment: "An error indicating the user has tried to perform an action, but the object they tried to perform it on doesn't exist."), // swiftlint:disable:this line_length
		NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString("You made a call to perform an action with an object, but the object doesn't exist.", comment: "Informative text describing a session error.") ]) // swiftlint:disable:this line_length
}

public struct CPMDate: Codable, Sendable {
	public let iso8601: String
	public let posix: Date
	
	enum CodingKeys: String, CodingKey {
		case iso8601 = "iso-8601"
		case posix
	}
}

internal struct CPMLoginResponse: Codable, Identifiable, Sendable {
	let apiServerVersion: String
	let id: UUID?
	let lastLogin: Date?
	let readOnly: Bool?
	let sessionTimeout: Int
	let sid: String
	let url: URL
	let username: String?
	
	enum CodingKeys: String, CodingKey {
		case apiServerVersion = "api-server-version"
		case id = "uid"
		case lastLogin = "last-login-was-at"
		case readOnly = "read-only"
		case sessionTimeout = "session-timeout"
		case sid
		case url
		case username = "user-name"
	}
	
	init(from decoder: Decoder)
	throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		apiServerVersion = try values.decode(String.self, forKey: .apiServerVersion)
		id = try values.decodeIfPresent(UUID.self, forKey: .id)
		lastLogin = try values.decodeIfPresent(CPMDate.self, forKey: .lastLogin)?.posix
		readOnly = try values.decodeIfPresent(Bool.self, forKey: .readOnly)
		sessionTimeout = try values.decode(Int.self, forKey: .sessionTimeout)
		sid = try values.decode(String.self, forKey: .sid)
		url = try values.decode(URL.self, forKey: .url)
		username = try values.decodeIfPresent(String.self, forKey: .username)
	}
}

public struct PolicyPushParameters: Sendable {
	public let access: Bool
	public let desktopSecurity: Bool
	public let qos: Bool
	public let threatPrevention: Bool
	public let installOnAllClusterMembersOrFail: Bool
	public let prepareOnly: Bool
	
	public init(
		access: Bool,
		desktopSecurity: Bool,
		qos: Bool,
		threatPrevention: Bool,
		installOnAllClusterMembersOrFail: Bool,
		prepareOnly: Bool)
	{
		self.access = access
		self.desktopSecurity = desktopSecurity
		self.qos = qos
		self.threatPrevention = threatPrevention
		self.installOnAllClusterMembersOrFail = installOnAllClusterMembersOrFail
		self.prepareOnly = prepareOnly
	}
}
