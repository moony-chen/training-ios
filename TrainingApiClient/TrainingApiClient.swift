//
//  TrainingApiClient.swift
//  TrainingApiClient
//
//  Created by Moony Chen on 2020/7/24.
//  Copyright © 2020 Moony Chen. All rights reserved.
//


import Foundation
import ComposableArchitecture

let Training_Base = "http://gdctools:8090/training/resteasy/training"

public struct Course: Decodable, Identifiable, Equatable {
  public var id: Int
  public var topicName: String = ""
  public var programName: String = ""
  public var externalTrainer: String? = ""
  public var deliveryDate: Date = Date()
  public var lastUpdate: Date = Date()
  public var startTime: String = ""
  public var endTime: String = ""
  public var description: String = ""
  public var meetingRoom: String? = ""
  
  public var trainers: [User] = []
  public var attendees: [User] = []
  

  public init(
    id: Int = 0,
    topicName: String = "",
    programName: String = "",
    externalTrainer: String? = "",
    deliveryDate: Date = Date(),
    lastUpdate: Date = Date(),
    startTime: String = "",
    endTime: String = "",
    description: String = "",
    meetingRoom: String? = "",
    trainers: [User] = [],
    attendees: [User] = []
  ) {
    self.id = id
    self.topicName = topicName
    self.programName = programName
    self.externalTrainer = externalTrainer
    self.deliveryDate = deliveryDate
    self.lastUpdate = lastUpdate
    self.startTime = startTime
    self.endTime = endTime
    self.description = description
    self.meetingRoom = meetingRoom
    self.trainers = trainers
    self.attendees = attendees
  }
}

public struct LoginRequest: Encodable {
  public var serviceTicket: String
  
  public init(serviceTicket: String) { self.serviceTicket = serviceTicket }
}

public struct LoginResponse: Decodable {
  public var status: Int
  public var authId: String
  public var emp: User
  
  public init(
    status: Int,
    authId: String,
    emp: User
  ) {
    self.status = status
    self.authId = authId
    self.emp = emp
  }
}

public struct User: Decodable, Identifiable, Equatable {
  public var id: Int
  public var screenName = ""
  public var emid: String? = ""
  public var firstName = ""
  public var lastName = ""
  public var active = true
  
  public init(
    id: Int = 0,
    screenName: String = "unknown.user",
    emid: String = "0",
    firstName: String = "N",
    lastName: String = "A",
    active: Bool = false
  ) {
    self.id = id
    self.screenName = screenName
    self.emid = emid
    self.firstName = firstName
    self.lastName = lastName
    self.active = active
  }
  
}

fileprivate struct Courses: Decodable, Equatable {
  var courses: [Course]
}

public struct TrainingApiClient {
  public var getUpcomingCourses: () -> Effect<[Course], ApiError>
  public var getMyRegisteredCourses: (_ emid: String) -> Effect<[Course], ApiError>
  public var getMyAttendedCourses: (_ emid: String) -> Effect<[Course], ApiError>
  
  public var login: (_ request: LoginRequest) -> Effect<LoginResponse, ApiError>

  public struct ApiError: Error, Equatable {}
  
  public init(
    getUpcomingCourses: @escaping () -> Effect<[Course], ApiError>,
    getMyRegisteredCourses: @escaping (_ emid: String) -> Effect<[Course], ApiError>,
    getMyAttendedCourses: @escaping (_ emid: String) -> Effect<[Course], ApiError>,
    login: @escaping (_ request: LoginRequest) -> Effect<LoginResponse, ApiError>
  ) {
    self.getUpcomingCourses = getUpcomingCourses
    self.getMyRegisteredCourses = getMyRegisteredCourses
    self.getMyAttendedCourses = getMyAttendedCourses
    self.login = login
  }
}

