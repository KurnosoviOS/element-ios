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

//@available(iOS 14.0, *)
//class MockAuthenticationService: AuthenticationServiceProtocol {
//    var presenceSubject: CurrentValueSubject<AuthenticationRegistrationPresence, Never>
//    
//    let homeserverURL: URL
//    let userId: String
//    let displayName: String?
//    let avatarUrl: String?
//    init(
//        homeserverURL: URL = URL(string: "https://matrix.org/")!,
//        userId: String = "@alice:matrix.org",
//        displayName:  String? = "Alice",
//        avatarUrl: String? = "mxc://matrix.org/VyNYAgahaiAzUoOeZETtQ",
//        presence: AuthenticationRegistrationPresence = .offline
//    ) {
//        self.homeserverURL = homeserverURL
//        self.userId = userId
//        self.displayName = displayName
//        self.avatarUrl = avatarUrl
//        self.presenceSubject = CurrentValueSubject<AuthenticationRegistrationPresence, Never>(presence)
//    }
//    
//    func simulateUpdate(presence: AuthenticationRegistrationPresence) {
//        self.presenceSubject.value = presence
//    }
//}
