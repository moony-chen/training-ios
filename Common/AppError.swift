//
//  AppError.swift
//  Common
//
//  Created by Moony Chen on 2020/7/29.
//  Copyright © 2020 Moony Chen. All rights reserved.
//

import Foundation
import CasAuth
import TrainingApiClient

public enum AppError: Error, Equatable {
  case casError
  case apiError(TrainingApiClient.ApiError)
}
