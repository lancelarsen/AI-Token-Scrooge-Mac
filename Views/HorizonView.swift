import SwiftUI

struct HorizonView: View {
    @Environment(AppStore.self) private var store
    @State private var showSettings = false
    @State private var viewport = HorizonViewport(now: .now, furthestFuture: nil, zone: TimeZone(identifier: "America/Chicago")!, width: 1000)
    @State private var position = ScrollPosition(x: 0)
    @State private var selectedEvent: HorizonEvent?
    @State private var selectedHistoricalMarker: HistoricalEventMarker?
    @State private var presentation = HorizonPresentation()
    @State private var historyPinned = false
    @State private var hoverText: String?
    @State private var hoveredSample: (account: ProviderAccount, point: HistoryPoint)?
    private var events: [HorizonEvent] { HorizonEvent.events(state: store.state, now: .now) }
    private var timelineAccounts: [ProviderAccount] { AccountPolicy.ordered(store.state, mode: .custom).filter(\.enabled) }
    var body: some View {
        ScroogeCard {
            VStack(spacing: 18) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 24) { heading; legend; historyToggle; Text(store.state.settings.historyEnabled ? "Scroll Left for History" : "Select Services to Filter Timeline").font(.system(size: 13)).foregroundStyle(Theme.secondary); Spacer(); settingsButton }
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 22) { heading; legend; Spacer(minLength: 0); settingsButton }
                        HStack(spacing: 18) {
                            historyToggle
                            Text(store.state.settings.historyEnabled ? "Scroll Left for History" : "Select Services to Filter Timeline")
                                .font(.system(size: 13)).foregroundStyle(Theme.secondary)
                            Spacer(minLength: 0)
                        }
                    }
                }
                Divider().overlay(Theme.border)
                if store.state.accounts.isEmpty {
                    emptyTimeline
                } else {
                HStack(alignment: .top, spacing: 16) {
                    selectors.frame(width: 90)
                    Divider()
                    HStack(spacing: 0) {
                        historyAxis.frame(width: 40).opacity(store.state.settings.historyEnabled ? 1 : 0)
                        GeometryReader { geometry in
                            ScrollView(.horizontal) {
                                timeline.frame(width: viewport.contentWidth, height: timelineHeight)
                                    .background(HistoryPointerTracking(text: hoverText, pinned: historyPinned, anchor: historyPinned ? sampleAnchor : nil, onMove: { if !historyPinned { updateHistoryHover($0) } }))
                            }
                            .scrollIndicators(.hidden).scrollPosition($position)
                            .onScrollGeometryChange(for: Double.self) { $0.contentOffset.x } action: { _, value in if position.isPositionedByUser { viewport.scroll(to: value) } }
                            .onAppear { update(width: geometry.size.width) }
                            .onChange(of: geometry.size.width) { _, width in update(width: width) }
                            .onChange(of: store.state.settings.historyEnabled) { _, _ in update(width: geometry.size.width) }
                            .onChange(of: store.state.settings.timeZoneID) { _, _ in update(width: geometry.size.width) }
                            .onChange(of: events.map(\.date)) { _, _ in update(width: geometry.size.width) }
                        }
                    }
                }.frame(height: timelineHeight)
                }
                if store.state.accounts.isEmpty {
                    RoundedRectangle(cornerRadius: 5).fill(Theme.activeControl)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.accent))
                        .overlay(Image(systemName: "ellipsis").font(.system(size: 10)).foregroundStyle(Theme.accent))
                        .frame(height: 22)
                } else { navigator.frame(height: 22) }
                if let historyStatus {
                    Text(historyStatus).font(.system(size: 13)).foregroundStyle(Theme.secondary)
                        .frame(maxWidth: .infinity).accessibilityIdentifier("historyStatus")
                }
            }
        }
        .background {
            GeometryReader { geometry in
                HorizonWheelRouting { delta in
                    viewport.scroll(to: viewport.scrollOffset + delta)
                    position.scrollTo(x: viewport.scrollOffset)
                }.frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .onAppear { prepareHistory() }
        .onChange(of: store.historyRevision) { _, _ in prepareHistory() }
        .onChange(of: timelineAccounts) { _, _ in prepareHistory() }
        .onChange(of: viewport.startCoordinate) { _, _ in prepareHistory() }
        .onChange(of: viewport.pixelsPerDay) { _, _ in prepareHistory() }
        .onChange(of: store.state.settings.timeZoneID) { _, _ in prepareHistory() }
        .sheet(isPresented: $showSettings) { SettingsView().environment(store) }
        .sheet(item: $selectedEvent) { event in
            DetailsDialog(close: { selectedEvent = nil }) {
              VStack(alignment: .leading, spacing: 8) {
                if event.reportedAt == nil {
                    AccountUsageDetailsView(accountID: event.account.id, windowID: event.windowID)
                } else {
                    Label(event.title, systemImage: event.expiration ? "hourglass" : "arrow.clockwise").font(.system(size: 20, weight: .semibold)).foregroundStyle(event.expiration ? Theme.amber : Theme.accent)
                    Text("\(event.account.provider.rawValue) · \(store.state.settings.privacy ? "Account" : event.account.nickname)")
                    Text(Format.date(event.date, zone: store.state.settings.zone))
                    if let reportedAt = event.reportedAt {
                        Text("Reported \(Format.date(reportedAt, zone: store.state.settings.zone))").foregroundStyle(Theme.secondary)
                        Text("This is a reported schedule, not confirmation that capacity reset or a credit was redeemed.").font(.callout)
                    } else { Text(Format.countdown(event.date)).foregroundStyle(Theme.secondary) }
                }
              }
            }
        }
        .sheet(item: $selectedHistoricalMarker) { marker in historicalDetails(marker) }
    }
    private func historicalDetails(_ marker: HistoricalEventMarker) -> some View {
        DetailsDialog(close: { selectedHistoricalMarker = nil }) {
          VStack(alignment: .leading, spacing: 16) {
            Text("History Event").font(.system(size: 20, weight: .semibold)).foregroundStyle(.white)
            Group {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(marker.events) { event in
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(event.account.provider.rawValue) / \(store.state.settings.privacy ? "Account" : event.account.nickname) · \(Format.plan(event.account.provider, event.plan))")
                            Text("\(event.title): \(Format.date(event.date, zone: store.state.settings.zone))")
                            if let reported = event.reportedAt { Text("Reported \(Format.date(reported, zone: store.state.settings.zone))") }
                        }
                    }
                    Text("This is a reported schedule, not confirmation that capacity reset or a credit was redeemed.").foregroundStyle(Theme.secondary)
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
          }
        }
    }
    private var emptyTimeline: some View {
        HStack(spacing: 16) {
            Color.clear.frame(width: 90)
            Divider()
            Canvas { context, size in
                let left: CGFloat = 40
                let anchor = left + 88
                var rail = Path()
                rail.move(to: CGPoint(x: left, y: 56))
                rail.addLine(to: CGPoint(x: size.width, y: 56))
                context.stroke(rail, with: .color(Theme.accent.opacity(0.7)), lineWidth: 2)
                context.draw(Text("Today").font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.accent), at: CGPoint(x: anchor, y: 7))
                let date = Date.now.formatted(Date.FormatStyle().month(.abbreviated).day().withTimeZone(store.state.settings.zone))
                context.draw(Text(date).font(.system(size: 12)).foregroundStyle(Theme.secondary), at: CGPoint(x: anchor, y: 31))
                context.fill(Path(ellipseIn: CGRect(x: anchor - 8, y: 48, width: 16, height: 16)), with: .color(Color(hex: "#D1BEFF")))
                if store.state.settings.historyEnabled {
                    var boundary = Path()
                    boundary.move(to: CGPoint(x: left, y: 88))
                    boundary.addLine(to: CGPoint(x: left, y: size.height - 4))
                    context.stroke(boundary, with: .color(Theme.accent), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                }
            }.accessibilityLabel("Today. No connected accounts or upcoming events.")
        }.frame(height: 216)
    }
    private var plotTop: Double { 56 + 32 }
    private var plotBottom: Double { timelineHeight - 8 }
    private var plotHeight: Double { max(1, plotBottom - plotTop) }
    private var historyAxis: some View {
        Canvas { context, _ in
            guard viewport.position(at: .now) - viewport.scrollOffset > 2 else { return }
            for percent in stride(from: 0, through: 100, by: 25) {
                let y = plotTop + (1 - Double(percent) / 100) * plotHeight
                context.draw(Text("\(percent)%").font(.system(size: 11)).foregroundStyle(Theme.secondary),
                             at: CGPoint(x: 38, y: y), anchor: .trailing)
            }
            context.translateBy(x: 5, y: (plotTop + plotBottom) / 2)
            context.rotate(by: .degrees(-90))
            context.draw(Text("% Used").font(.system(size: 10)).foregroundStyle(Theme.secondary), at: .zero)
        }.accessibilityLabel("History axis: zero to one hundred percent used")
    }
    private var timelineHeight: Double {
        let groups = Dictionary(grouping: events, by: { calendar.startOfDay(for: $0.date) })
        let accounts = max(3, store.state.accounts.filter(\.enabled).count)
        let selectors = 16 + Double(accounts * 66 + (accounts - 1) * 6)
        let future = 56 + 21 + Double(max(1, groups.values.map(\.count).max() ?? 0)) * 76
        return max(selectors, future)
    }
    private var heading: some View { HStack { Image(systemName: "clock.arrow.circlepath").font(.system(size: 30)).foregroundStyle(Theme.accent); Text("Reset Horizon").font(.system(size: 26, weight: .semibold)) } }
    private var historyStatus: String? {
        guard !store.state.accounts.isEmpty else { return nil }
        if !store.state.settings.historyEnabled { return events.isEmpty ? "No Upcoming Events Reported" : nil }
        guard viewport.visibleStart < .now else { return nil }
        let visible = historySeries
        if let error = store.historyError { return error }
        if store.historyLoading && visible.allSatisfy({ $0.points.isEmpty }) { return "Loading History" }
        if visible.isEmpty { return "Select an Account to View History" }
        let end = viewport.date(at: viewport.scrollOffset + viewport.viewportWidth)
        return visible.allSatisfy { series in !series.points.contains { $0.at >= viewport.visibleStart && $0.at <= end } }
            ? "No Recorded Usage in This Period" : nil
    }
    private func historyHelp(_ account: ProviderAccount) -> String {
        let series = presentation.series.first { $0.account.id == account.id }
        let name = store.state.settings.privacy ? "Account" : account.nickname
        if !store.state.settings.historyEnabled {
            return "\(account.provider.rawValue) / \(name) · \(Format.plan(account.provider, store.state.snapshots[account.id]?.planType))\nShow or Hide History, Resets and Refreshes"
        }
        let period = account.provider == .copilot ? "Monthly" : "Weekly"
        var text = "\(account.provider.rawValue) / \(name) · \(Format.plan(account.provider, store.state.snapshots[account.id]?.planType))\n\(period) History"
        if let first = series?.points.first, first.at > viewport.firstDate { text += "\nHistory Begins \(Format.date(first.at, zone: store.state.settings.zone))" }
        if let status = series?.status { text += "\n\(status)" }
        return text
    }
    private var legend: some View {
        HStack(spacing: 36) {
            HStack(spacing: 8) { Circle().fill(Theme.accent).frame(width: 10, height: 10); Text("Quota Refresh (\(events.filter { !$0.expiration }.count))") }
            HStack(spacing: 8) { Circle().fill(Theme.amber).frame(width: 10, height: 10); Text("Reset Expires (\(events.filter(\.expiration).count))") }
        }.font(.system(size: 13)).foregroundStyle(Theme.secondary)
    }
    private var historyToggle: some View {
        HStack(spacing: 7) {
            Toggle("History", isOn: Binding(get: { store.state.settings.historyEnabled }, set: { store.setHistory($0) }))
                .toggleStyle(ScroogeSwitchStyle(showsLabel: false)).frame(width: 40, height: 20).accessibilityLabel("History").accessibilityIdentifier("historyToggle")
            Text("History").font(.system(size: 13))
        }
    }
    private var settingsButton: some View { Button { showSettings = true } label: { ActionLabel(title: "", symbol: "gearshape") }.buttonStyle(ScroogeButtonStyle()).help("Timeline Settings") }
    private var selectors: some View {
        ScrollView {
            VStack(spacing: 6) {
                ForEach(timelineAccounts) { account in
                    Button { store.toggleAccountHistory(account.id) } label: {
                        let enabled = !store.state.settings.hiddenHistoryAccounts.contains(account.id)
                        let accent = Color(hex: account.resolvedLineColor(plan: store.state.snapshots[account.id]?.planType))
                        ZStack {
                            RoundedRectangle(cornerRadius: 13).fill(Color(hex: "#272331"))
                                .overlay(RoundedRectangle(cornerRadius: 13).stroke(accent, lineWidth: 2))
                                .overlay(ProviderIcon(provider: account.provider, size: 30))
                                .padding(.horizontal, 4).padding(.vertical, 10)
                            VStack {
                                selectorBadge(store.state.settings.privacy ? "Account" : account.nickname, size: 11, accent: accent)
                                Spacer(minLength: 0)
                                HStack(alignment: .bottom, spacing: 0) {
                                    selectorBadge(Format.plan(account.provider, store.state.snapshots[account.id]?.planType), size: 10, accent: accent)
                                    Spacer(minLength: 0)
                                    ZStack { if enabled { Image(systemName: "checkmark") } }
                                        .font(.system(size: 12, weight: .bold)).foregroundStyle(.white)
                                        .frame(width: 19, height: 19)
                                        .background(enabled ? accent : Theme.control)
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(accent, lineWidth: 1.5))
                                }
                            }
                        }.frame(width: 82, height: 66).opacity(enabled ? 1 : 0.5)
                    }.buttonStyle(.plain).accessibilityLabel("Show \(account.provider.rawValue) \(store.state.settings.privacy ? "Account" : account.nickname) on Timeline")
                        .help(historyHelp(account))
                }
            }
        }.scrollIndicators(.hidden)
    }
    private func selectorBadge(_ text: String, size: CGFloat, accent: Color) -> some View {
        Text(text).font(.system(size: size)).lineLimit(1).foregroundStyle(.white)
            .padding(.horizontal, 5).padding(.vertical, 2).background(Theme.control)
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(accent, lineWidth: 1.5))
    }
    private var timeline: some View {
        ZStack(alignment: .topLeading) {
            Canvas { context, size in
                var rail = Path(); rail.move(to: CGPoint(x: 0, y: 56)); rail.addLine(to: CGPoint(x: size.width, y: 56))
                context.stroke(rail, with: .color(Theme.accent.opacity(0.7)), lineWidth: 2)
                if store.state.settings.historyEnabled { drawHistory(context: &context, size: size) }
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                historyPinned = false
                updateHistoryHover(location)
                historyPinned = hoverText != nil
            }
            .focusable()
            .focusEffectDisabled()
            .accessibilityLabel("Usage history. Use arrow keys to inspect samples; Escape dismisses details.")
            .accessibilityValue(hoverText ?? "No sample selected")
            .onKeyPress(.leftArrow) { inspectSample(direction: -1); return .handled }
            .onKeyPress(.rightArrow) { inspectSample(direction: 1); return .handled }
            .onKeyPress(.escape) { historyPinned = false; hoverText = nil; hoveredSample = nil; return .handled }

            Group {
                ForEach(HistoricalEventMarker.layout(events: historicalEvents, viewport: viewport, now: .now)) { marker in
                    Button { selectedHistoricalMarker = marker } label: {
                        Group {
                            if marker.events.count > 1 { Text(String(marker.events.count)) }
                            else { Image(systemName: marker.expiration ? "hourglass" : "arrow.clockwise") }
                        }.font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.card)
                            .frame(width: 22, height: 22).background(marker.expiration ? Theme.amber : Theme.accent).clipShape(Circle())
                    }.buttonStyle(.plain).position(x: marker.x, y: Double(56 + marker.lane * 24))
                        .help(marker.events.map { "\($0.title) · \(Format.date($0.date, zone: store.state.settings.zone))" }.joined(separator: "\n"))
                }
            }
            ForEach(days, id: \.self) { date in
                let dayEvents = events.filter { calendar.isDate($0.date, inSameDayAs: date) }
                VStack(spacing: 8) {
                    Text(dayName(date)).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.accent)
                    Text(date.formatted(Date.FormatStyle().month(.abbreviated).day().withTimeZone(store.state.settings.zone))).font(.system(size: 12)).foregroundStyle(Theme.secondary)
                }.frame(width: viewport.pixelsPerDay, height: 40, alignment: .top)
                    .position(x: viewport.dayAnchor(date), y: 20)
                Circle()
                    .fill(isToday(date) ? Color(hex: "#D1BEFF") : dayEvents.isEmpty ? Color(hex: "#1C1E24") : Theme.accent)
                    .frame(width: isToday(date) ? 16 : 10, height: isToday(date) ? 16 : 10)
                    .overlay {
                        if !isToday(date), dayEvents.isEmpty {
                            Circle().strokeBorder(Theme.accent, lineWidth: 2)
                        }
                    }
                    .position(x: viewport.dayAnchor(date), y: 56)
                ForEach(Array((viewport.showsFutureEvents(on: date) ? dayEvents : []).enumerated()), id: \.element.id) { index, event in
                    let accent = Color(hex: event.expiration ? "#EAAA51" : "#B5A0F4")
                    let plan = Format.plan(event.account.provider, event.plan)
                    Button { selectedEvent = event } label: {
                        VStack(spacing: 3) {
                            ZStack(alignment: .top) {
                                ProviderIcon(provider: event.account.provider, size: 27)
                                    .frame(width: 42, height: 42)
                                    .background(Color(hex: event.expiration ? "#49321D" : "#352A50"))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(accent, lineWidth: 2))
                            }.frame(width: 62, height: 49, alignment: .top)
                                .overlay(alignment: .bottom) {
                                    Text(plan == "Plan unavailable" ? "?" : plan)
                                        .font(.system(size: 10, weight: .semibold)).lineLimit(1)
                                        .padding(.horizontal, 5).padding(.vertical, 1)
                                        .background(Color(hex: "#1C1E24"))
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(accent, lineWidth: 1))
                                }
                            Text(event.date.formatted(Date.FormatStyle(date: .omitted, time: .shortened).withTimeZone(store.state.settings.zone))).font(.system(size: 10))
                        }.foregroundStyle(accent).frame(width: 62, height: 74, alignment: .top)
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain).position(x: viewport.dayAnchor(date), y: CGFloat(114 + index * 76))
                        .help("\(event.title) · \(Format.date(event.date, zone: store.state.settings.zone))")
                }
            }
        }.contentShape(Rectangle())
        .onChange(of: viewport.scrollOffset) { _, _ in if !historyPinned { hoverText = nil; hoveredSample = nil } }
        .onChange(of: store.state.settings.historyEnabled) { _, _ in hoverText = nil; hoveredSample = nil; historyPinned = false }
        .onChange(of: store.state.settings.privacy) { _, _ in hoverText = nil; hoveredSample = nil; historyPinned = false }
        .onChange(of: store.state.settings.hiddenHistoryAccounts) { _, _ in hoverText = nil; hoveredSample = nil; historyPinned = false }
        .onChange(of: timelineAccounts.map(\.id)) { _, _ in hoverText = nil; hoveredSample = nil; historyPinned = false }
    }
    private var sampleAnchor: CGPoint? {
        guard let sample = hoveredSample else { return nil }
        return CGPoint(x: historyX(sample.point.at), y: plotTop + NSDecimalNumber(decimal: sample.point.remaining).doubleValue / 100 * plotHeight)
    }
    private func inspectSample(direction: Int) {
        guard store.state.settings.historyEnabled else { return }
        var samples: [(ProviderAccount, HistoryPoint)] = []
        for series in historySeries {
            for point in series.points { samples.append((series.account, point)) }
        }
        samples.sort { left, right in
            if left.1.at == right.1.at { return left.0.id < right.0.id }
            return left.1.at < right.1.at
        }
        guard !samples.isEmpty else { return }
        let current = samples.firstIndex { $0.0.id == hoveredSample?.account.id && $0.1.at == hoveredSample?.point.at }
        let index = current.map { min(samples.count - 1, max(0, $0 + direction)) } ?? (direction > 0 ? 0 : samples.count - 1)
        let sample = samples[index]
        let x = viewport.position(at: sample.1.at)
        viewport.scroll(to: x - viewport.viewportWidth / 2)
        position.scrollTo(x: viewport.scrollOffset)
        showHistorySample(account: sample.0, point: sample.1)
        historyPinned = true
    }
    private func updateHistoryHover(_ location: CGPoint?) {
        guard let location else { hoverText = nil; hoveredSample = nil; return }
        let date = viewport.date(at: location.x)
        func distance(_ point: HistoryPoint) -> Double {
            let x = historyX(point.at)
            let y = plotTop + NSDecimalNumber(decimal: point.remaining).doubleValue / 100 * plotHeight
            return abs(x - location.x) + abs(y - location.y) * 0.45
        }
        let nearest = historySeries.flatMap { series in series.points.filter { abs(historyX($0.at) - location.x) <= 18 }.map { (series.account, $0) } }
            .min { distance($0.1) < distance($1.1) }
        let estimate = nearest == nil ? historySeries.compactMap { series in
            UsageHistory.estimatedPoint(points: series.points, x: location.x, y: location.y, viewport: viewport, plotTop: plotTop, plotHeight: plotHeight).map { (series.account, $0) }
        }.first : nil
        if store.state.settings.historyEnabled, date <= .now, (plotTop...plotBottom).contains(location.y), let (account, point) = nearest ?? estimate {
            showHistorySample(account: account, point: point)
        } else { hoverText = nil; hoveredSample = nil }
    }
    private func showHistorySample(account: ProviderAccount, point: HistoryPoint) {
        hoveredSample = (account, point)
        var details = historyHelp(account)
        details += "\n\(Format.percent(100 - point.remaining)) Used · \(Format.date(point.at, zone: store.state.settings.zone))"
        if point.estimated { details += "\nEstimated Linear Connection From Previous Observation" }
        if let previous = point.replenishedFrom {
            details += "\nCapacity Rose From \(Format.percent(previous)) to \(Format.percent(point.remaining)) · Observed Between Polls"
            if let prior = point.previousObservedAt {
                details += "\n\(Format.date(prior, zone: store.state.settings.zone)) – \(Format.date(point.at, zone: store.state.settings.zone))"
            }
        }
        hoverText = details
    }

    private var navigator: some View {
        GeometryReader { geometry in
            let trackWidth = max(1, geometry.size.width - 2)
            let overview = viewport.overview(trackWidth: trackWidth)
            Canvas { context, _ in
                let track = Path(roundedRect: CGRect(x: 1, y: 1, width: trackWidth, height: 20), cornerRadius: 5)
                context.fill(track, with: .color(Color(hex: "#232429")))
                context.stroke(track, with: .color(Color(hex: "#45464D")), lineWidth: 1)
                let thumb = Path(roundedRect: CGRect(x: overview.left + 1, y: 1, width: overview.width, height: 20), cornerRadius: 5)
                context.fill(thumb, with: .color(Color(hex: "#483A64")))
                context.stroke(thumb, with: .color(Theme.accent), lineWidth: 1)
                let markers = events + historicalEvents
                let groups = Dictionary(grouping: markers) { event in
                    "\(calendar.startOfDay(for: event.date).timeIntervalSince1970)/\(event.expiration)/\(event.reportedAt == nil)"
                }
                for group in groups.values {
                    guard let event = group.first else { continue }
                    let position = event.reportedAt == nil ? viewport.dayAnchor(event.date) : viewport.position(at: event.date)
                    let x = 1 + position / viewport.contentWidth * trackWidth
                    let y = event.expiration ? 14.0 : 9.0
                    let dot = Path(ellipseIn: CGRect(x: x - 2.5, y: y - 2.5, width: 5, height: 5))
                    context.fill(dot, with: .color(Color(hex: event.expiration ? "#EAAA51" : "#B5A0F4")))
                }
                let nowX = 1 + viewport.position(at: .now) / viewport.contentWidth * trackWidth
                var nowLine = Path()
                nowLine.move(to: CGPoint(x: nowX, y: 3)); nowLine.addLine(to: CGPoint(x: nowX, y: 19))
                context.stroke(nowLine, with: .color(Color(hex: "#E5DCF9")), lineWidth: 1)
                for column in -1...1 {
                    for row in 0...1 {
                        let x = overview.left + overview.width / 2 + Double(column * 4)
                        let y = Double(9 + row * 4)
                        context.fill(Path(ellipseIn: CGRect(x: x - 1, y: y - 1, width: 2, height: 2)), with: .color(Color(hex: "#D1BEFF")))
                    }
                }
            }.contentShape(Rectangle()).gesture(DragGesture(minimumDistance: 0).onChanged { value in
                viewport.centerFromOverview(pointerX: value.location.x - 1, trackWidth: trackWidth)
                position.scrollTo(x: viewport.scrollOffset)
            })
            .accessibilityLabel("Timeline Navigator").accessibilityValue(Format.date(viewport.visibleStart, zone: store.state.settings.zone))
            .accessibilityAdjustableAction { direction in
                viewport.scroll(to: viewport.scrollOffset + (direction == .increment ? 1 : -1) * viewport.pixelsPerDay)
                position.scrollTo(x: viewport.scrollOffset)
            }
        }
    }
    private func drawHistory(context: inout GraphicsContext, size: CGSize) {
        let nowX = viewport.position(at: .now)
        let chartHeight = plotHeight
        for percent in stride(from: 0, through: 100, by: 25) {
            let y = plotTop + (1 - Double(percent) / 100) * chartHeight
            var line = Path(); line.move(to: CGPoint(x: 0, y: y)); line.addLine(to: CGPoint(x: max(0, nowX), y: y))
            context.stroke(line, with: .color(Theme.border.opacity(0.6)), lineWidth: 1)
        }
        for day in days {
            let x = viewport.position(at: day)
            guard x >= 0, x <= nowX else { continue }
            var line = Path()
            line.move(to: CGPoint(x: x, y: plotTop))
            line.addLine(to: CGPoint(x: x, y: plotTop + chartHeight))
            context.stroke(line, with: .color(Color(hex: "#30333C")), lineWidth: 1)
        }
        for series in historySeries {
            let points = presentation.renderPoints[series.account.id] ?? []
            let color = Color(hex: series.account.resolvedLineColor(plan: store.state.snapshots[series.account.id]?.planType))
            var segment: [CGPoint] = []
            func flush() {
                guard let first = segment.first, let last = segment.last else { return }
                var path = Path(); path.addLines(segment)
                var fill = Path(); fill.move(to: CGPoint(x: first.x, y: plotTop + chartHeight))
                for point in segment { fill.addLine(to: point) }
                fill.addLine(to: CGPoint(x: last.x, y: plotTop + chartHeight)); fill.closeSubpath()
                context.fill(fill, with: .color(color.opacity(0.09)))
                context.stroke(path, with: .color(color), lineWidth: 2)
                if segment.count == 1 { context.fill(Path(ellipseIn: CGRect(x: first.x - 2.5, y: first.y - 2.5, width: 5, height: 5)), with: .color(color)) }
                segment.removeAll()
            }
            for point in points {
                if point.startsSegment { flush() }
                let x = historyX(point.at)
                if let before = point.replenishedFrom, !segment.isEmpty {
                    segment.append(CGPoint(x: x, y: plotTop + NSDecimalNumber(decimal: before).doubleValue / 100 * chartHeight))
                }
                segment.append(CGPoint(x: x, y: plotTop + NSDecimalNumber(decimal: point.remaining).doubleValue / 100 * chartHeight))
            }
            flush()
        }
        for event in historicalEvents {
            let x = viewport.position(at: event.date)
            guard x >= viewport.scrollOffset, x <= min(nowX, viewport.scrollOffset + viewport.viewportWidth) else { continue }
            var marker = Path(); marker.move(to: CGPoint(x: x, y: plotTop)); marker.addLine(to: CGPoint(x: x, y: plotTop + chartHeight))
            context.stroke(marker, with: .color((event.expiration ? Theme.amber : Theme.accent).opacity(0.6)), style: StrokeStyle(lineWidth: 1, dash: [4,4]))
        }
        if let sample = hoveredSample,
           timelineAccounts.contains(where: { $0.id == sample.account.id }),
           !store.state.settings.hiddenHistoryAccounts.contains(sample.account.id) {
            let x = historyX(sample.point.at)
            let y = plotTop + NSDecimalNumber(decimal: sample.point.remaining).doubleValue / 100 * chartHeight
            var guide = Path()
            guide.move(to: CGPoint(x: x, y: plotTop))
            guide.addLine(to: CGPoint(x: x, y: plotTop + chartHeight))
            context.stroke(guide, with: .color(Theme.secondary.opacity(0.6)), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            let dot = Path(ellipseIn: CGRect(x: x - 4, y: y - 4, width: 8, height: 8))
            context.fill(dot, with: .color(Color(hex: sample.account.resolvedLineColor(plan: store.state.snapshots[sample.account.id]?.planType))))
            context.stroke(dot, with: .color(.white), lineWidth: 1)
        }
        if nowX >= viewport.scrollOffset - 1, nowX <= viewport.scrollOffset + viewport.viewportWidth + 1 {
            var currentTime = Path()
            currentTime.move(to: CGPoint(x: nowX, y: plotTop))
            currentTime.addLine(to: CGPoint(x: nowX, y: plotTop + chartHeight))
            context.stroke(currentTime, with: .color(Theme.accent), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
        }
        let latest = historySeries.compactMap { series -> (UsageHistorySeries, HistoryPoint)? in
            guard let point = series.points.last(where: { historyX($0.at) >= viewport.scrollOffset && historyX($0.at) <= viewport.scrollOffset + viewport.viewportWidth }) else { return nil }
            return (series, point)
        }.sorted { $0.1.remaining < $1.1.remaining }
        let desired = latest.map { plotTop + NSDecimalNumber(decimal: $0.1.remaining).doubleValue / 100 * chartHeight - 10 }
        let labels = HistoryLabelLayout.positions(desired, top: plotTop, bottom: plotTop + chartHeight - 21)
        for (index, item) in latest.enumerated() {
            let (series, point) = item
            let x = historyX(point.at)
            guard x >= viewport.scrollOffset, x <= viewport.scrollOffset + viewport.viewportWidth else { continue }
            let color = Color(hex: series.account.resolvedLineColor(plan: store.state.snapshots[series.account.id]?.planType))
            let y = plotTop + NSDecimalNumber(decimal: point.remaining).doubleValue / 100 * chartHeight
            context.fill(Path(ellipseIn: CGRect(x: x - 3, y: y - 3, width: 6, height: 6)), with: .color(color))
            let end = viewport.scrollOffset + viewport.viewportWidth
            guard nowX >= end - 80, x >= end - 70 else { continue }
            let labelX = end - 86, labelY = labels[index]
            var connector = Path(); connector.move(to: CGPoint(x: x - 4, y: y)); connector.addLine(to: CGPoint(x: labelX + 80, y: labelY + 10))
            context.stroke(connector, with: .color(color.opacity(0.6)), lineWidth: 1)
            let rect = CGRect(x: labelX, y: labelY, width: 80, height: 21)
            context.fill(Path(roundedRect: rect, cornerRadius: 6), with: .color(Theme.card))
            context.stroke(Path(roundedRect: rect, cornerRadius: 6), with: .color(color.opacity(0.7)), lineWidth: 1)
            let plan = Format.plan(series.account.provider, store.state.snapshots[series.account.id]?.planType)
            context.draw(Text("\(plan) \(Format.percent(100 - point.remaining))").font(.system(size: 10)).foregroundColor(color), at: CGPoint(x: rect.midX, y: rect.midY))
        }
    }
    private func prepareHistory() {
        presentation = HorizonPresentation(accounts: timelineAccounts, runs: store.history, viewport: viewport, now: .now)
    }
    private func historyX(_ date: Date) -> Double { presentation.positions[date] ?? viewport.position(at: date) }
    private var historicalEvents: [HorizonEvent] {
        presentation.events.filter { !store.state.settings.hiddenHistoryAccounts.contains($0.account.id) }
    }
    private var historySeries: [UsageHistorySeries] {
        presentation.series.filter { !store.state.settings.hiddenHistoryAccounts.contains($0.account.id) }
    }

    private var calendar: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = store.state.settings.zone; return c }
    private var days: [Date] {
        let start = calendar.startOfDay(for: viewport.date(at: 0))
        let count = min(370, Int(ceil(viewport.contentWidth / viewport.pixelsPerDay)) + 1)
        return (0..<count).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
    }
    private func dayName(_ date: Date) -> String {
        if isToday(date) { return "Today" }
        let formatter = DateFormatter(); formatter.timeZone = store.state.settings.zone; formatter.dateFormat = "EEE"; return formatter.string(from: date)
    }
    private func isToday(_ date: Date) -> Bool { calendar.isDate(date, inSameDayAs: .now) }
    private func update(width: Double) {
        hoverText = nil; hoveredSample = nil
        viewport.update(now: .now, furthestFuture: events.map(\.date).max(), zone: store.state.settings.zone, width: width, historyEnabled: store.state.settings.historyEnabled)
        position.scrollTo(x: viewport.scrollOffset)
    }
}

