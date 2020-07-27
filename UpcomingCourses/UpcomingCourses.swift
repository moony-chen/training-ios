
import SwiftUI
import ComposableArchitecture
import TrainingApiClient
import Common

public struct UpcomingCoursesState: Equatable {
  public var upcomingCourses: [Course]?
  public var isRefreshingCoures = false
  public var refreshError: TrainingApiClient.ApiError? = nil
  
  public init() {}
}

public enum UpcomingCoursesAction {
  case course(id: Int, action: Void)
  case refreshCourseRequest
  case refreshCourseResponse(Result<[Course], TrainingApiClient.ApiError>)
}

public struct UpcomingCoursesEnv {
  public var api: TrainingApiClient
  public var mainQueue: AnySchedulerOf<DispatchQueue>
  
  public init(api: TrainingApiClient, mainQueue: AnySchedulerOf<DispatchQueue>) {
    self.api = api
    self.mainQueue = mainQueue
  }
}

public let upcomingCoursesReducer =
  Reducer<Course, Void, UpcomingCoursesEnv>.empty
    .forEach(
      state: \.self,
      action: /.self,
      environment: { $0 })
    .optional
    .pullback(
      state: \UpcomingCoursesState.upcomingCourses,
      action: /UpcomingCoursesAction.course(id:action:),
      environment: { $0 }
  )
    .combined(with:
      Reducer<UpcomingCoursesState, UpcomingCoursesAction, UpcomingCoursesEnv> { state, action, environment in
        switch action {
        case .course(id: let id, action: let action):
          return .none
        case .refreshCourseRequest:
          state.isRefreshingCoures = true
          return environment.api.getUpcomingCourses()
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .map(UpcomingCoursesAction.refreshCourseResponse)
        case let .refreshCourseResponse(result):
          state.isRefreshingCoures = false
          switch result {
          case .success(let courses):
            state.upcomingCourses = courses
            return .none
          case .failure(let error):
            state.refreshError = error
            return .none
          }
        }
      }
      
)

public struct UpcomingCourseView: View {
  let store: Store<Course, Void>
  
  public var body: some View {
    WithViewStore(self.store) { course in
      Text(course.topicName)
    }
  }
}


public struct UpcomingCoursesView: View {
  let store: Store<UpcomingCoursesState, UpcomingCoursesAction>
  
  public var body: some View {
    WithViewStore(self.store) { viewStore in
      
      IfLetStore(
        self.store.scope(
          state: { $0.upcomingCourses }),
        then: { store in
          List {
            ForEachStore(
              self.store.scope(state: { $0.upcomingCourses! }, action: UpcomingCoursesAction.course(id:action:)),
              content: UpcomingCourseView.init(store:)
            )
          }
      },
        else: ActivityIndicator()
          .frame(maxHeight: .infinity)
          .onAppear {
          viewStore.send(UpcomingCoursesAction.refreshCourseRequest)
        }
      )
      
      
    }.navigationBarTitle("Upcoming Courses")
  }
  
  public init(store: Store<UpcomingCoursesState, UpcomingCoursesAction>) {
    self.store = store
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    UpcomingCoursesView(
      store: Store(
        initialState: UpcomingCoursesState(),
        reducer: upcomingCoursesReducer,
        environment: UpcomingCoursesEnv(
          api: .mock(),
          mainQueue: DispatchQueue.main.eraseToAnyScheduler()
        )
    ))
  }
}
