
import SwiftUI
import ComposableArchitecture
import TrainingApiClient
import Common

public struct MyRegisteredCoursesState: Equatable {
  public var myRegisteredCourses: [Course]?
  public var isRefreshingCoures = false
  public var refreshError: TrainingApiClient.ApiError? = nil
  public var emid: String?
  
  public init(
  myRegisteredCourses: [Course]? = nil,
  isRefreshingCoures: Bool = false,
  refreshError: TrainingApiClient.ApiError? = nil,
  emid: String? = nil
  ) {
    self.myRegisteredCourses = myRegisteredCourses
    self.isRefreshingCoures = isRefreshingCoures
    self.refreshError = refreshError
    self.emid = emid
  }
  
}

public enum MyRegisteredCoursesAction {
  case course(id: Int, action: Void)
  case refreshCourseRequest
  case refreshCourseResponse(Result<[Course], TrainingApiClient.ApiError>)
}

public struct MyRegisteredCoursesEnv {
  public var api: TrainingApiClient
  public var mainQueue: AnySchedulerOf<DispatchQueue>
  
  public init(api: TrainingApiClient, mainQueue: AnySchedulerOf<DispatchQueue>) {
    self.api = api
    self.mainQueue = mainQueue
  }
}

public let myRegisteredCoursesReducer =
  
  Reducer<Course, Void, MyRegisteredCoursesEnv>.empty
    .forEach(
      state: \.self,
      action: /.self,
      environment: { $0 })
    .optional
    .pullback(
      state: \MyRegisteredCoursesState.myRegisteredCourses,
      action: /MyRegisteredCoursesAction.course(id:action:),
      environment: { $0 }
  )
    .combined(with:
      
      Reducer<MyRegisteredCoursesState, MyRegisteredCoursesAction, MyRegisteredCoursesEnv> { state, action, environment in
        switch action {
          
        case .refreshCourseRequest:
          state.isRefreshingCoures = true
          return environment.api.getMyRegisteredCourses(state.emid!)
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .map(MyRegisteredCoursesAction.refreshCourseResponse)
        case let .refreshCourseResponse(result):
          state.isRefreshingCoures = false
          switch result {
          case .success(let courses):
            state.myRegisteredCourses = courses
            return .none
          case .failure(let error):
            state.refreshError = error
            return .none
          }
        case .course(id: let id, action: let action):
          return .none
        }
      }
)


public struct MyRegisteredCourseView: View {
  let store: Store<Course, Void>
  
  public var body: some View {
    WithViewStore(self.store) { course in
      Text(course.topicName)
    }
  }
}


public struct MyRegisteredCoursesView: View {
  public let store: Store<MyRegisteredCoursesState, MyRegisteredCoursesAction>
  
  public var body: some View {
    WithViewStore(self.store) { viewStore in
      
      IfLetStore(
        self.store.scope(
          state: { $0.myRegisteredCourses }),
        then: { store in
          List {
            ForEachStore(
              self.store.scope(state: { $0.myRegisteredCourses! }, action: MyRegisteredCoursesAction.course(id:action:)),
              content: MyRegisteredCourseView.init(store:)
            )
          }
      },
        else: ActivityIndicator()
          .frame(maxHeight: .infinity)
          .onAppear {
          viewStore.send(MyRegisteredCoursesAction.refreshCourseRequest)
        }
      )
      
      
    }.navigationBarTitle("Registered Courses")
  }
  
  public init(store: Store<MyRegisteredCoursesState, MyRegisteredCoursesAction>) {
    self.store = store
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    MyRegisteredCoursesView(
      store: Store(
        initialState: MyRegisteredCoursesState(emid: "0"),
        reducer: myRegisteredCoursesReducer,
        environment: MyRegisteredCoursesEnv(
          api: .mock(),
          mainQueue: DispatchQueue.main.eraseToAnyScheduler()
        )
    ))
  }
}
