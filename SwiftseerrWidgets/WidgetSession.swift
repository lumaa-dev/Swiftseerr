// Made by Lumaa

import Foundation

/// Prepares `SeerSession.shared` inside the widget process.
///
/// Every `Endpoint` builds its URL from `SeerSession.shared.auth.address`, and `MediaRequest.getMedia()`
/// calls through `SeerSession.shared` too. In the extension that singleton starts out empty, so requests
/// were being sent to a relative `/api/v1/...` path (a `URLError.badURL`) with no session cookie attached.
/// Binding the singleton to the configured account, then logging in, is what makes the API reachable.
enum WidgetSession {
	/// Sessions are reused across timeline refreshes instead of logging in every time.
	private static let cookieTTL: TimeInterval = 60 * 60 * 12

	/// Binds the shared session to `auth` and makes sure it carries a usable cookie.
	@discardableResult
	static func prepare(for auth: AuthInfo, forceLogIn: Bool = false) async -> Bool {
		let session = SeerSession.shared

		if session.auth.id != auth.id {
			session.clear()
			session.auth = auth
		}

		if forceLogIn {
			WidgetSession.clearCachedCookie(for: auth)
			session.authorization = nil
		} else if session.authorization == nil {
			session.authorization = WidgetSession.cachedCookie(for: auth)
		}

		if session.authorization != nil {
			return true
		}

		do {
			let sid = try await session.logIn()
			WidgetSession.cacheCookie(sid, for: auth)
			return true
		} catch {
			print("[WidgetSession] Log in failed: \(error.localizedDescription)")
			return false
		}
	}

	// MARK: - Cookie cache

	/// Keyed on address and username only, so the password never lands in shared defaults.
	private static func cookieKey(for auth: AuthInfo) -> String {
		"widget.sid.\(auth.address)|\(auth.username)"
	}

	private static func cachedCookie(for auth: AuthInfo) -> String? {
		let defaults = AppData.sharedDefaults
		let key = WidgetSession.cookieKey(for: auth)

		guard let stored = defaults.dictionary(forKey: key),
			  let sid = stored["sid"] as? String,
			  let date = stored["date"] as? Date,
			  Date.now.timeIntervalSince(date) < WidgetSession.cookieTTL else {
			return nil
		}

		return sid
	}

	private static func cacheCookie(_ sid: String, for auth: AuthInfo) {
		AppData.sharedDefaults.set(
			["sid": sid, "date": Date.now],
			forKey: WidgetSession.cookieKey(for: auth)
		)
	}

	private static func clearCachedCookie(for auth: AuthInfo) {
		AppData.sharedDefaults.removeObject(forKey: WidgetSession.cookieKey(for: auth))
	}
}
