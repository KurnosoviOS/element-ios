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

import SwiftUI
import Combine

@available(iOS 14, *)
typealias AuthenticationRegistrationViewModelType = StateStoreViewModel<AuthenticationRegistrationViewState,
                                                                 Never,
                                                                 AuthenticationRegistrationViewAction>


@available(iOS 14, *)
class AuthenticationRegistrationViewModel: AuthenticationRegistrationViewModelType, AuthenticationRegistrationViewModelProtocol {

    // MARK: - Properties

    // MARK: Private

    private let authenticationService: AuthenticationService

    // MARK: Public

    var completion: ((AuthenticationRegistrationViewModelResult) -> Void)?

    // MARK: - Setup

    init(authenticationService: AuthenticationService, defaultHomeserver: URL) {
        self.authenticationService = authenticationService
        let initialViewState = AuthenticationRegistrationViewState(defaultHomeserver: defaultHomeserver.host ?? "matrix.org",
                                                                   selectedServer: /*authenticationService.homeserverURL.host ??*/ "matrix.org",
                                                                   bindings: AuthenticationRegistrationBindings())
        super.init(initialViewState: initialViewState)
    }
    
    // MARK: - Public

    override func process(viewAction: AuthenticationRegistrationViewAction) {
        switch viewAction {
        case .editServer:
            completion?(.cancel)
        case .updateFlows:
            refreshServer()
        case .next:
            completion?(.done)
        }
    }
    
    // MARK: - Private
    
    private func refreshServer() {
        Task {
            let loginFlows = try await authenticationService.loginFlow(for: state.selectedServer)
            let wizard = authenticationService.registrationWizard()
            let registrationFlow = try await wizard.registrationFlow()
            
            switch registrationFlow {
            case .success(let mxSession):
                break
            case .flowResponse(let flowResult):
                print(flowResult)
            }
        }
    }
}
