// Made by Lumaa

import Foundation

enum Permission: Int {
    case none = 0
    case admin = 2
    case manageSettings = 4
    case manageUsers = 8
    case manageRequests = 16
    case request = 32
    case vote = 64
    case autoApprove = 128
    case autoApproveMovie = 256
    case autoApproveTV = 512
    case request4K = 1024
    case request4KMovie = 2048
    case request4KTV = 4096
    case requestAdvanced = 8192
    case requestView = 16384
    case autoApprove4K = 32768
    case autoApprove4KMovie = 65536
    case autoApprove4KTV = 131072
    case requestMovie = 262144
    case requestTV = 524288
    case manageIssues = 1048576
    case viewIssues = 2097152
    case createIssues = 4194304
    case autoRequest = 8388608
    case autoRequestMovie = 16777216
    case autoRequestTV = 33554432
    case recentView = 67108864
    case watchlistView = 134217728
    case manageBlacklist = 268435456
    case viewBlacklist = 1073741824

    enum CheckOptions {
        case and
        case or
    }
}
