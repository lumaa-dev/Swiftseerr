// Made by Lumaa


// Made by Lumaa

import SwiftUI

struct RequestRow: View {
    @Binding var request: MediaRequest
    let showActions: Bool

    @State private var item: MediaItem?

    @State private var fileDelConfirm: Bool = false

    private var width: CGFloat { self.height * (1.0 / 1.5) }
    private let height: CGFloat = 100

	private var hasPermissions: Bool {
		let user = SeerSession.shared.user
		return user?.hasPermission(Permission.manageRequests) ?? false
	}

    let onDelete: () -> Void

    init(_ request: Binding<MediaRequest>, showActions: Bool = true, onDelete: @escaping () -> Void = {}) {
        self._request = request
        self.showActions = showActions
        self.onDelete = onDelete
    }

    var body: some View {
        if item != nil {
            itemView
        } else {
            ProgressView()
                .progressViewStyle(.circular)
                .frame(width: 370, height: 200, alignment: .center)
                .background(Color.gray.opacity(0.4).gradient)
                .clipShape(RoundedRectangle(cornerRadius: 15.0))
                .task {
                    if let m = try? await self.request.getMedia() {
                        self.item = m
                    }
                }
        }
    }

    @ViewBuilder
    var itemView: some View {
        if let item {
            VStack(spacing: 16.0) {
                NavigationLink {
                    #if os(tvOS) || os(macOS)
                    Text(item.title)
                    #else
                    MediaItemView(item)
                    #endif
                } label: {
                    HStack(spacing: 8) {
                        poster
                            .frame(width: width, height: height)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        VStack(alignment: .leading) {
                            Text(item.title)
                                .font(.callout.bold())
                                .lineLimit(1)
                                .multilineTextAlignment(.leading)

                            Text(item.requestStatus.localized)
                                .foregroundStyle(Color.white)
                                .font(.callout)
                                .glassPill(item.requestStatus.color)
                        }
                    }
                    .frame(width: 330, alignment: .leading)
                }
                .frame(width: 330, alignment: .leading)
                .buttonStyle(.plain)

                if showActions {
                    actions
                        .frame(width: 330)
                }
            }
            .frame(width: 370, alignment: .center)
            .padding(.vertical)
            .background {
                back
                    .mask(Color.white.opacity(0.4))
                    .blur(radius: 5.0)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 15.0))
            }
            .mediaContext(media: item)
        }
    }

    @ViewBuilder
    var actions: some View {
        if var item {
            GlassEffectContainer {
                VStack(spacing: 8) {
					if hasPermissions, item.requestStatus == .pending {
						HStack {
							Button {
								Task {
									if let http = await self.updateStatus(.approve, request: request), http.statusCode == 200 {
										item.requestHd = item.requestHd == .pending ? .processing : item.requestHd
										item.request4k = item.request4k == .pending ? .processing : item.request4k
										self.request.status = .processing

										self.item = item
									}
								}
							} label: {
								Label("request.accept", systemImage: "checkmark")
									.buttonGlass(Color.green)
							}
							.disabled(request.status != .unknown)

							Button {
								Task {
									if let http = await self.updateStatus(.decline, request: request), http.statusCode == 200 {
										item.requestHd = item.requestHd == .pending ? .blacklisted : item.requestHd
										item.request4k = item.request4k == .pending ? .blacklisted : item.request4k
										self.request.status = .blacklisted

										self.item = item
									}
								}
							} label: {
								Label("request.decline", systemImage: "xmark")
									.buttonGlass(Color.red)
							}
							.disabled(request.status != .unknown)

							Menu {
								Button(role: .destructive) {
									Task {
										if await self.deleteRequest() {
											onDelete()
										}
									}
								} label: {
									Label("delete.request", systemImage: "trash.fill")
								}

								Button(role: .destructive) {
									Task {
										await self.deleteSonarr()
									}
								} label: {
									Label("delete.radarr", systemImage: "document.on.trash.fill")
								}
								.disabled(item.requestStatus == .deleted)
							} label: {
								Label("delete", systemImage: "ellipsis")
									.labelStyle(.iconOnly)
									.frame(width: 40, height: 40)
									.foregroundStyle(Color.white)
									.glassEffect(.clear.interactive().tint(Color.black.opacity(0.4)))
							}
						}
					}

					if (hasPermissions && item.requestStatus != .pending) || !hasPermissions {
						Button {
							Task {
								if await self.deleteRequest() {
									onDelete()
								}
							}
						} label: {
							Label("delete.request", systemImage: "trash.fill")
								.foregroundStyle(Color.white)
								.buttonGlass(Color.red)
						}
						.buttonStyle(.plain)

						if let user = SeerSession.shared.user, user.hasPermission(Permission.manageRequests), item.requestStatus != .deleted {
							Button {
								withAnimation {
									self.fileDelConfirm = true
								}
							} label: {
								Label("delete.radarr", systemImage: "document.on.trash.fill")
									.foregroundStyle(Color.white)
									.buttonGlass(Color.red)
							}
							.buttonStyle(.plain)
							.confirmationDialog("confirm.delete.radarr", isPresented: $fileDelConfirm, titleVisibility: .visible) {
								Button(role: .destructive) {
									Task {
										await self.deleteSonarr()
									}
								} label: {
									Text("delete.radarr")
								}

								Button(role: .cancel) {} label: {
									Text("cancel")
								}
							} message: {
								Text("confirm.delete.radarr.message")
							}
						}
					}
                }
            }
        }
    }

    @ViewBuilder
    var poster: some View {
        AsyncImage(url: item?.image ?? URL(string: "\(SeerSession.shared.auth.address)/images/jellyseerr_poster_not_found.png")) { image in
            image
                .resizable()
                .scaledToFill()
                .frame(width: self.width, height: self.height)
                .clipped()
        } placeholder: {
            Rectangle()
                .fill(Color.clear)
                .frame(width: self.width, height: self.height)
                .overlay {
                    ProgressView()
                        .progressViewStyle(.circular)
                }
        }
    }

    @ViewBuilder
    var back: some View {
        AsyncImage(url: item?.backdrop) { image in
            image
                .resizable()
                .scaledToFill()
                .frame(width: 370, alignment: .center)
        } placeholder: {
            EmptyView()
        }
    }

    // MARK: Methods

    private func deleteRequest() async -> Bool {
        let http: HTTPURLResponse? = try? await SeerSession.shared.raw(Requests.delete(id: self.request.id)).1
        let code = http?.statusCode ?? -1

        return code == 204
    }

    private func deleteSonarr() async -> Bool {
        guard let mediaId = self.request.mediaId else { return false }
        let http: HTTPURLResponse? = try? await SeerSession.shared.raw(Requests.deleteFile(id: mediaId)).1
        let code = http?.statusCode ?? -1

        return code == 204
    }

	private func updateStatus(_ status: Requests.Status, request: MediaRequest) async -> HTTPURLResponse? {
		let http: HTTPURLResponse? = try? await SeerSession.shared.raw(Requests.updateStatus(id: request.id, status: status)).1
		return http
	}
}

private extension View {
    @ViewBuilder
    func buttonGlass(_ tint: Color = Color.accentColor) -> some View {
        self
			.foregroundStyle(Color.white)
            .frame(maxWidth: .infinity, minHeight: 40)
            .glassEffect(.clear.interactive().tint(tint.opacity(0.4)))
    }
}
