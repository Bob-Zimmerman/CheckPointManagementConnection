//
//  Management Actions.swift
//  CheckPointManagementConnection
//
//  Created by Bob Zimmerman on 2024-12-10.
//

import Foundation

extension CheckPointManagement {
	static internal func getTaskId(_ returnedData: Data)
	throws -> UUID? {
		let decoded = try JSONSerialization.jsonObject(with: returnedData) as? [String: Sendable] ?? [:]
		return UUID(uuidString: decoded["task-id"] as? String ?? "")
	}
	
	static internal func getFirstTask(_ returnedData: Data)
	throws -> [String: Sendable]? {
		let decodedDict = try JSONSerialization.jsonObject(with: returnedData) as? [String: Sendable]
		return(decodedDict?["tasks"] as? [[String: Sendable]])?.first
	}
	
	static internal func getTaskStatus(_ task: [String: Sendable]?)
	-> String {
		task?["status"] as? String ?? "in progress"
	}
	
	/// Waits for a task to reach a terminal state, then returns the task results.
	///
	/// - Parameters:
	///   - taskId: UUID of the task to check.
	///   - checkInterval: How many seconds to wait before checking again.
	///   - maxDuration: The maximum number of seconds to wait for the task to finish.
	///
	/// - Returns: A dictionary of the task's results, or nil if the task still hasn't finished.
	internal func syncTask(
		_ taskId: UUID,
		checkInterval: Int = 5,
		maxDuration: Int = 600)
	async throws -> [String: Sendable]? {
		var counter: Int = maxDuration
		var decoded: [String: Sendable]?
		repeat {
			counter -= checkInterval
			try? await Task.sleep(nanoseconds: UInt64(checkInterval) * 1_000_000_000)
			let returnedData = try await makeRawApiCall(apiPoint: "/show-task",
														requestBody: ["task-id": taskId.uuidString.lowercased()])
			decoded = try CheckPointManagement.getFirstTask(returnedData)
		} while (counter > 0 && CheckPointManagement.getTaskStatus(decoded) == "in progress")
		return decoded
	}
	
	/// Publish the changes staged during a session.
	///
	/// While Check Point's API documentation says you can provide a UUID of a session to publish, that
	/// option does not actually work in any API version through 2.0.
	public func publish()
	async throws -> UUID? {
		guard !self.readOnly else {
			CheckPointManagement.logger.error("ERROR: publish called, but session is read-only!")
			throw CPMError.writeCallInReadOnlySession }
		let apiPoint = "/publish"
		let returnedData = try await makeRawApiCall(apiPoint: apiPoint, requestBody: [:])
		return try CheckPointManagement.getTaskId(returnedData)
	}
	
	/// Discard the changes staged during a session.
	///
	/// - Parameters:
	///   - sessionUUID: The UUID of the session you want to discard. If not specified, the current
	///   session will be discarded (but will remain valid for later changes).
	public func discard(sessionUUID: UUID? = nil) async throws {
		guard !self.readOnly else {
			CheckPointManagement.logger.error("ERROR: discard called, but session is read-only!")
			throw CPMError.writeCallInReadOnlySession }
		let apiPoint = "/discard"
		let requestBody: [String: Sendable]
		if let sessionUUID { requestBody = ["uid": sessionUUID.uuidString.lowercased()] } else { requestBody = [:] }
		_ = try await makeRawApiCall(apiPoint: apiPoint, requestBody: requestBody)
	}
	
	/// Push a policy package to one or more firewalls.
	///
	/// - Parameters:
	///   - policyToPush: The UUID of the policy package you want to push.
	///   - targets: A list of UUIDs of the firewalls you want to push the policy to. For a cluster, you
	///   specify just the cluster's UUID, and leave the members out.
	///   - pushParameters: An object with parameters for the push, such as which policies from the
	///   package you want to push.
	///
	/// - Returns: A UUID for the task object to check status later.
	public func pushPolicy(
		_ policyToPush: UUID,
		to targets: [UUID],
		pushParameters: PolicyPushParameters)
	async throws -> UUID? {
		guard !self.readOnly else {
			CheckPointManagement.logger.error("ERROR: pushPolicy called, but session is read-only!")
			throw CPMError.writeCallInReadOnlySession }
		let apiPoint: String = "/install-policy"
		let requestBody: [String: Sendable] = [
			"policy-package": policyToPush.uuidString.lowercased(),
			"targets": targets.map { $0.uuidString.lowercased() },
			"access": pushParameters.access,
			"desktop-security": pushParameters.desktopSecurity,
			"qos": pushParameters.qos,
			"threat-prevention": pushParameters.threatPrevention,
			"install-on-all-cluster-members-or-fail": pushParameters.installOnAllClusterMembersOrFail,
			"prepare-only": pushParameters.prepareOnly
		]
		let returnedData = try await makeRawApiCall(apiPoint: apiPoint, requestBody: requestBody)
		return try CheckPointManagement.getTaskId(returnedData)
	}
}
