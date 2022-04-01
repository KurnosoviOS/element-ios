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

@available(iOS 14.0, *)
struct AuthenticationRegistrationCoordinatorParameters {
    let authenticationService: AuthenticationService
}

enum AuthenticationRegistrationCoordinatorResult {
    case selectServer
}

@available(iOS 14.0, *)
final class AuthenticationRegistrationCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: AuthenticationRegistrationCoordinatorParameters
    private let authenticationRegistrationHostingController: VectorHostingController
    private var authenticationRegistrationViewModel: AuthenticationRegistrationViewModelProtocol
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((AuthenticationRegistrationCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: AuthenticationRegistrationCoordinatorParameters) {
        self.parameters = parameters
        #warning("parameters.authenticationService.homeserverURL is not the default homeserverURL")
        let viewModel = AuthenticationRegistrationViewModel(authenticationService: parameters.authenticationService,
                                                            defaultHomeserver: URL(string: "https://matrix.org")!)
        let view = AuthenticationRegistrationScreen(viewModel: viewModel.context)
        authenticationRegistrationViewModel = viewModel
        authenticationRegistrationHostingController = VectorHostingController(rootView: view)
        authenticationRegistrationHostingController.vc_removeBackTitle()
        authenticationRegistrationHostingController.enableNavigationBarScrollEdgeAppearance = true
    }
    
    // MARK: - Public
    func start() {
        MXLog.debug("[AuthenticationRegistrationCoordinator] did start.")
        authenticationRegistrationViewModel.completion = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[AuthenticationRegistrationCoordinator] AuthenticationRegistrationViewModel did complete with result: \(result).")
            switch result {
            case .cancel, .done:
                self.completion?(.selectServer)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.authenticationRegistrationHostingController
    }
}
