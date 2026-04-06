//
//  ParticleAPI.swift
//  GarageOSWatch
//
//  Created by David Washington.
//  Copyright © 2025 David Washington. All rights reserved.
//

import Foundation

actor ParticleAPI {
    static let shared = ParticleAPI()

    private let baseURL = "https://api.particle.io/v1"
    private let deviceID = Secrets.particleDeviceID

    // Credentials
    private let username = Secrets.particleUser
    private let password = Secrets.particlePassword

    private var accessToken: String?

    private let tokenKey = "particleAccessToken"

    init() {
        // Load cached token from UserDefaults (watchOS Keychain is fussy)
        accessToken = UserDefaults.standard.string(forKey: tokenKey)
    }

    // MARK: - Authentication

    func ensureAuthenticated() async throws {
        if let token = accessToken {
            // Verify token is still valid
            if await isTokenValid(token) {
                return
            }
        }
        // Need to login
        try await login()
    }

    private func login() async throws {
        let url = URL(string: "https://api.particle.io/oauth/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // Basic auth with particle:particle for personal dev accounts
        let credentials = "particle:particle"
        let base64 = Data(credentials.utf8).base64EncodedString()
        request.setValue("Basic \(base64)", forHTTPHeaderField: "Authorization")

        let body = "grant_type=password&username=\(urlEncode(username))&password=\(urlEncode(password))&expires_in=0"
        request.httpBody = body.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "unknown"
            print("Login failed: \(errorBody)")
            throw ParticleError.authenticationFailed
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        guard let token = json["access_token"] as? String else {
            throw ParticleError.authenticationFailed
        }

        accessToken = token
        UserDefaults.standard.set(token, forKey: tokenKey)
        print("Particle login successful, token cached")
    }

    private func isTokenValid(_ token: String) async -> Bool {
        guard let url = URL(string: "https://api.particle.io/v1/access_tokens/current") else { return false }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    // MARK: - Device Variables

    func getVariable(_ name: String) async throws -> Any? {
        try await ensureAuthenticated()
        guard let token = accessToken else { throw ParticleError.notAuthenticated }

        let url = URL(string: "\(baseURL)/devices/\(deviceID)/\(name)")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return nil
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        return json["result"]
    }

    func getDoorStatus() async -> (smallOpen: Bool, bigOpen: Bool) {
        do {
            async let door1 = getVariable("door1Status")
            async let door2 = getVariable("door2Status")

            let d1 = try await door1
            let d2 = try await door2

            // The Particle variable returns an int (1 = open, 0 = closed)
            let smallOpen = asBool(d1)
            let bigOpen = asBool(d2)

            return (smallOpen, bigOpen)
        } catch {
            print("Error getting door status: \(error)")
            return (false, false)
        }
    }

    // MARK: - Device Functions

    func toggleDoor(isDoor1: Bool) async throws {
        try await ensureAuthenticated()
        guard let token = accessToken else { throw ParticleError.notAuthenticated }

        let doorArg = isDoor1 ? "r2" : "r1"  // matches GarageClient convention

        let url = URL(string: "\(baseURL)/devices/\(deviceID)/toggleDoor")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "arg=\(doorArg)".data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "unknown"
            print("Toggle door failed: \(errorBody)")
            throw ParticleError.functionCallFailed
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        print("Toggle door response: \(json)")
    }

    // MARK: - Helpers

    private func asBool(_ value: Any?) -> Bool {
        if let intVal = value as? Int {
            return intVal != 0
        }
        if let boolVal = value as? Bool {
            return boolVal
        }
        if let strVal = value as? String {
            return strVal == "1" || strVal.lowercased() == "true"
        }
        return false
    }

    private func urlEncode(_ string: String) -> String {
        return string.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? string
    }
}

enum ParticleError: Error {
    case authenticationFailed
    case notAuthenticated
    case functionCallFailed
}