private extension Date.FormatStyle {
    func withTimeZone(_ zone: TimeZone) -> Self { var style = self; style.timeZone = zone; return style }
}

/// A non-interactive tracking surface: event buttons and scrolling retain hit testing.
struct HistoryPointerTracking: NSViewRepresentable {
    var text: String? = nil
    var pinned = false
    var anchor: CGPoint? = nil
    var onMove: (CGPoint?) -> Void

    func makeNSView(context: Context) -> TrackingView {
        let view = TrackingView()
        view.onMove = onMove
        return view
    }

    func updateNSView(_ view: TrackingView, context: Context) {
        view.onMove = onMove
        view.pinned = pinned
        if let anchor { view.pointer = anchor }
        view.showPopup(text)
    }
    static func dismantleNSView(_ view: TrackingView, coordinator: ()) { view.hidePopup() }

    final class TrackingView: NSView {
        var onMove: ((CGPoint?) -> Void)?
        private var area: NSTrackingArea?
        private var popup: NSPanel?
        var pointer = NSPoint.zero
        var pinned = false
        func hidePopup() { popup?.orderOut(nil) }
        func showPopup(_ text: String?) {
            guard let text, let window, let screen = window.screen else { hidePopup(); return }
            let panel = popup ?? NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: true)
            if popup == nil {
                panel.isOpaque = false; panel.backgroundColor = .clear
                panel.title = "Usage History Details"
                panel.hasShadow = true; panel.ignoresMouseEvents = true
                panel.level = .floating; popup = panel
            }
            let lines = text.split(separator: "\n", maxSplits: 1).map(String.init)
            let content = NSHostingView(rootView:
                VStack(alignment: .leading, spacing: 5) {
                    Text(lines[0]).font(.system(size: 14, weight: .semibold)).foregroundStyle(Color(hex: "#F2F1F5"))
                    if lines.count > 1 { Text(lines[1]).font(.system(size: 13)).foregroundStyle(Theme.secondary) }
                }.padding(.horizontal, 14).padding(.vertical, 10).frame(maxWidth: 420, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .background(Color(hex: "#222329"), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "#65577F"))))
            let size = content.fittingSize
            let anchor = window.convertPoint(toScreen: convert(pointer, to: nil))
            let visible = screen.visibleFrame.insetBy(dx: 8, dy: 8)
            let x = min(max(visible.minX, anchor.x - size.width / 2), visible.maxX - size.width)
            let above = anchor.y + 14
            let y = min(max(visible.minY, above + size.height <= visible.maxY ? above : anchor.y - size.height - 18), visible.maxY - size.height)
            panel.contentView = content
            panel.setFrame(NSRect(origin: NSPoint(x: x, y: y), size: size), display: true)
            panel.orderFront(nil)
        }
        override var isFlipped: Bool { true }
        override func hitTest(_ point: NSPoint) -> NSView? { nil }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            // Tracking areas need the hosting window to deliver ordinary pointer movement.
            window?.acceptsMouseMovedEvents = true
        }

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            if let area { removeTrackingArea(area) }
            let replacement = NSTrackingArea(rect: .zero,
                options: [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect],
                owner: self, userInfo: nil)
            addTrackingArea(replacement)
            area = replacement
        }

        override func mouseEntered(with event: NSEvent) { mouseMoved(with: event) }
        override func mouseMoved(with event: NSEvent) {
            guard !pinned else { return }
            pointer = convert(event.locationInWindow, from: nil)
            onMove?(pointer)
        }
        override func mouseExited(with event: NSEvent) { if !pinned { hidePopup(); onMove?(nil) } }
    }
}


