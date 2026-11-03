import SwiftUI

struct HorizonView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.openSettings) private var openSettings
    @State private var viewport = HorizonViewport(now: .now, furthestFuture: nil, zone: TimeZone(identifier: "America/Chicago")!, width: 1000)
    @State private var position = ScrollPosition(x: 0)
    @State private var selectedEvent: HorizonEvent?
    @State private var selectedHistoricalMarker: HistoricalEventMarker?
    @State private var hoverText: String?
    @State private var hoveredSample: (account: ProviderAccount, point: HistoryPoint)?
    private var events: [HorizonEvent] { HorizonEvent.events(state: store.state, now: .now) }
    private var timelineAccounts: [ProviderAccount] { AccountPolicy.ordered(store.state, mode: .custom).filter(\.enabled) }
    var body: some View {
        ScroogeCard {
            VStack(spacing: 18) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 24) { heading; legend; historyToggle; Text("Scroll Left for History").font(.system(size: 12)).foregroundStyle(Theme.secondary); Spacer(); settingsButton }
                    VStack(alignment: .leading, spacing: 12) { HStack { heading; Spacer(); settingsButton }; HStack { legend; Spacer(); historyToggle } }
                }
                Divider().overlay(Theme.border)
                HStack(alignment: .top, spacing: 16) {
                    selectors.frame(width: 90)
                    Divider()
                    HStack(spacing: 0) {
                        if store.state.settings.historyEnabled { historyAxis.frame(width: 40) }
                        GeometryReader { geometry in
                            ScrollView(.horizontal) {
                                timeline.frame(width: viewport.contentWidth, height: timelineHeight)
                                    .background(HistoryPointerTracking(text: hoverText, onMove: updateHistoryHover))
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
                navigator.frame(height: 22)
                if let historyStatus {
                    Text(historyStatus).font(.callout).foregroundStyle(Theme.secondary)
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
        .sheet(item: $selectedEvent) { event in
            VStack(alignment: .leading, spacing: 16) {
                if event.reportedAt == nil {
                    ScrollView { AccountUsageDetailsView(accountID: event.account.id, windowID: event.windowID) }
                        .frame(width: 450, height: 370)
                } else {
                    Label(event.title, systemImage: event.expiration ? "hourglass" : "arrow.clockwise").font(.title2).foregroundStyle(event.expiration ? Theme.amber : Theme.accent)
                    Text("\(event.account.provider.rawValue) · \(store.state.settings.privacy ? "Account" : event.account.nickname)")
                    Text(Format.date(event.date, zone: store.state.settings.zone))
                    if let reportedAt = event.reportedAt {
                        Text("Reported \(Format.date(reportedAt, zone: store.state.settings.zone))").foregroundStyle(Theme.secondary)
                        Text("This is a reported schedule, not confirmation that capacity reset or a credit was redeemed.").font(.callout)
                    } else { Text(Format.countdown(event.date)).foregroundStyle(Theme.secondary) }
                }
                Button("Close") { selectedEvent = nil }.buttonStyle(ScroogeButtonStyle())
            }.padding(28).frame(minWidth: 400).background(Theme.card).preferredColorScheme(.dark)
        }
        .sheet(item: $selectedHistoricalMarker) { marker in historicalDetails(marker) }
    }
    private func historicalDetails(_ marker: HistoricalEventMarker) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("History Event").font(.title2)
            ScrollView {
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
            Button("Close") { selectedHistoricalMarker = nil }.buttonStyle(ScroogeButtonStyle())
        }.padding(24).frame(width: 500, height: 420).background(Theme.card).preferredColorScheme(.dark)
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
        return store.state.settings.historyEnabled ? max(selectors, future) : future
    }
    private var heading: some View { HStack { Image(systemName: "clock.arrow.circlepath").foregroundStyle(Theme.accent); Text("Reset Horizon").fontWeight(.semibold) }.font(.system(size: 24)) }
    private var historyStatus: String? {
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
        let series = UsageHistory.build(account: account, runs: store.history, from: viewport.firstDate, through: .now)
        let name = store.state.settings.privacy ? "Account" : account.nickname
        let period = account.provider == .copilot ? "Monthly" : "Weekly"
        var text = "\(account.provider.rawValue) / \(name) · \(Format.plan(account.provider, store.state.snapshots[account.id]?.planType))\n\(period) History"
        if let first = series.points.first, first.at > viewport.firstDate { text += "\nHistory Begins \(Format.date(first.at, zone: store.state.settings.zone))" }
        if let status = series.status { text += "\n\(status)" }
        return text
    }
    private var legend: some View {
        HStack(spacing: 36) {
            HStack(spacing: 8) { Circle().fill(Theme.accent).frame(width: 10, height: 10); Text("Quota Refresh (\(events.filter { !$0.expiration }.count))") }
            HStack(spacing: 8) { Circle().fill(Theme.amber).frame(width: 10, height: 10); Text("Reset Expires (\(events.filter(\.expiration).count))") }
        }.font(.system(size: 12)).foregroundStyle(Theme.secondary)
    }
    private var historyToggle: some View {
        HStack(spacing: 7) {
            Toggle("History", isOn: Binding(get: { store.state.settings.historyEnabled }, set: { store.setHistory($0) }))
                .labelsHidden().toggleStyle(.switch).controlSize(.small).fixedSize().accessibilityIdentifier("historyToggle")
            Text("History").font(.system(size: 12))
        }
    }
    private var settingsButton: some View { Button { openSettings() } label: { ActionLabel(title: "", symbol: "gearshape") }.buttonStyle(ScroogeButtonStyle()).help("Timeline Settings") }
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
            if store.state.settings.historyEnabled {
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
                    Text(dayName(date)).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.accent)
                    Text(date.formatted(Date.FormatStyle().month(.abbreviated).day().withTimeZone(store.state.settings.zone))).font(.system(size: 11)).foregroundStyle(Theme.secondary)
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
        .onChange(of: viewport.scrollOffset) { _, _ in hoverText = nil; hoveredSample = nil }
        .onChange(of: store.state.settings.privacy) { _, _ in hoverText = nil; hoveredSample = nil }
        .onChange(of: store.state.settings.hiddenHistoryAccounts) { _, _ in hoverText = nil; hoveredSample = nil }
        .onChange(of: timelineAccounts.map(\.id)) { _, _ in hoverText = nil; hoveredSample = nil }
    }
    private func updateHistoryHover(_ location: CGPoint?) {
        guard let location else { hoverText = nil; hoveredSample = nil; return }
        let date = viewport.date(at: location.x)
        func distance(_ point: HistoryPoint) -> Double {
            let x = viewport.position(at: point.at)
            let y = plotTop + NSDecimalNumber(decimal: point.remaining).doubleValue / 100 * plotHeight
            return abs(x - location.x) + abs(y - location.y) * 0.45
        }
        let nearest = historySeries.flatMap { series in series.points.filter { abs(viewport.position(at: $0.at) - location.x) <= 18 }.map { (series.account, $0) } }
            .min { distance($0.1) < distance($1.1) }
        let estimate = nearest == nil ? historySeries.compactMap { series in
            UsageHistory.estimatedPoint(points: series.points, x: location.x, y: location.y, viewport: viewport, plotTop: plotTop, plotHeight: plotHeight).map { (series.account, $0) }
        }.first : nil
        if store.state.settings.historyEnabled, date <= .now, (plotTop...plotBottom).contains(location.y), let (account, point) = nearest ?? estimate {
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
        } else { hoverText = nil; hoveredSample = nil }
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
                let markers = events + (store.state.settings.historyEnabled ? historicalEvents : [])
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
            let points = UsageHistory.reduce(series.points, project: viewport.position, minX: viewport.scrollOffset, maxX: viewport.scrollOffset + viewport.viewportWidth)
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
                let x = viewport.position(at: point.at)
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
            let x = viewport.position(at: sample.point.at)
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
            guard let point = series.points.last(where: { viewport.position(at: $0.at) >= viewport.scrollOffset && viewport.position(at: $0.at) <= viewport.scrollOffset + viewport.viewportWidth }) else { return nil }
            return (series, point)
        }.sorted { $0.1.remaining < $1.1.remaining }
        let desired = latest.map { plotTop + NSDecimalNumber(decimal: $0.1.remaining).doubleValue / 100 * chartHeight - 10 }
        let labels = HistoryLabelLayout.positions(desired, top: plotTop, bottom: plotTop + chartHeight - 21)
        for (index, item) in latest.enumerated() {
            let (series, point) = item
            let x = viewport.position(at: point.at)
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
            context.draw(Text("\(plan) \(Format.percent(100 - point.remaining))").font(.system(size: 11)).foregroundColor(color), at: CGPoint(x: rect.midX, y: rect.midY))
        }
    }
    private var historicalEvents: [HorizonEvent] {
        timelineAccounts.filter { !store.state.settings.hiddenHistoryAccounts.contains($0.id) }.flatMap {
            UsageHistory.events(account: $0, runs: store.history, from: viewport.firstDate, through: .now)
        }
    }
    private var historySeries: [UsageHistorySeries] {
        timelineAccounts.filter { !store.state.settings.hiddenHistoryAccounts.contains($0.id) }.map {
            UsageHistory.build(account: $0, runs: store.history, from: viewport.firstDate, through: .now)
        }
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
    var onMove: (CGPoint?) -> Void

    func makeNSView(context: Context) -> TrackingView {
        let view = TrackingView()
        view.onMove = onMove
        return view
    }

    func updateNSView(_ view: TrackingView, context: Context) {
        view.onMove = onMove
        view.showPopup(text)
    }
    static func dismantleNSView(_ view: TrackingView, coordinator: ()) { view.hidePopup() }

    final class TrackingView: NSView {
        var onMove: ((CGPoint?) -> Void)?
        private var area: NSTrackingArea?
        private var popup: NSPanel?
        private var pointer = NSPoint.zero
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
                    Text(lines[0]).font(.system(size: 14, weight: .semibold)).foregroundStyle(Theme.accent)
                    if lines.count > 1 { Text(lines[1]).font(.system(size: 12)).foregroundStyle(Theme.secondary) }
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
            pointer = convert(event.locationInWindow, from: nil)
            onMove?(pointer)
        }
        override func mouseExited(with event: NSEvent) { hidePopup(); onMove?(nil) }
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
                self.onScroll?(Self.horizontalDelta(x: event.scrollingDeltaX, y: event.scrollingDeltaY,
                                                    precise: event.hasPreciseScrollingDeltas))
                return nil
            }
        }
        func stopMonitoring() {
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
        }
        static func horizontalDelta(x: Double, y: Double, precise: Bool) -> Double {
            // Keep native horizontal gestures; map vertical wheels to the same axis.
            -(abs(x) > abs(y) ? x : y) * (precise ? 1 : 20)
        }
    }
}
