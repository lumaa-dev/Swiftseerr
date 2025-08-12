// Made by Lumaa

import Foundation

struct User {
    let username: String
    let permission: Int

    init(username: String, permission: Int) {
        self.username = username
        self.permission = permission
    }

    init(data: [String: Any]) {
        self.username = data["displayName"] as? String ?? data["username"] as! String
        self.permission = data["permissions"] as! Int
    }

    /// Takes a Permission and the user's permission value and determines
    /// if the user has access to the permission provided. If the user has
    /// the admin permission, true will always be returned from this check!
    ///
    /// - Parameters:
    ///   - permissions: Single permission or array of permissions
    ///   - value: User's current permission value
    ///   - options: Extra options to control permission check behavior (mainly for arrays)
    /// - Returns: Boolean indicating if the user has the specified permission(s)
    func hasPermission(_ permissions: Any, options: Permission.CheckOptions = .and) -> Bool {
        var total = 0

        // If we are not checking any permissions, bail out and return true
        if case let permission as Permission = permissions, permission == Permission.none {
            return true
        }

        if let permissionArray = permissions as? [Permission] {
            if self.permission & Permission.admin.rawValue != 0 {
                return true
            }
            switch options {
                case .and:
                    return permissionArray.allSatisfy { permission in
                        (self.permission & permission.rawValue) != 0
                    }
                case .or:
                    return permissionArray.contains { permission in
                        (self.permission & permission.rawValue) != 0
                    }
            }
        } else if let permission = permissions as? Permission {
            total = permission.rawValue
        }

        return (self.permission & Permission.admin.rawValue) != 0 || (self.permission & total) != 0
    }
}