/// Routes wheel events only within the visible Horizon card, leaving other views untouched.
struct HorizonWheelRouting: NSViewRepresentable {
    var onScroll: (Double) -> Void
    func makeNSView(context: Context) -> WheelView {
        let view = WheelView()
        view.onScroll = onScroll
        return view
    }
    func updateNSView(_ view: WheelView, context: Context) { view.onScroll = onScroll }
    static func dismantleNSView(_ view: WheelView, coordinator: ()) { view.stopMonitoring() }

    final class WheelView: NSView {
        var onScroll: ((Double) -> Void)?
        private var monitor: Any?
        private var timer: Timer?
        private var motion = HorizonWheelMotion()
        private var lastFrame = 0.0
        override func hitTest(_ point: NSPoint) -> NSView? { nil }
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            stopMonitoring()
            guard window != nil else { return }
            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                guard let self, let window = self.window,
                      event.window === window, window.attachedSheet == nil,
                      !self.isHiddenOrHasHiddenAncestor,
                      self.bounds.intersection(self.visibleRect).contains(self.convert(event.locationInWindow, from: nil)) else { return event }
                let delta = Self.horizontalDelta(x: event.scrollingDeltaX, y: event.scrollingDeltaY, precise: event.hasPreciseScrollingDeltas)
                if event.hasPreciseScrollingDeltas || NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
                    self.stopAnimation()
                    self.onScroll?(delta)
                } else {
                    self.motion.enqueue(delta)
                    self.startAnimation()
                }
                return nil
            }
        }
        private func startAnimation() {
            guard timer == nil else { return }
            lastFrame = ProcessInfo.processInfo.systemUptime
            let next = Timer(timeInterval: 1.0 / 120.0, target: self, selector: #selector(advanceScroll), userInfo: nil, repeats: true)
            timer = next
            RunLoop.main.add(next, forMode: .common)
        }
        @objc private func advanceScroll() {
            guard window != nil, !isHiddenOrHasHiddenAncestor else { stopAnimation(); return }
            let now = ProcessInfo.processInfo.systemUptime
            let delta = motion.step(seconds: now - lastFrame)
            lastFrame = now
            if delta != 0 { onScroll?(delta) }
            if motion.remaining == 0 { stopAnimation() }
        }
        private func stopAnimation() { timer?.invalidate(); timer = nil; motion.cancel() }
        func stopMonitoring() {
            stopAnimation()
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
        }
        static func horizontalDelta(x: Double, y: Double, precise: Bool) -> Double {
            // Keep native horizontal gestures; map vertical wheels to the same axis.
            -(abs(x) > abs(y) ? x : y) * (precise ? 1 : 20)
        }
    }
}
