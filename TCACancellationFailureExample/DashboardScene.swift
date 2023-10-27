import SwiftUI
import ComposableArchitecture

// MARK: - Domain
struct DashboardScene: Reducer {

    struct Path: Reducer {
        enum State: Equatable {
            case feature(FeatureScene.State)
        }

        enum Action: Equatable {
            case feature(FeatureScene.Action)
        }

        var body: some Reducer<State, Action> {

            EmptyReducer()
                .ifCaseLet(/State.feature, action: /Action.feature) {
                    FeatureScene()
                }
        }
    }

    struct State: Equatable {

        var stack = StackState<Path.State>()
        @PresentationState var alert: AlertState<Action.Alert>?

        @BindingState var showInactivityModal: Bool = false

        var root = RootScene.State()
    }

    enum Action: Equatable, BindableAction {
        case onTask
        case binding(BindingAction<State>)

        case stack(StackAction<Path.State, Path.Action>)
        case alert(PresentationAction<Alert>)

        case root(RootScene.Action)

        case showAlert

        enum Alert: Equatable {
            case tappedLogOut
        }
    }

    @Dependency(\.continuousClock) var clock

    var body: some ReducerOf<Self> {

        BindingReducer()

        Reduce { state, action in
            switch action {
            case .onTask:
                return .none

            case .alert(.presented(.tappedLogOut)):
                return .none

            case .stack(.element(id: _, action: .feature(.set(\.$mode, .shutdown(route: .inactivity))))):
                return .run { send in
                    do {
                        try await clock.sleep(for: .seconds(2))
                        await send(.showAlert) // should get hit but it doesnt
                    } catch {
                        print(error)
                    }
                }

            case .showAlert:
                state.alert = AlertState {
                    TextState("Alert")
                  } actions: {
                    ButtonState(role: .cancel) {
                      TextState("Cancel")
                    }
                    ButtonState(action: .tappedLogOut) {
                      TextState("Log Out")
                    }
                  } message: {
                    TextState("Okay Bye!")
                  }
                return .none

            default:
                return .none
            }
        }
        .forEach(\.stack, action: /Action.stack) {
            Path()
        }
        .ifLet(\.$alert, action: /Action.alert)

        Scope(state: \.root, action: /Action.root) {
            RootScene()
        }
    }
}

// MARK: - View
extension DashboardScene {

    struct ContentView: View {

        let store: StoreOf<DashboardScene>

        var body: some View {
            NavigationStackStore(
                store.scope(state: \.stack, action: Action.stack)
            ) {
                WithViewStore(store, observe: { $0 }) { viewStore in
                    RootScene.ContentView(
                        store: store.scope(state: \.root, action: Action.root)
                    )
                    .navigationBarBackButtonHidden()
                }
                .alert(
                  store: self.store.scope(
                    state: \.$alert,
                    action: { .alert($0) }
                  )
                )
                .task {
                    await store.send(.onTask).finish()
                }
            } destination: {
                switch $0 {
                case .feature:
                    CaseLet(
                        /Path.State.feature,
                         action: Path.Action.feature,
                         then: {
                             FeatureScene.ContentView.init(store: $0)
                         }
                    )
                }
            }
        }
    }
}
