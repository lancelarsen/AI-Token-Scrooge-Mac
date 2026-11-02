import SwiftUI

struct HorizonView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.openSettings) private var openSettings
    @State private var viewport = HorizonViewport(now: .now, furthestFuture: nil, zone: TimeZone(identifier: "America/Chicago")!, width: 1000)
    @State private var position = ScrollPosition(x: 0)
    @State private var selectedEvent: HorizonEvent?
    @State private var hoverText: String?
    private var events: [HorizonEvent] { HorizonEvent.events(state: store.state, now: .now) }
    var body: some View {
        ScroogeCard {
            VStack(spacing: 18) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 24) { heading; legend; Spacer(); historyToggle; settingsButton }
                    VStack(alignment: .leading, spacing: 12) { HStack { heading; Spacer(); settingsButton }; HStack { legend; Spacer(); historyToggle } }
                }
                Divider().overlay(Theme.border)
                HStack(alignment: .top, spacing: 16) {
                    selectors.frame(width: 90)
                    Divider()
                    GeometryReader { geometry in
                        ScrollView(.horizontal) {
                            timeline.frame(width: viewport.contentWidth, height: timelineHeight)
                        }
                        .scrollIndicators(.hidden).scrollPosition($position)
                        .onScrollGeometryChange(for: Double.self) { $0.contentOffset.x } action: { _, value in if position.isPositionedByUser { viewport.scroll(to: value) } }
                        .onAppear { update(width: geometry.size.width) }
                        .onChange(of: geometry.size.width) { _, width in update(width: width) }
                        .onChange(of: store.state.settings.historyEnabled) { _, _ in update(width: geometry.size.width) }
                        .onChange(of: store.state.settings.timeZoneID) { _, _ in update(width: geometry.size.width) }
                        .onChange(of: events.map(\.date)) { _, _ in update(width: geometry.size.width) }
                    }
                }.frame(height: timelineHeight)
                navigator.frame(height: 22)
                if let hoverText { Text(hoverText).font(.caption).foregroundStyle(Theme.secondary).frame(maxWidth: .infinity, alignment: .leading) }
            }
        }
        .sheet(item: $selectedEvent) { event in
            VStack(alignment: .leading, spacing: 16) {
                Label(event.title, systemImage: event.expiration ? "hourglass" : "arrow.clockwise").font(.title2).foregroundStyle(event.expiration ? Theme.amber : Theme.accent)
                Text("\(event.account.provider.rawValue) · \(store.state.settings.privacy ? "Account" : event.account.nickname)")
                Text(Format.date(event.date, zone: store.state.settings.zone))
                if let reportedAt = event.reportedAt {
                    Text("Reported \(Format.date(reportedAt, zone: store.state.settings.zone))").foregroundStyle(Theme.secondary)
                    Text("This is a reported schedule, not confirmation that capacity reset or a credit was redeemed.").font(.callout)
                } else { Text(Format.countdown(event.date)).foregroundStyle(Theme.secondary) }
                Button("Close") { selectedEvent = nil }.buttonStyle(ScroogeButtonStyle())
            }.padding(28).frame(minWidth: 400).background(Theme.card).preferredColorScheme(.dark)
        }
    }
    private var timelineHeight: Double {
        let groups = Dictionary(grouping: events, by: { calendar.startOfDay(for: $0.date) })
        let accounts = max(3, store.state.accounts.count)
        let selectors = 16 + Double(accounts * 66 + (accounts - 1) * 6)
        let future = 56 + 21 + Double(max(1, groups.values.map(\.count).max() ?? 0)) * 76
        return store.state.settings.historyEnabled ? max(selectors, future) : future
    }
    private var heading: some View { HStack { Image(systemName: "clock.arrow.circlepath").foregroundStyle(Theme.accent); Text("Reset Horizon").fontWeight(.semibold) }.font(.system(size: 24)) }
    private var legend: some View {
        HStack(spacing: 22) {
            Label("Quota Refresh (\(events.filter { !$0.expiration }.count))", systemImage: "circle.fill").foregroundStyle(Theme.accent)
            Label("Reset Expires (\(events.filter(\.expiration).count))", systemImage: "circle.fill").foregroundStyle(Theme.amber)
        }.font(.system(size: 12))
    }
    private var historyToggle: some View {
        Toggle("History", isOn: Binding(get: { store.state.settings.historyEnabled }, set: { store.setHistory($0) }))
            .toggleStyle(.switch).fixedSize().accessibilityIdentifier("historyToggle")
    }
    private var settingsButton: some View { Button { openSettings() } label: { ActionLabel(title: "", symbol: "gearshape") }.buttonStyle(ScroogeButtonStyle()).help("Timeline Settings") }
    private var selectors: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(store.state.accounts) { account in
                    Button { store.toggleAccountHistory(account.id) } label: {
                        VStack(spacing: 1) {
                            Text(store.state.settings.privacy ? "Account" : account.nickname).font(.system(size: 10)).lineLimit(1)
                            ProviderIcon(provider: account.provider, size: 29)
                            HStack(spacing: 4) {
                                Text(store.state.snapshots[account.id]?.planType ?? "Unknown").font(.system(size: 10))
                                Image(systemName: store.state.settings.hiddenHistoryAccounts.contains(account.id) ? "square" : "checkmark.square.fill")
                            }
                        }.padding(5).frame(width: 72).background(Theme.control)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: account.resolvedLineColor(plan: store.state.snapshots[account.id]?.planType)), lineWidth: 2))
                            .opacity(store.state.settings.hiddenHistoryAccounts.contains(account.id) ? 0.4 : 1)
                    }.buttonStyle(.plain).accessibilityLabel("Show \(account.provider.rawValue) \(account.nickname) on Timeline")
                }
            }
        }.scrollIndicators(.hidden)
    }
    private var timeline: some View {
        ZStack(alignment: .topLeading) {
            Canvas { context, size in
                var rail = Path(); rail.move(to: CGPoint(x: 0, y: 56)); rail.addLine(to: CGPoint(x: size.width, y: 56))
                context.stroke(rail, with: .color(Theme.accent.opacity(0.7)), lineWidth: 2)
                if store.state.settings.historyEnabled { drawHistory(context: &context, size: size) }
            }
            if store.state.settings.historyEnabled {
                ForEach(historicalEvents) { event in
                    Button { selectedEvent = event } label: {
                        Image(systemName: event.expiration ? "hourglass" : "arrow.clockwise")
                            .font(.system(size: 11, weight: .semibold)).foregroundStyle(Theme.card)
                            .frame(width: 22, height: 22).background(event.expiration ? Theme.amber : Theme.accent).clipShape(Circle())
                    }.buttonStyle(.plain).position(x: viewport.position(at: event.date), y: event.expiration ? 83 : 60)
                        .help("\(event.title) · \(Format.date(event.date, zone: store.state.settings.zone))")
                }
            }
            ForEach(days, id: \.self) { date in
                VStack(spacing: 8) {
                    Text(dayName(date)).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.accent)
                    Text(date.formatted(Date.FormatStyle().month(.abbreviated).day().withTimeZone(store.state.settings.zone))).font(.system(size: 11)).foregroundStyle(Theme.secondary)
                    Circle().fill(isToday(date) ? Theme.accent : Theme.card).frame(width: isToday(date) ? 15 : 8, height: isToday(date) ? 15 : 8)
                        .overlay(Circle().stroke(Theme.accent, lineWidth: 2))
                }.frame(width: viewport.pixelsPerDay, height: 70, alignment: .top)
                    .position(x: viewport.dayAnchor(date), y: 35)
                let dayEvents = events.filter { calendar.isDate($0.date, inSameDayAs: date) }
                ForEach(Array(dayEvents.enumerated()), id: \.element.id) { index, event in
                    Button { selectedEvent = event } label: {
                        VStack(spacing: 2) {
                            ProviderIcon(provider: event.account.provider, size: 28)
                            Text(event.plan ?? "Unknown").font(.system(size: 9)).lineLimit(1)
                            Text(event.date.formatted(Date.FormatStyle(date: .omitted, time: .shortened).withTimeZone(store.state.settings.zone))).font(.system(size: 9))
                        }.frame(width: 54, height: 63).background(event.expiration ? Theme.amber.opacity(0.15) : Theme.accent.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(event.expiration ? Theme.amber : Theme.accent, lineWidth: 2))
                    }.buttonStyle(.plain).position(x: viewport.dayAnchor(date), y: CGFloat(104 + index * 75))
                        .help("\(event.title) · \(Format.date(event.date, zone: store.state.settings.zone))")
                }
            }
        }.contentShape(Rectangle())
        .onContinuousHover { phase in
            switch phase {
            case .active(let location):
                let date = viewport.date(at: location.x)
                func distance(_ point: HistoryPoint) -> Double {
                    let x = viewport.position(at: point.at)
                    let y = 95 + NSDecimalNumber(decimal: point.remaining).doubleValue / 100 * 200
                    return abs(x - location.x) + abs(y - location.y) * 0.45
                }
                let nearest = historySeries.flatMap { series in series.points.filter { abs(viewport.position(at: $0.at) - location.x) <= 18 }.map { (series.account, $0) } }
                    .min { distance($0.1) < distance($1.1) }
                let estimate = nearest == nil ? historySeries.compactMap { series in
                    UsageHistory.estimatedPoint(points: series.points, x: location.x, y: location.y, viewport: viewport).map { (series.account, $0) }
                }.first : nil
                if store.state.settings.historyEnabled, date <= .now, (95...295).contains(location.y), let (account, point) = nearest ?? estimate {
                    hoverText = "\(store.state.settings.privacy ? "Account" : account.nickname) · \(Format.percent(100 - point.remaining)) Used · \(Format.date(point.at, zone: store.state.settings.zone))" + (point.estimated ? " · Estimated Linear Connection From Previous Observation" : "")
                } else { hoverText = Format.date(date, zone: store.state.settings.zone) }
            case .ended: hoverText = nil
            }
        }
    }
    private var navigator: some View {
        GeometryReader { geometry in
            let overview = viewport.overview(trackWidth: geometry.size.width)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 5).fill(Theme.control).overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.border))
                ForEach(events) { event in
                    Circle().fill(event.expiration ? Theme.amber : Theme.accent).frame(width: 4, height: 4)
                        .offset(x: viewport.position(at: event.date) / viewport.contentWidth * geometry.size.width)
                }
                RoundedRectangle(cornerRadius: 5).fill(Theme.accent.opacity(0.25))
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.accent))
                    .frame(width: max(1, overview.width)).offset(x: overview.left)
            }.contentShape(Rectangle()).gesture(DragGesture(minimumDistance: 0).onChanged { value in
                viewport.centerFromOverview(pointerX: value.location.x, trackWidth: geometry.size.width)
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
        let chartHeight = 200.0
        for percent in stride(from: 0, through: 100, by: 25) {
            let y = 95 + (1 - Double(percent) / 100) * chartHeight
            var line = Path(); line.move(to: CGPoint(x: 0, y: y)); line.addLine(to: CGPoint(x: max(0, nowX), y: y))
            context.stroke(line, with: .color(Theme.border.opacity(0.6)), lineWidth: 1)
        }
        for event in historicalEvents {
            let x = viewport.position(at: event.date)
            var marker = Path(); marker.move(to: CGPoint(x: x, y: 95)); marker.addLine(to: CGPoint(x: x, y: 95 + chartHeight))
            context.stroke(marker, with: .color((event.expiration ? Theme.amber : Theme.accent).opacity(0.6)), style: StrokeStyle(lineWidth: 1, dash: [4,4]))
        }
        for series in historySeries {
            let points = UsageHistory.reduce(series.points, project: viewport.position, minX: viewport.scrollOffset, maxX: viewport.scrollOffset + viewport.viewportWidth)
            let color = Color(hex: series.account.resolvedLineColor(plan: store.state.snapshots[series.account.id]?.planType))
            var segment: [CGPoint] = []
            func flush() {
                guard let first = segment.first, let last = segment.last else { return }
                var path = Path(); path.addLines(segment)
                var fill = Path(); fill.move(to: CGPoint(x: first.x, y: 95 + chartHeight))
                fill.addLines(segment); fill.addLine(to: CGPoint(x: last.x, y: 95 + chartHeight)); fill.closeSubpath()
                context.fill(fill, with: .color(color.opacity(0.09)))
                context.stroke(path, with: .color(color), lineWidth: 2)
                if segment.count == 1 { context.fill(Path(ellipseIn: CGRect(x: first.x - 2.5, y: first.y - 2.5, width: 5, height: 5)), with: .color(color)) }
                segment.removeAll()
            }
            for point in points {
                if point.startsSegment { flush() }
                let x = viewport.position(at: point.at)
                if let before = point.replenishedFrom, !segment.isEmpty {
                    segment.append(CGPoint(x: x, y: 95 + NSDecimalNumber(decimal: before).doubleValue / 100 * chartHeight))
                }
                segment.append(CGPoint(x: x, y: 95 + NSDecimalNumber(decimal: point.remaining).doubleValue / 100 * chartHeight))
            }
            flush()
        }
        let latest = historySeries.compactMap { series -> (UsageHistorySeries, HistoryPoint)? in
            guard let point = series.points.last(where: { viewport.position(at: $0.at) >= viewport.scrollOffset && viewport.position(at: $0.at) <= viewport.scrollOffset + viewport.viewportWidth }) else { return nil }
            return (series, point)
        }.sorted { $0.1.remaining < $1.1.remaining }
        let desired = latest.map { 95 + NSDecimalNumber(decimal: $0.1.remaining).doubleValue / 100 * chartHeight - 10 }
        let labels = HistoryLabelLayout.positions(desired, top: 95, bottom: 95 + chartHeight - 21)
        for (index, item) in latest.enumerated() {
            let (series, point) = item
            let x = viewport.position(at: point.at)
            guard x >= viewport.scrollOffset, x <= viewport.scrollOffset + viewport.viewportWidth else { continue }
            let color = Color(hex: series.account.resolvedLineColor(plan: store.state.snapshots[series.account.id]?.planType))
            let y = 95 + NSDecimalNumber(decimal: point.remaining).doubleValue / 100 * chartHeight
            let end = viewport.scrollOffset + viewport.viewportWidth
            guard nowX >= end - 80, x >= end - 70 else { continue }
            let labelX = end - 86, labelY = labels[index]
            var connector = Path(); connector.move(to: CGPoint(x: x - 4, y: y)); connector.addLine(to: CGPoint(x: labelX + 80, y: labelY + 10))
            context.stroke(connector, with: .color(color.opacity(0.6)), lineWidth: 1)
            context.fill(Path(ellipseIn: CGRect(x: x - 3, y: y - 3, width: 6, height: 6)), with: .color(color))
            let rect = CGRect(x: labelX, y: labelY, width: 80, height: 21)
            context.fill(Path(roundedRect: rect, cornerRadius: 6), with: .color(Theme.card))
            context.stroke(Path(roundedRect: rect, cornerRadius: 6), with: .color(color.opacity(0.7)), lineWidth: 1)
            let plan = store.state.snapshots[series.account.id]?.planType ?? "Unknown"
            context.draw(Text("\(plan) \(Format.percent(100 - point.remaining))").font(.system(size: 11)).foregroundColor(color), at: CGPoint(x: rect.midX, y: rect.midY))
        }
    }
    private var historicalEvents: [HorizonEvent] {
        store.state.accounts.filter { !store.state.settings.hiddenHistoryAccounts.contains($0.id) }.flatMap {
            UsageHistory.events(account: $0, runs: store.history, from: viewport.firstDate, through: .now)
        }
    }
    private var historySeries: [UsageHistorySeries] {
        store.state.accounts.filter { !store.state.settings.hiddenHistoryAccounts.contains($0.id) }.map {
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
        viewport.update(now: .now, furthestFuture: events.map(\.date).max(), zone: store.state.settings.zone, width: width, historyEnabled: store.state.settings.historyEnabled)
        position.scrollTo(x: viewport.scrollOffset)
    }
}

private extension Date.FormatStyle {
    func withTimeZone(_ zone: TimeZone) -> Self { var style = self; style.timeZone = zone; return style }
}
