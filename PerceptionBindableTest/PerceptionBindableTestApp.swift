//
//  PerceptionBindableTestApp.swift
//  PerceptionBindableTest
//
//  Created by Ben Williams on 1/30/25.
//

import ComposableArchitecture
import SwiftUI

@main
struct PerceptionBindableTestApp: App {
    @MainActor
    static let store: Store<Timers.State, Timers.Action> = {
        let store = Store(initialState: Timers.State()) {
            Timers()
        }

        return store
    }()

    var body: some Scene {
        WindowGroup {
            TimersView(store: Self.store)
        }
    }
}
