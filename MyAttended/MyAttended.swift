
import SwiftUI
import ComposableArchitecture
import TrainingApiClient
import Common

public struct MyAttendedCoursesState: Equatable {
  public var myAttendedCourses: [Course]?
  public var isRefreshingCoures = false
  public var refreshError: TrainingApiClient.ApiError? = nil
  public var emid: String?
  
  public init(
  myAttendedCourses: [Course]? = nil,
  isRefreshingCoures: Bool = false,
  refreshError: TrainingApiClient.ApiError? = nil,
  emid: String? = nil
  ) {
    self.myAttendedCourses = myAttendedCourses
    self.isRefreshingCoures = isRefreshingCoures
    self.refreshError = refreshError
    self.emid = emid
  }
  
}

public enum MyAttendedCoursesAction {
  case course(id: Int, action: Void)
  case refreshCourseRequest
  case refreshCourseResponse(Result<[Course], TrainingApiClient.ApiError>)
}

public struct MyAttendedCoursesEnv {
  public var api: TrainingApiClient
  public var mainQueue: AnySchedulerOf<DispatchQueue>
  
  public init(api: TrainingApiClient, mainQueue: AnySchedulerOf<DispatchQueue>) {
    self.api = api
    self.mainQueue = mainQueue
  }
}

public let myAttendedCoursesReducer =
  
  Reducer<Course, Void, MyAttendedCoursesEnv>.empty
    .forEach(
      state: \.self,
      action: /.self,
      environment: { $0 })
    .optional
    .pullback(
      state: \MyAttendedCoursesState.myAttendedCourses,
      action: /MyAttendedCoursesAction.course(id:action:),
      environment: { $0 }
  )
    .combined(with:
      
      Reducer<MyAttendedCoursesState, MyAttendedCoursesAction, MyAttendedCoursesEnv> { state, action, environment in
        switch action {
          
        case .refreshCourseRequest:
          state.isRefreshingCoures = true
          return environment.api.getMyAttendedCourses(state.emid!)
            .receive(on: environment.mainQueue)
            .catchToEffect()
            .map(MyAttendedCoursesAction.refreshCourseResponse)
        case let .refreshCourseResponse(result):
          state.isRefreshingCoures = false
          switch result {
          case .success(let courses):
            state.myAttendedCourses = courses
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


public struct MyAttendedCourseView: View {
  let store: Store<Course, Void>
  
  public var body: some View {
    WithViewStore(self.store) { course in
      Text(course.topicName)
    }
  }
}


public struct MyAttendedCoursesView: View {
  public let store: Store<MyAttendedCoursesState, MyAttendedCoursesAction>
  
  public var body: some View {
    WithViewStore(self.store) { viewStore in
      
      IfLetStore(
        self.store.scope(
          state: { $0.myAttendedCourses }),
        then: { store in
          List {
            ForEachStore(
              self.store.scope(state: { $0.myAttendedCourses! }, action: MyAttendedCoursesAction.course(id:action:)),
              content: MyAttendedCourseView.init(store:)
            )
          }
      },
        else: ActivityIndicator()
          .frame(maxHeight: .infinity)
          .onAppear {
          viewStore.send(MyAttendedCoursesAction.refreshCourseRequest)
        }
      )
      
      
    }.navigationBarTitle("Attended Courses")
  }
  
  public init(store: Store<MyAttendedCoursesState, MyAttendedCoursesAction>) {
    self.store = store
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    MyAttendedCoursesView(
      store: Store(
        initialState: MyAttendedCoursesState(emid: "0"),
        reducer: myAttendedCoursesReducer,
        environment: MyAttendedCoursesEnv(
          api: .mock(),
          mainQueue: DispatchQueue.main.eraseToAnyScheduler()
        )
    ))
  }
}

