// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import Combine

@available(iOS 14.0, *)
protocol AuthenticationServiceDelegate: AnyObject {
    func authenticationServiceDidUpdateRegistrationParameters(_ authenticationService: AuthenticationService)
}

enum AuthenticationError: Error {
    case encodingError
    case decodingError
}

@available(iOS 14.0, *)
class AuthenticationService: NSObject {
    
    static let shared = AuthenticationService()
    
    // MARK: - Properties
    
    // MARK: Private
    
    private var client: MXRestClient
    private var pendingData: AuthenticationPendingData?
    private var currentRegistrationWizard: RegistrationWizard?
    private var currentLoginWizard: LoginWizard?
    
    // MARK: Public
    
    weak var delegate: AuthenticationServiceDelegate?
    
    // MARK: - Setup
    
    override init() {
        guard let homeserverURL = URL(string: BuildSettings.serverConfigDefaultHomeserverUrlString) else {
            fatalError("[AuthenticationService]: Failed to create URL from default homeserver URL string.")
        }
        
        client = MXRestClient(homeServer: homeserverURL, unrecognizedCertificateHandler: nil)
        
        super.init()
    }
    
    /// Check if authentication is needed by looking checking for any accounts.
    /// - Returns: `true` there are no accounts or if there is an inactive account that has had a soft logout.
    var needsAuthentication: Bool {
        MXKAccountManager.shared().accounts.isEmpty || softLogoutCredentials != nil
    }
    
    var softLogoutCredentials: MXCredentials? {
        guard MXKAccountManager.shared().activeAccounts.isEmpty else { return nil }
        for account in MXKAccountManager.shared().accounts {
            if account.isSoftLogout {
                return account.mxCredentials
            }
        }
        
        return nil
    }
    
    enum AuthenticationError: Error {
        case invalidHomeserver
    }
    
    enum AuthenticationMode {
        case login
        case registration
    }
    
    /// Request the supported login flows for this homeserver.
    /// This is the first method to call to be able to get a wizard to login or to create an account
    /// - Parameter homeserverString: The homeserver string entered by the user.
    func loginFlow(for homeserverString: String) async throws -> [MXLoginFlow] {
        guard let baseURL = URL(string: homeserverString) else {
            MXLog.error("[AuthenticationService] loginFlow: Invalid homeserver base URL.")
            throw AuthenticationError.invalidHomeserver
        }
        
        client = MXRestClient(homeServer: baseURL, unrecognizedCertificateHandler: nil)
        pendingData = AuthenticationPendingData(homeserverString: homeserverString)
        
        if let wellKnown = try? await client.wellKnown() {
            pendingData?.homeserverWellKnown = wellKnown
        }
        
        return try await client.getLoginSession().flows
    }
    
    /// Request the supported login flows for the corresponding session.
    /// This method is used to get the flows for a server after a soft-logout.
    /// - Parameter session: The MXSession where a soft-logout has occurred.
    func loginFlow(for session: MXSession) async throws -> [MXLoginFlow] {
        return try await session.matrixRestClient.getLoginSession().flows
    }
    
//    /// Get a SSO url
//    func getSSOURL(redirectUrl: String, deviceId: String?, providerId: String?) -> String? {
//        
//    }
    
    /// Get the sign in or sign up fallback URL
    func fallbackURL(for authenticationMode: AuthenticationMode) -> URL {
        switch authenticationMode {
        case .login:
            return client.loginFallbackURL
        case .registration:
            return client.registerFallbackURL
        }
    }
    
    /// Return a LoginWizard, to login to the homeserver. The login flow has to be retrieved first.
    ///
    /// See ``LoginWizard`` for more details
    func loginWizard() -> LoginWizard {
        if let currentLoginWizard = currentLoginWizard {
            return currentLoginWizard
        }
        
        let wizard = LoginWizard()
        return wizard
    }
    
    /// Return a RegistrationWizard, to create a matrix account on the homeserver. The login flow has to be retrieved first.
    ///
    /// See ``RegistrationWizard`` for more details.
    func registrationWizard() -> RegistrationWizard {
        if let currentRegistrationWizard = currentRegistrationWizard {
            return currentRegistrationWizard
        }
        
        let wizard = RegistrationWizard(client: client, pendingData: pendingData)
        return wizard
    }
    
//    /// True when login and password has been sent with success to the homeserver
//    var isRegistrationStarted: Bool {
//        
//    }
//    
//    /// Cancel pending login or pending registration
//    func cancelPendingLoginOrRegistration() async {
//        
//    }
    
    /// Reset all pending settings, including current HomeServerConnectionConfig
    func reset() async {
        pendingData = nil
        currentRegistrationWizard = nil
        currentLoginWizard = nil
    }
    
//    /// Get the last authenticated [Session], if there is an active session.
//    /// - Returns: The last active session if any, or `nil`
//    func lastAuthenticatedSession() -> MXSession? {
//        
//    }
//
//    /// Create a session after a SSO successful login
//    func createSessionFromSso(homeServerConnectionConfig: HomeServerConnectionConfig,
//                              credentials: Credentials) async -> Session {
//        
//    }
//    
//    /// Perform a well-known request, using the domain from the matrixId
//    func getWellKnownData(matrixId: String,
//                          homeServerConnectionConfig: HomeServerConnectionConfig?) async -> WellknownResult {
//        
//    }
//
//    /// Authenticate with a matrixId and a password
//    /// Usually call this after a successful call to getWellKnownData()
//    /// - Parameter homeServerConnectionConfig the information about the homeserver and other configuration
//    /// - Parameter matrixId the matrixId of the user
//    /// - Parameter password the password of the account
//    /// - Parameter initialDeviceName the initial device name
//    /// - Parameter deviceId the device id, optional. If not provided or null, the server will generate one.
//    func directAuthentication(homeServerConnectionConfig: HomeServerConnectionConfig,
//                              matrixId: String,
//                              password: String,
//                              initialDeviceName: String,
//                              deviceId: String? = null) async -> Session {
//        
//    }
}
