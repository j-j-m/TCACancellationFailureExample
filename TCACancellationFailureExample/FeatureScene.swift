import SwiftUI
import ComposableArchitecture

struct FeatureScene: Reducer {

    enum Mode: Equatable {

        enum ShutdownRoute: Equatable {
            case exited
            case inactivity
        }

        case initial
        case connecting
        case normal
        case leaving
        case shutdown(route: ShutdownRoute)
    }

    struct State: Equatable {
        @BindingState var mode: Mode = .initial
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case onTask
    }

    enum CancellableID {
        case networkTimeout
    }

    @Dependency(\.continuousClock) var clock

    var body: some Reducer<State, Action> {

        BindingReducer()

        Reduce { state, action in
            switch action {

            case .onTask:
                return .run { send in
                    try await clock.sleep(for: .seconds(10))
                    await send(.binding(.set(\.$mode, .leaving)), animation: .easeInOut)
                    try await clock.sleep(for: .seconds(1))
                    await send(.binding(.set(\.$mode, .shutdown(route: .inactivity))))
                }
                .cancellable(id: CancellableID.networkTimeout, cancelInFlight: true)

            default:
                return .none
            }
        }
    }
}

extension FeatureScene {

    private struct ViewState: Equatable {
        let mode: Mode

        init(state: State) {
            self.mode = state.mode
        }
    }

    struct ContentView: View {

        @Environment(\.dismiss) var dismiss

        let store: StoreOf<FeatureScene>

        var body: some View {
            WithViewStore(store, observe: ViewState.init(state:)) { viewStore in
                ZStack {
                    VStack(spacing: 20) {
                        Group {
                            switch viewStore.mode {
                            case .initial:
                                Text("Wait 10 Seconds")
                                ProgressView()

                            case .connecting:
                                Text("Connecting")
                                ProgressView()

                            case .normal:
                                EmptyView()

                            case .leaving:
                                ProgressView()

                            case .shutdown:
                                EmptyView()
                            }
                        }
                        .transition(.opacity)
                        .bold()
                        .tint(Color.white)
                        .shadow(color: .black, radius: 2, y: 2)
                        .controlSize(.large)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationBarBackButtonHidden()
                .task {
                    await store.send(.onTask).finish()
                }
                .onChange(of: viewStore.mode) { newValue in
                    if case .shutdown = newValue {
                        dismiss()
                    }
                }
            }
        }
    }
}
