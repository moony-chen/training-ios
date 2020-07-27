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
import TrainingApiClient
import Common

struct AppState: Equatable {
  var upcomingCourses: UpcomingCoursesState = UpcomingCoursesState()
  var myRegisteredCourses: MyRegisteredCoursesState = MyRegisteredCoursesState(emid: "135")
  var tab: Tab = .myRegistered
}

enum Tab: Int, Equatable {
  case upcoming
  case myRegistered
}

enum AppAction {
  case upcomingCourses(UpcomingCoursesAction)
  case myRegisteredCourses(MyRegisteredCoursesAction)
  case tabChanged(Tab)
}

struct AppEnv {
  var api: TrainingApiClient
  var mainQueue: AnySchedulerOf<DispatchQueue>
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
  ).combined(with: Reducer<AppState, AppAction, AppEnv> {
    state, action, env in
    switch action {
    case .upcomingCourses(_):
      return .none
    case .myRegisteredCourses(_):
      return .none
    case let .tabChanged(tab):
      state.tab = tab
      return .none
    }
  })
)


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
          }.pickerStyle(SegmentedPickerStyle())
          
          self.courseView(tab: viewStore.tab)
          
        }
      }
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
          mainQueue: DispatchQueue.main.eraseToAnyScheduler()
        )
    ))
  }
}
