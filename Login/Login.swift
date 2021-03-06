
import SwiftUI
import ComposableArchitecture
import TrainingApiClient
import CasAuth
import Common


public struct LoginState: Equatable {
  var username: String = ""
  var password: String = ""
  public var loginedUser: User? = nil
  public var loginErrorAlert: AlertState<LoginAction>? = nil
  public var loginInFlight: Bool = false
  
  public init(loginedUser: User? = nil) {
    self.loginedUser = loginedUser
  }
}

public enum LoginAction: Equatable {
  case usernameChanged(username: String)
  case passwordChanged(password: String)
  case loginTapped
  case loginSuccess(authId: String, user: User)
  case loginFailure(AppError)
  case loginErrorAlertDismissTapped
}

public struct LoginEnv {
  public var api: TrainingApiClient
  public var mainQueue: AnySchedulerOf<DispatchQueue>
  public var casAuth: (_ username: String, _ password: String) -> Effect<String, CASError>
  
  public init(
    api: TrainingApiClient,
    mainQueue: AnySchedulerOf<DispatchQueue>,
    casAuth: @escaping (_ username: String, _ password: String) -> Effect<String, CASError>) {
    self.api = api
    self.mainQueue = mainQueue
    self.casAuth = casAuth
  }
}

public let loginReducer =
  Reducer<LoginState, LoginAction, LoginEnv> { state, action, environment in
        switch action {
      
        case .usernameChanged(username: let username):
          state.username = username
          return .none
        case .passwordChanged(password: let password):
          state.password = password
          return .none
        case .loginTapped:
          state.loginInFlight = true
          return environment.casAuth(state.username, state.password)
            .mapError { _ in AppError.casError }
            .map(LoginRequest.init)
            .flatMap { lr in environment.api.login(lr).mapError(AppError.apiError) }
            .receive(on: environment.mainQueue)
            .map { lr -> LoginAction in
              LoginAction.loginSuccess(authId: lr.authId, user: lr.emp)
          }.catch { err in
            Effect(value: LoginAction.loginFailure(err))
          }.eraseToEffect()
        case .loginSuccess(authId: let authId, user: let user):
          state.loginedUser = user
          state.loginInFlight = false
          return .none
        case .loginFailure(let error):
          state.loginInFlight = false
          state.loginErrorAlert = .init(
            title: "Login Failed!",
            message: "Please try again later",
            dismissButton: .default("OK", send: .loginErrorAlertDismissTapped)
          )
          return .none
        case .loginErrorAlertDismissTapped:
          state.loginErrorAlert = nil
          return .none
    }
      
}

public struct LoginView: View {
  let store: Store<LoginState, LoginAction>
  
  public init(store: Store<LoginState, LoginAction>) {
    self.store = store
  }
  
  public var body: some View {
    WithViewStore(self.store) { vs in
      VStack {
        TextField("username", text: vs.binding(
          get: { $0.username },
          send: LoginAction.usernameChanged
        ))
        SecureField("******", text: vs.binding(
          get: { $0.password },
          send: LoginAction.passwordChanged
          ))
        Button(action: {
          vs.send(.loginTapped)
        }) { Text("Login") }
          .disabled(vs.loginInFlight)
      }
      .alert(
        self.store.scope(state: { $0.loginErrorAlert }),
        dismiss: .loginErrorAlertDismissTapped
      )
    }
  }
}


struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    LoginView(
      store: Store(
        initialState: LoginState(),
        reducer: loginReducer.debug(),
        environment: LoginEnv(
          api: .mock(),
          mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
          casAuth: { (_, _) in
            Effect(value: "ST-1608-f1gUv2SjwwaSYp5kCDpX-eccb7f695a77")
          }
        )
    ))
  }
}
