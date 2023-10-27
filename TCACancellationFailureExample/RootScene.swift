import SwiftUI
import ComposableArchitecture

struct RootScene: Reducer {

    struct State: Equatable {
        @BindingState var presentRootPopover: Bool = false
    }

    enum Action: Equatable, BindableAction {
        case binding(BindingAction<State>)
        case onTask

        case tappedShowFeature
    }

    enum CancellableID: Hashable {
        case getRooms
        case networkPopover
    }

    @Dependency(\.continuousClock) var clock

    var body: some Reducer<State, Action> {

        BindingReducer()

        Reduce { state, action in
            switch action {
            case .onTask:
                return .none
                // what I thought the issue was...
//                return .run { send in
//                    try await clock.sleep(for: .seconds(2)) //
//                    await send(.binding(.set(\.$presentRootPopover, true)))
//                }
//                .cancellable(id: CancellableID.networkPopover, cancelInFlight: true)

            default:
                return .none
            }
        }

    }
}

extension RootScene {
    struct ContentView: View {

        let store: StoreOf<RootScene>

        var body: some View {
            WithViewStore(store, observe: { $0 }) { viewStore in
                VStack {
                    NavigationLink(
                        state: DashboardScene.Path.State.feature(.init())
                    ) {
                        Text("Go to Feature")
                    }
                }
            }
            .task {
                await store.send(.onTask).finish()
            }
        }
    }
}
