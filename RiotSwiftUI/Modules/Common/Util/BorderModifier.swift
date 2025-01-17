// 
// Copyright 2022 New Vector Ltd
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
struct BorderModifier<Shape: InsettableShape>: ViewModifier {
    
    var color: Color
    var borderWidth: CGFloat
    var shape: Shape
    
    func body(content: Content) -> some View {
        content
            .overlay(shape.stroke(color, lineWidth: borderWidth))
    }
}

@available(iOS 14.0, *)
extension View {
    func shapedBorder<Shape: InsettableShape>(color: Color, borderWidth: CGFloat, shape: Shape) -> some View {
        modifier(BorderModifier(color: color, borderWidth: borderWidth, shape: shape))
    }
}
