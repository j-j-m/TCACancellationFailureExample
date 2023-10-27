//
//  ContentView.swift
//  TCACancellationFailureExample
//
//  Created by Jacob Martin on 10/26/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        DashboardScene.ContentView(
            store: .init(initialState: .init(), reducer: DashboardScene.init)
        )
    }
}

#Preview {
    ContentView()
}
