//
//  ContentView.swift
//  training-ios-new
//
//  Created by Moony Chen on 2020/7/22.
//  Copyright © 2020 Moony Chen. All rights reserved.
//

import SwiftUI
import ComposableArchitecture
import UpcomingCourses
import MyRegistered
import MyAttended
import TrainingApiClient
import Common
import Login
import CasAuth

struct AppState: Equatable {
  var upcomingCourses: UpcomingCoursesState = UpcomingCoursesState()
  var myRegisteredCourses: MyRegisteredCoursesState = MyRegisteredCoursesState()
  var myAttendedCourses: MyAttendedCoursesState = MyAttendedCoursesState()
  var tab: Tab = .upcoming
  var loginState: LoginState = LoginState()
  
  var anonymous: User? {
    loginState.loginedUser == nil ? User(id: 0) : nil
  }
}

enum Tab: Int, Equatable {
  case upcoming
  case myRegistered
  case myAttended
}

enum AppAction {
  case upcomingCourses(UpcomingCoursesAction)
  case myRegisteredCourses(MyRegisteredCoursesAction)
  case myAttendedCourses(MyAttendedCoursesAction)
  case tabChanged(Tab)
  case dismissLogin
  case login(LoginAction)
}

struct AppEnv {
  var api: TrainingApiClient
  var mainQueue: AnySchedulerOf<DispatchQueue>
  var casAuth: PFTCasAuth
}

let appReducer : Reducer<AppState, AppAction, AppEnv> = Reducer.combine(
  upcomingCoursesReducer.debug()
    .pullback(
      state: \.upcomingCourses,
      action: /AppAction.upcomingCourses,
      environment: { UpcomingCoursesEnv(api: $0.api, mainQueue: $0.mainQueue) }
  ),
  myRegisteredCoursesReducer.debug()
    .pullback(
      state: \.myRegisteredCourses,
      action: /AppAction.myRegisteredCourses,
      environment: { MyRegisteredCoursesEnv(api: $0.api, mainQueue: $0.mainQueue) }
  ),
  myAttendedCoursesReducer.debug()
    .pullback(
      state: \.myAttendedCourses,
      action: /AppAction.myAttendedCourses,
      environment: { MyAttendedCoursesEnv(api: $0.api, mainQueue: $0.mainQueue) }
  ),
  loginReducer.debug()
    .pullback(
      state: \.loginState,
      action: /AppAction.login,
      environment: { env in LoginEnv(api: env.api,
                              mainQueue: env.mainQueue,
                              casAuth: { u, p in env.casAuth.getServiceTicket(u, p, .training).map { (g, s) in s}.eraseToEffect()  }) }
      )
  )
  .combined(with: Reducer<AppState, AppAction, AppEnv> {
    state, action, env in
    switch action {
    case .upcomingCourses(_),
         .myRegisteredCourses(_),
         .myAttendedCourses(_):
      return .none
    case .login(.loginSuccess(_, let user)):
      state.myRegisteredCourses.emid = "\(user.id)"
      state.myAttendedCourses.emid = "\(user.id)"
      return .none
    case .login(_):
      return .none
    case let .tabChanged(tab):
      state.tab = tab
      return .none
    case .dismissLogin:
      return .none
    }
  })



struct ContentView: View {
  let store: Store<AppState, AppAction>
  
  var body: some View {
    WithViewStore(self.store) { viewStore in
      NavigationView {
        VStack {
          Picker(selection: viewStore.binding(
            get: { $0.tab },
            send: AppAction.tabChanged
          ), label: Text("")) {
            Text("Upcoming").tag(Tab.upcoming)
            Text("Registered").tag(Tab.myRegistered)
            Text("Attended").tag(Tab.myAttended)
          }.pickerStyle(SegmentedPickerStyle())
          
          self.courseView(tab: viewStore.tab)
          
        }
      }
      .sheet(item: viewStore.binding(
        get: { $0.anonymous },
      send: AppAction.dismissLogin
        ), content: { _ in
          LoginView(store:
            self.store.scope(
            state: { $0.loginState },
            action: AppAction.login)) }
      )
    }
    
    
  }
  
  
  func courseView(tab: Tab) -> AnyView {
    switch tab {
    case .upcoming:
      return AnyView(UpcomingCoursesView(
        store: self.store.scope(
          state: { $0.upcomingCourses },
          action: AppAction.upcomingCourses)
      ))
    case .myRegistered:
      return AnyView(MyRegisteredCoursesView(
        store: self.store.scope(
          state: { $0.myRegisteredCourses },
          action: AppAction.myRegisteredCourses)
      ))
    case .myAttended:
      return AnyView(MyAttendedCoursesView(
        store: self.store.scope(
          state: { $0.myAttendedCourses },
          action: AppAction.myAttendedCourses)
      ))
      
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView(
      store: Store(
        initialState: AppState(),
        reducer: appReducer,
        environment: AppEnv(
          api: .mock(),
          mainQueue: DispatchQueue.main.eraseToAnyScheduler(),
          casAuth: .mock()
        )
    ))
  }
}
