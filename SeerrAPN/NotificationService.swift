// Made by Lumaa

import UniformTypeIdentifiers
import UserNotifications

class NotificationService: UNNotificationServiceExtension {

	var contentHandler: ((UNNotificationContent) -> Void)?
	var bestAttemptContent: UNMutableNotificationContent?

	override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
		self.contentHandler = contentHandler
		bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

		print(bestAttemptContent?.userInfo ?? "[NotificationService] No userInfo")

		if let image: String = bestAttemptContent?.userInfo["image"] as? String, let imgURL: URL = URL(string: image) {
			print("[NotificationService] Found image! \(image)")
			if let bestAttemptContent = bestAttemptContent {
				self.downloadImageFrom(url: imgURL) { attachment in
					if let attachment {
						print("[NotificationService] Downloaded attachment sent")
						bestAttemptContent.attachments = [attachment]
						contentHandler(bestAttemptContent)
					} else {
						print("[NotificationService] Failed download")
						contentHandler(bestAttemptContent)
					}
				}
			}
		} else {
			print("[NotificationService] No image sadge")
			if let bestAttemptContent = bestAttemptContent {
				contentHandler(bestAttemptContent)
			}
		}
	}

	override func serviceExtensionTimeWillExpire() {
		print("[NotificationService] Took too long...")
		if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
			contentHandler(bestAttemptContent)
		}
	}

	private func downloadImageFrom(url: URL, with completionHandler: @escaping (UNNotificationAttachment?) -> Void) {
		let task = URLSession.shared.downloadTask(with: url) { (downloadedUrl, response, error) in
			// 1. Test URL and escape if URL not OK
			guard let downloadedUrl = downloadedUrl else {
				completionHandler(nil)
				return
			}

			// 2. Get current's user temporary directory path
			var urlPath = URL(fileURLWithPath: NSTemporaryDirectory())
			// 3. Add proper ending to url path, in the case .jpg (The system validates the content of attached files before scheduling the corresponding notification request. If an attached file is corrupted, invalid, or of an unsupported file type, the notification request is not scheduled for delivery. )
			let uniqueURLEnding = ProcessInfo.processInfo.globallyUniqueString + ".jpg"
			urlPath = urlPath.appendingPathComponent(uniqueURLEnding)

			// 4. Move downloadedUrl to newly created urlPath
			try? FileManager.default.moveItem(at: downloadedUrl, to: urlPath)

			// 5. Try adding getting the attachment and pass it to the completion handler
			do {
				let attachment = try UNNotificationAttachment(identifier: "picture", url: urlPath, options: nil)
				completionHandler(attachment)
			} catch {
				completionHandler(nil)
			}
		}
		task.resume()
	}
}