extension TrainingApiClient {
  public static func mock(
    getUpcomingCourses: @escaping () -> Effect<[Course], ApiError> = {
      Effect(value: [
        Course(id: 1, topicName: "Swift"),
        Course(id: 2, topicName: "Objc"),
        Course(id: 3, topicName: "Objc++")
        ]).eraseToEffect()
    },
    getMyRegisteredCourses: @escaping (_ emid: String) -> Effect<[Course], ApiError> = { _ in
      Effect(value: [
        Course(id: 1, topicName: "Swift"),
        Course(id: 4, topicName: "English"),
        Course(id: 5, topicName: "CI&CD")
        ]).eraseToEffect()
    },
    getMyAttendedCourses: @escaping (_ emid: String) -> Effect<[Course], ApiError> = { _ in
      Effect(value: [
        Course(id: 1, topicName: "raywenderich"),
        Course(id: 4, topicName: "pointfree"),
        Course(id: 5, topicName: "objc")
        ]).eraseToEffect()
    },
    login: @escaping (_ request: LoginRequest) -> Effect<LoginResponse, ApiError> = { _ in
      Effect(value: LoginResponse(
        status: 1,
        authId: "Moony.Chen1595835757787",
        emp: User(
          id: 135, screenName: "Moony.Chen", emid: "HE170", firstName: "Moony", lastName: "Chen", active: true)))
        .eraseToEffect()
    }
    
  ) -> TrainingApiClient {
    .init(getUpcomingCourses: getUpcomingCourses,
          getMyRegisteredCourses: getMyRegisteredCourses,
          getMyAttendedCourses: getMyAttendedCourses,
          login: login)
  }
}

extension TrainingApiClient {
  public static var live = TrainingApiClient(
    getUpcomingCourses: { recentCourses() },
    getMyRegisteredCourses: myRegisteredCourses,
    getMyAttendedCourses: myAttendedCourses,
    login: myLogin
  )
}

private func recentCourses(from: Date = Date(), to: Date = Date() + 60 * 3600, emid: String = "0") -> Effect<[Course], TrainingApiClient.ApiError> {
  let url = URL(string: "\(Training_Base)/course/recentcourses/\(df.string(from: from))/\(df.string(from: to))/\(emid)")!

  return URLSession.shared.dataTaskPublisher(for: url)
    .map { data, _ in data }
    .decode(type: Courses.self, decoder: jsonDecoder)
    .map { $0.courses }
    .mapError { err in
      print(err)
      return .init()
  }
    .eraseToEffect()
}

private func myRegisteredCourses(emid: String = "0") -> Effect<[Course], TrainingApiClient.ApiError> {
  let url = URL(string: "\(Training_Base)/course/myRegistered/\(emid)")!

  return URLSession.shared.dataTaskPublisher(for: url)
    .map { data, _ in data }
    .decode(type: Courses.self, decoder: jsonDecoder)
    .map { $0.courses }
    .mapError { err in
      print(err)
      return .init()
  }
    .eraseToEffect()
}

private func myAttendedCourses(emid: String = "0") -> Effect<[Course], TrainingApiClient.ApiError> {
  let url = URL(string: "\(Training_Base)/course/myAttended/\(emid)")!

  return URLSession.shared.dataTaskPublisher(for: url)
    .map { data, _ in data }
    .decode(type: Courses.self, decoder: jsonDecoder)
    .map { $0.courses }
    .mapError { err in
      print(err)
      return .init()
  }
    .eraseToEffect()
}

private func myLogin(loginRequest: LoginRequest) -> Effect<LoginResponse, TrainingApiClient.ApiError> {
  let url = URL(string: "\(Training_Base)/user/login")!
  var request = URLRequest(url: url)
  request.httpMethod = "POST"
  request.addValue("application/json", forHTTPHeaderField: "Content-Type")
  request.addValue("application/json", forHTTPHeaderField: "Accept")
  
  request.httpBody = try? jsonEncoder.encode(loginRequest)

  return URLSession.shared.dataTaskPublisher(for: request)
    .map { data, _ in data }
    .decode(type: LoginResponse.self, decoder: jsonDecoder)
    .mapError { err in
      print(err)
      return .init()
  }
    .eraseToEffect()
}

private let jsonDecoder: JSONDecoder = {
  let d = JSONDecoder()
  d.dateDecodingStrategy = .millisecondsSince1970
  return d
}()

private let jsonEncoder: JSONEncoder = {
  let d = JSONEncoder()
  d.dateEncodingStrategy = .millisecondsSince1970
  return d
}()

private let df: DateFormatter = {
  let formatter = DateFormatter()
  formatter.dateFormat = "yyyy-MM-dd"
  return formatter
}()
