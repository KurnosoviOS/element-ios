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

// MARK: - Coordinator

enum AuthenticationRegistrationPresence {
    case online
    case idle
    case offline
}

extension AuthenticationRegistrationPresence: Identifiable, CaseIterable {
    var id: Self { self }
    
    var title: String {
        switch self {
        case .online:
            return VectorL10n.roomParticipantsOnline
        case .idle:
            return VectorL10n.roomParticipantsIdle
        case .offline:
            return VectorL10n.roomParticipantsOffline
        }
    }
}

// MARK: View model

enum AuthenticationRegistrationViewModelResult {
    case cancel
    case done
}

// MARK: View

struct AuthenticationRegistrationViewState: BindableState {
    var defaultHomeserver: String
    var selectedServer: String
    var bindings: AuthenticationRegistrationBindings
    
    var serverDescription: String? {
        guard selectedServer == defaultHomeserver else { return nil }
        return VectorL10n.onboardingRegistrationMatrixDescription
    }
}

struct AuthenticationRegistrationBindings: BindableState {
    var username = ""
    var password = ""
}

enum AuthenticationRegistrationViewAction {
    case updateFlows
    case editServer
    case next
}
