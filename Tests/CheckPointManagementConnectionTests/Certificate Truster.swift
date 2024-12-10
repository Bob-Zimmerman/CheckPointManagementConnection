//
//  Certificate Truster.swift
//  CheckPointManagementConnection
//
//  Created by Bob Zimmerman on 2024-12-10.
//
// This "test" adds a certificate to the Keychain and trusts it for the domain
// name defined in 'TestData.url'. If needed, the system will prompt you for
// your password to add the certificate to the keychain. This isn't a test of
// the functional code in the package, but it makes it easier for the other
// tests to work.

import Foundation
import Testing

@Suite(.serialized, .tags(.serverRequired)) struct CertificateTruster {
	@Test func certificateTruster() async throws {
		do {
			let session = URLSession(configuration: URLSessionConfiguration.default)
			let request = NSMutableURLRequest(url: TestData.url)
			_ = try await session.data(for: request as URLRequest)
		} catch let error as NSError {
			guard error.domain == NSURLErrorDomain,
				  error.code == -1202 // This is the error for untrusted certificates.
			else { try #require(Bool(false), "Unexpected error: \(error)"); return }
			guard let serverCertificate = (error.userInfo["NSErrorPeerCertificateChainKey"] as? [SecCertificate])?[0]
			else { try #require(Bool(false), "Couldn't extract the certificate."); return }
			try addTrustForCertificate(serverCertificate, host: TestData.url.host!)
		}
	}
	
	func addTrustForCertificate(
		_ serverCertificate: SecCertificate,
		host: String)
	throws {
		let serverCertDictionary: CFDictionary = [
			kSecClass: kSecClassCertificate,
			kSecValueRef: serverCertificate
		] as [CFString: Any] as CFDictionary
		let secItemAddError = SecItemAdd(serverCertDictionary, nil)
		switch secItemAddError {
		case noErr:
			break
		default:
			let errorString = SecCopyErrorMessageString(secItemAddError, nil)
			try #require(Bool(false), "ERROR: addTrustForCertificate SecItemAdd returned: \(String(describing: errorString))")
		}
		
		let secPolicyToSet = SecPolicyCreateSSL(true, nil)
		let secTrustDict1: CFDictionary = [
			kSecTrustSettingsAllowedError: CSSMERR_TP_CERT_EXPIRED,
			kSecTrustSettingsPolicy: secPolicyToSet,
			"kSecTrustSettingsPolicyName": "sslServer",
			kSecTrustSettingsPolicyString: host,
			kSecTrustSettingsResult: 1
		] as [CFString: Any] as CFDictionary
		let secTrustDict2: CFDictionary = [
			kSecTrustSettingsAllowedError: CSSMERR_APPLETP_HOSTNAME_MISMATCH,
			kSecTrustSettingsPolicy: secPolicyToSet,
			"kSecTrustSettingsPolicyName": "sslServer",
			kSecTrustSettingsPolicyString: host,
			kSecTrustSettingsResult: 1
		] as [CFString: Any] as CFDictionary
		let trustSettings: CFArray = [secTrustDict1, secTrustDict2] as CFArray
		let trustSettingsError = SecTrustSettingsSetTrustSettings(serverCertificate, .user, trustSettings)
		switch trustSettingsError {
		case noErr:
			break
		default:
			let errorString = SecCopyErrorMessageString(trustSettingsError, nil)
			try #require(Bool(false), "ERROR: addTrustForCertificate SecTrustSettingsSetTrustSettings returned: \(String(describing: errorString))")
		}
	}
}
