//
//  TimersView.swift
//  PerceptionBindableTest
//
//  Created by Ben Williams on 1/30/25.
//

import ComposableArchitecture
import SwiftUI

@Reducer
struct Timers {
    @ObservableState
    struct State: Equatable {
        var isTimerActive = false
        var secondsElapsed = 0
        var child = TimerChildFeature.State()
    }

    enum Action {
        case child(TimerChildFeature.Action)
        case onDisappear
        case timerTicked
        case toggleTimerButtonTapped
    }

    @Dependency(\.continuousClock) var clock
    private enum CancelID { case timer }

    var body: some Reducer<State, Action> {
        Scope(state: \.child, action: \.child) {
            TimerChildFeature()
        }
        Reduce { state, action in
            switch action {
            case .child:
                return .none
            case .onDisappear:
                return .cancel(id: CancelID.timer)

            case .timerTicked:
                state.secondsElapsed += 1
                return .none

            case .toggleTimerButtonTapped:
                state.isTimerActive.toggle()
                return .run { [isTimerActive = state.isTimerActive] send in
                    guard isTimerActive else { return }
                    for await _ in self.clock.timer(interval: .seconds(1)) {
                        await send(.timerTicked, animation: .interpolatingSpring(stiffness: 3000, damping: 40))
                    }
                }
                .cancellable(id: CancelID.timer, cancelInFlight: true)
            }
        }
    }
}

struct TimersView: View {
    var store: StoreOf<Timers>

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        WithPerceptionTracking {
            Form {
                Text("Time Elapsed: \(store.secondsElapsed)")
                TimerChildAView(store: store.scope(state: \.child, action: \.child))
                TimerChildBView(store: store.scope(state: \.child, action: \.child))
                ZStack {
                    Circle()
                        .fill(
                            AngularGradient(
                                gradient: Gradient(
                                    colors: [
                                        .blue.opacity(0.3),
                                        .blue,
                                        .blue,
                                        .green,
                                        .green,
                                        .yellow,
                                        .yellow,
                                        .red,
                                        .red,
                                        .purple,
                                        .purple,
                                        .purple.opacity(0.3),
                                    ]
                                ),
                                center: .center
                            )
                        )
                        .rotationEffect(.degrees(-90))
                    GeometryReader { proxy in
                        WithPerceptionTracking {
                            #if DEBUG
                            let _ = Self._printChanges()
                            #endif
                            Path { path in
                                path.move(to: CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2))
                                path.addLine(to: CGPoint(x: proxy.size.width / 2, y: 0))
                            }
                            .stroke(.primary, lineWidth: 3)
                            .rotationEffect(.degrees(Double(store.secondsElapsed) * 360 / 60))
                        }
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: 280)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)

                Button {
                    store.send(.toggleTimerButtonTapped)
                } label: {
                    Text(store.isTimerActive ? "Stop" : "Start")
                        .padding(8)
                }
                .frame(maxWidth: .infinity)
                .tint(store.isTimerActive ? Color.red : .accentColor)
                .buttonStyle(.borderedProminent)
            }
            .navigationTitle("Timers")
            .onDisappear {
                store.send(.onDisappear)
            }
        }
    }
}

@Reducer
struct TimerChildFeature {
    @ObservableState
    struct State: Equatable {
        var title: String = "Child Feature"
    }
}

struct TimerChildAView: View {
    var store: StoreOf<TimerChildFeature>

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        WithPerceptionTracking {
            Text(store.title)
        }
    }
}

struct TimerChildBView: View {
    @Perception.Bindable var store: StoreOf<TimerChildFeature>

    var body: some View {
        #if DEBUG
        let _ = Self._printChanges()
        #endif
        WithPerceptionTracking {
            Text(store.title)
        }
    }
}

#Preview {
    NavigationStack {
        TimersView(
            store: Store(initialState: Timers.State()) {
                Timers()
            }
        )
    }
}
