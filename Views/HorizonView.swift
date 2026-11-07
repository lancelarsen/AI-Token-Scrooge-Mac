import SwiftUI

struct HorizonView: View {
    @Environment(AppStore.self) private var store
    let openSettings: () -> Void
    @State private var timelineWidth: CGFloat = 1000
    @State private var viewport = HorizonViewport(now: .now, furthestFuture: nil, zone: TimeZone(identifier: "America/Chicago")!, width: 1000)
    @State private var position = ScrollPosition(x: 0)
    @State private var selectedEvent: HorizonEvent?
    @State private var selectedHistoricalMarker: HistoricalEventMarker?
    @State private var presentation = HorizonPresentation()
    @State private var historyPinned = false
    @FocusState private var historyFocused: Bool
    @State private var navigatorDragOffset: Double?
    @State private var hoverText: String?
    @State private var hoveredSample: (account: ProviderAccount, point: HistoryPoint)?
    private var now: Date { store.presentationDate }
    private var events: [HorizonEvent] { HorizonEvent.events(state: store.state, now: now) }
    private var earliestRecordedHistory: Date? { presentation.series.compactMap { $0.points.first?.at }.min() }
    private var timelineAccounts: [ProviderAccount] { AccountPolicy.ordered(store.state, mode: .custom).filter(\.enabled) }
    var body: some View {
        ScroogeCard(inset: 0) {
            VStack(spacing: 16) {
                HStack(alignment: .top, spacing: 8) {
                    HorizonHeaderFlow {
                        heading.padding(.trailing, 44)
                        legends
                        historyToggle.padding(.trailing, 36)
                        historyHint
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    settingsButton.fixedSize()
                }
                .padding(.leading, 12)
                Divider().overlay(Theme.border).padding(.horizontal, 12)
                if store.state.accounts.isEmpty {
                    emptyTimeline
                } else {
                HStack(alignment: .top, spacing: 10) {
                    HStack(spacing: 0) {
                        selectors
                        Rectangle().fill(Theme.border).frame(width: 1).padding(.vertical, 6)
                    }.frame(width: timelineWidth < 850 ? 95 : 112)
                    HStack(spacing: 0) {
                        historyAxis.frame(width: 40).opacity(store.state.settings.historyEnabled ? 1 : 0)
                        GeometryReader { geometry in
                            ScrollView(.horizontal) {
                                timeline.frame(width: viewport.contentWidth, height: timelineHeight)
                                    .background(HistoryPointerTracking(text: hoverText, pinned: historyPinned, anchor: historyPinned ? sampleAnchor : nil) { point in
                                        if let point {
                                            if !historyPinned { updateHistoryHover(point) }
                                        } else {
                                            clearHistorySample()
                                        }
                                    })
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
                    .overlay(alignment: .topLeading) { dateHeadings }
                }.frame(height: timelineHeight)
                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { timelineWidth = $0 }
                }
                if store.state.accounts.isEmpty {
                    RoundedRectangle(cornerRadius: 5).fill(Theme.activeControl)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(Theme.accent))
                        .overlay {
                            Canvas { context, size in
                                drawNavigatorGrip(in: &context, centerX: size.width / 2)
                            }
                            .accessibilityHidden(true)
                        }
                        .frame(height: 22)
                } else { navigator.frame(height: 22) }
                if let historyStatus {
                    Text(historyStatus).font(.reference(size: 13)).foregroundStyle(Theme.secondary)
                        .frame(maxWidth: .infinity).accessibilityIdentifier("historyStatus")
                }
            }.padding(.horizontal, 12).padding(.vertical, 18)
        }
        .background {
            GeometryReader { geometry in
                HorizonWheelRouting { delta in
                    if historyPinned || hoverText != nil { clearHistorySample() }
                    viewport.scroll(to: viewport.scrollOffset + delta)
                    position.scrollTo(x: viewport.scrollOffset)
                }.frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .onAppear { prepareHistory() }
        .onChange(of: earliestRecordedHistory) { _, _ in update(width: viewport.viewportWidth) }
        .onChange(of: store.historyRevision) { _, _ in prepareHistory() }
        .onChange(of: timelineAccounts) { _, _ in prepareHistory() }
        .onChange(of: viewport.startCoordinate) { _, _ in prepareHistory() }
        .onChange(of: viewport.pixelsPerDay) { _, _ in prepareHistory() }
        .onChange(of: store.state.settings.timeZoneID) { _, _ in prepareHistory() }
        .sheet(item: $selectedEvent) { event in
            if event.reportedAt == nil {
                AccountUsageDialog(accountID: event.account.id, windowID: event.windowID, close: { selectedEvent = nil })
            } else {
                DetailsDialog(title: event.title, close: { selectedEvent = nil }) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(event.account.provider.rawValue) · \(store.state.settings.privacy ? "Account" : event.account.nickname)")
                        Text(Format.date(event.date, zone: store.state.settings.zone))
                        if let reportedAt = event.reportedAt {
                            Text("Reported \(Format.date(reportedAt, zone: store.state.settings.zone))").foregroundStyle(Theme.secondary)
                            Text("This is a reported schedule, not confirmation that capacity reset or a credit was redeemed.").font(.reference(size: 14))
                        }
                    }
                }
            }
        }
        .sheet(item: $selectedHistoricalMarker) { marker in historicalDetails(marker) }
    }
    private func historicalTooltip(_ marker: HistoricalEventMarker) -> String {
        marker.events.map { event in
            let account = "\(event.account.provider.rawValue) / \(store.state.settings.privacy ? "Account" : event.account.nickname) · \(Format.plan(event.account.provider, event.plan))"
            let kind = event.expiration ? "Reset Expiration" : "Quota Refresh"
            return "\(account)\n\(kind): \(Format.date(event.date, zone: store.state.settings.zone))\n\(event.title)"
        }.joined(separator: "\n\n")
    }
    private func historicalDetails(_ marker: HistoricalEventMarker) -> some View {
        DetailsDialog(title: "History Event", close: { selectedHistoricalMarker = nil }) {
            DialogMessage(message: historicalTooltip(marker))
        }
    }
    private var emptyTimeline: some View {
        GeometryReader { geometry in
            let compact = geometry.size.width < 850
            let left: CGFloat = 40
            let anchor = left + (compact ? 38 : 88)
            HStack(spacing: 10) {
                HStack(spacing: 0) {
                    Color.clear
                    Rectangle().fill(Theme.border).frame(width: 1).padding(.vertical, 6)
                }.frame(width: compact ? 95 : 112)
                Canvas { context, size in
                    var rail = Path()
                    rail.move(to: CGPoint(x: left, y: 56))
                    // Windows HistoryTimelineView reserves PlotRight = 12 beyond the rail.
                    rail.addLine(to: CGPoint(x: max(left, size.width - 12), y: 56))
                    context.stroke(rail, with: .color(Color(hex: "#8170B7")), lineWidth: 2)
                    context.fill(Path(ellipseIn: CGRect(x: anchor - 8, y: 48, width: 16, height: 16)), with: .color(Color(hex: "#D1BEFF")))
                    if store.state.settings.historyEnabled {
                        var boundary = Path()
                        boundary.move(to: CGPoint(x: left, y: 88))
                        boundary.addLine(to: CGPoint(x: left, y: size.height - 4))
                        context.stroke(boundary, with: .color(Theme.accent), style: StrokeStyle(lineWidth: 2, dash: [5, 4]))
                    }
                }.overlay(alignment: .topLeading) {
                    dayHeading(now).frame(height: 40, alignment: .top)
                        .position(x: anchor, y: 20)
                        .allowsHitTesting(false).accessibilityHidden(true)
                }.accessibilityLabel("Today. No connected accounts or upcoming events.")
            }
        }.frame(height: 216)
    }
    private var plotTop: Double { 56 + 32 }
    private var plotBottom: Double { timelineHeight - 8 }
    private var plotHeight: Double { max(1, plotBottom - plotTop) }
    private var historyAxis: some View {
        Canvas { context, _ in
            guard viewport.position(at: now) - viewport.scrollOffset > 2 else { return }
            for percent in stride(from: 0, through: 100, by: 25) {
                let y = plotTop + (1 - Double(percent) / 100) * plotHeight
                context.draw(Text("\(percent)%").font(.reference(size: 11)).foregroundStyle(Theme.dialogText),
                             at: CGPoint(x: 38, y: y), anchor: .trailing)
            }
            context.translateBy(x: 5, y: (plotTop + plotBottom) / 2)
            context.rotate(by: .degrees(-90))
            context.draw(Text("% Used").font(.reference(size: 10)).foregroundStyle(Theme.dialogText), at: .zero)
        }.accessibilityLabel("History axis: zero to one hundred percent used")
    }
    private var timelineHeight: Double {
        let groups = Dictionary(grouping: events, by: { calendar.startOfDay(for: $0.date) })
        let accounts = max(3, store.state.accounts.filter(\.enabled).count)
        let selectors = 16 + Double(accounts * 66 + (accounts - 1) * 6)
        let future = 56 + 21 + Double(max(1, groups.values.map(\.count).max() ?? 0)) * 76
        return max(selectors, future)
    }
    private var heading: some View { HStack(spacing: 12) { ActionIcon(symbol: "clock.arrow.circlepath", size: 30); Text("Reset Horizon").font(.reference(size: 26, weight: .semibold)).referenceFallbackLineMetrics(size: 26) } }
    private var historyStatus: String? {
        guard !store.state.accounts.isEmpty else { return nil }
        if !store.state.settings.historyEnabled { return events.isEmpty ? "No Upcoming Events Reported" : nil }
        guard viewport.visibleStart < now else { return nil }
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
        var text = "\(account.provider.rawValue) / \(name) · \(Format.plan(account.provider, store.state.snapshots[account.id]?.planType))\nShow or Hide History, Resets and Refreshes"
        if let first = series?.points.first, viewport.position(at: first.at) > 0 { text += "\nHistory Begins \(Format.date(first.at, zone: store.state.settings.zone))" }
        if let status = series?.status { text += "\n\(status)" }
        return text
    }
    @ViewBuilder private var legends: some View {
        let visible = timelineAccounts.filter { !store.state.settings.hiddenHistoryAccounts.contains($0.id) }
        let partialRefresh = visible.contains { account in
            guard account.provider == .codex || account.provider == .claude else { return false }
            guard let snapshot = store.state.snapshots[account.id], snapshot.belongs(to: account) else { return true }
            return !snapshot.missingWindowNames(for: account.provider).isEmpty || snapshot.windows.contains { $0.resetsAt == nil }
        }
        let partialExpiry = visible.contains { account in
            if account.provider == .claude { return true } // Claude /usage omits earned resets.
            guard account.provider == .codex else { return false }
            guard let snapshot = store.state.snapshots[account.id], snapshot.belongs(to: account) else { return true }
            return snapshot.expirationDatesIncomplete
        }
        let refresh = HorizonEvent.legendCount(events.filter { !$0.expiration }.count, incomplete: partialRefresh)
        let expiry = HorizonEvent.legendCount(events.filter(\.expiration).count, incomplete: partialExpiry)
        HStack(spacing: 7) { Circle().fill(Theme.actionAccent).frame(width: 10, height: 10); Text("Quota Refresh (\(refresh))") }
            .font(.reference(size: 13)).foregroundStyle(Theme.dialogText).padding(.trailing, 40)
        HStack(spacing: 7) { Circle().fill(Theme.amber).frame(width: 10, height: 10); Text("Reset Expires (\(expiry))") }
            .font(.reference(size: 13)).foregroundStyle(Theme.dialogText).padding(.trailing, 40)
    }
    private var historyHint: some View {
        Text(store.state.settings.historyEnabled ? "Scroll Left for History" : "Select Services to Filter Timeline")
            .font(.reference(size: 13)).foregroundStyle(Theme.dialogText)
            .padding(.vertical, 8)
    }
    private var historyToggle: some View {
        HStack(spacing: 7) {
            Toggle("History", isOn: Binding(get: { store.state.settings.historyEnabled }, set: { store.setHistory($0) }))
                .toggleStyle(ScroogeSwitchStyle(showsLabel: false, onColor: Color(hex: "#8670CC"), thumbColor: Color(hex: "#D1BEFF"))).frame(width: 40, height: 20).accessibilityLabel("History").accessibilityIdentifier("historyToggle")
            Text("History").font(.reference(size: 13))
        }
    }
    private var settingsButton: some View { Button(action: openSettings) { ActionLabel(title: "", symbol: "gearshape") }.buttonStyle(ScroogeButtonStyle(horizontalPadding: 12)).modifier(ImmediateReferenceTooltip(text: "Earned Reset Alert Settings"))
        .accessibilityLabel("Earned Reset Alert Settings") }
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
                                .padding(.horizontal, 4).padding(.vertical, 10).opacity(enabled ? 1 : 0.5)
                            VStack {
                                selectorBadge(store.state.settings.privacy ? "Account" : account.nickname, size: 11, accent: accent, enabled: enabled)
                                Spacer(minLength: 0)
                                HStack(alignment: .bottom, spacing: 0) {
                                    selectorBadge(Format.historyPlanBadge(account.provider, store.state.snapshots[account.id]?.planType), size: 10, accent: accent, enabled: enabled)
                                    Spacer(minLength: 0)
                                    ZStack {
                                        if enabled {
                                            Path { path in
                                                path.move(to: CGPoint(x: 1, y: 6))
                                                path.addLine(to: CGPoint(x: 4.5, y: 9.5))
                                                path.addLine(to: CGPoint(x: 11, y: 2.5))
                                            }
                                            .stroke(.white, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                                            .frame(width: 12, height: 12)
                                        }
                                    }
                                        .frame(width: 19, height: 19)
                                        .background(enabled ? accent : Theme.control)
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(accent, lineWidth: 1.5))
                                }
                            }
                        }.frame(width: 82, height: 66).contentShape(Rectangle())
                    }.buttonStyle(.plain)
                        .accessibilityIdentifier("timelineAccount-\(account.id)")
                        .accessibilityLabel("\(store.state.settings.hiddenHistoryAccounts.contains(account.id) ? "Show" : "Hide") \(account.provider.rawValue) / \(store.state.settings.privacy ? "Account" : account.nickname) · \(Format.plan(account.provider, store.state.snapshots[account.id]?.planType)) · Timeline")
                        .modifier(ImmediateReferenceTooltip(text: historyHelp(account)))
                }
            }.padding(.leading, 3).padding(.trailing, 10).padding(.top, 8)
                .frame(maxWidth: .infinity)
        }.scrollIndicators(.hidden)
    }
    private func selectorBadge(_ text: String, size: CGFloat, accent: Color, enabled: Bool) -> some View {
        Text(text).font(.reference(size: size)).lineLimit(1).foregroundStyle(enabled ? .white : Color(hex: "#919195"))
            .padding(.horizontal, 5).padding(.vertical, 2).background(Theme.control)
            .clipShape(RoundedRectangle(cornerRadius: 7))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(accent.opacity(enabled ? 1 : 0.5), lineWidth: 1.5))
    }
    private func eventTooltip(_ event: HorizonEvent) -> String {
        let account = "\(event.account.provider.rawValue) / \(store.state.settings.privacy ? "Account" : event.account.nickname) · \(Format.plan(event.account.provider, event.plan))"
        let first = event.expiration ? "Earned Reset Expires" : account
        let detail = event.expiration ? account : event.title
        return "\(first)\n\(detail)\n\(event.expiration ? "Reset Expires" : "Quota Refresh"): \(Format.date(event.date, zone: store.state.settings.zone))"
    }
    private func eventCountdownContext(_ event: HorizonEvent) -> String {
        let account = "\(event.account.provider.rawValue) / \(store.state.settings.privacy ? "Account" : event.account.nickname) · \(Format.plan(event.account.provider, event.plan))"
        return event.expiration ? "Earned Reset Expires\n\(account)" : "\(account)\nQuota Refresh · \(event.title)"
    }
    private func dayHeading(_ date: Date) -> some View {
        VStack(spacing: 7) {
            Text(dayName(date)).font(.reference(size: 14, weight: .semibold))
                .foregroundStyle(isToday(date) ? Color(hex: "#D1BEFF") : Theme.actionAccent)
                .referenceFallbackLineMetrics(size: 14)
            Text(date.formatted(Date.FormatStyle().month(.abbreviated).day().withTimeZone(store.state.settings.zone)))
                .font(.reference(size: 12)).foregroundStyle(Theme.dialogText)
        }
    }
    private var dateHeadings: some View {
        GeometryReader { _ in
            ZStack(alignment: .topLeading) {
                ForEach(days.filter { date in
                    let anchor = viewport.dayAnchor(date) - viewport.scrollOffset
                    return date <= calendar.startOfDay(for: viewport.lastEventAt) &&
                        anchor >= 0 && anchor <= viewport.viewportWidth
                }, id: \.self) { date in
                    dayHeading(date).frame(width: viewport.pixelsPerDay, height: 40, alignment: .top)
                        .position(x: 40 + viewport.dayAnchor(date) - viewport.scrollOffset, y: 20)
                }
            }
        }
        .frame(height: 40)
        .clipped()
        .allowsHitTesting(false)
    }

    private var timeline: some View {
        ZStack(alignment: .topLeading) {
            Canvas { context, size in
                var rail = Path(); rail.move(to: CGPoint(x: 0, y: 56)); rail.addLine(to: CGPoint(x: size.width, y: 56))
                context.stroke(rail, with: .color(Color(hex: "#8170B7")), lineWidth: 2)
                if store.state.settings.historyEnabled { drawHistory(context: &context, size: size) }
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                historyPinned = false
                updateHistoryHover(location)
                historyPinned = hoverText != nil
            }
            .focusable()
            .focused($historyFocused)
            .focusEffectDisabled()
            .onChange(of: historyFocused) { _, focused in
                if !focused {
                    clearHistorySample()
                } else if let event = NSApp.currentEvent, event.type == .keyDown, event.keyCode == 48 {
                    // Tab and Shift-Tab inspect the latest visible observation.
                    // Focus restored after rebuilding a selector has no keyboard readout.
                    inspectSample(direction: 0)
                }
            }
            .accessibilityLabel("Usage history. Use arrow keys to inspect samples; Page Up and Page Down move seven days; Home returns to today; Escape dismisses details.")
            .accessibilityValue(hoverText ?? "No sample selected")
            .onKeyPress(.leftArrow) { inspectSample(direction: -1); return .handled }
            .onKeyPress(.rightArrow) { inspectSample(direction: 1); return .handled }
            .onKeyPress(.upArrow) { inspectSample(direction: -1); return .handled }
            .onKeyPress(.downArrow) { inspectSample(direction: 1); return .handled }
            .onKeyPress(.pageUp) { panHistory(days: -7); return .handled }
            .onKeyPress(.pageDown) { panHistory(days: 7); return .handled }
            .onKeyPress(.home) { returnToToday(); return .handled }
            .onKeyPress(.return) { inspectSample(direction: 0); return .handled }
            .onKeyPress(.space) { inspectSample(direction: 0); return .handled }
            .onKeyPress(.escape) { clearHistorySample(); return .handled }

            ForEach(days.filter { $0 <= calendar.startOfDay(for: viewport.lastEventAt) }, id: \.self) { date in
                let dayEvents = events.filter { calendar.isDate($0.date, inSameDayAs: date) }

                Circle()
                    .fill(isToday(date) ? Color(hex: "#D1BEFF") : dayEvents.isEmpty ? Color(hex: "#1C1E24") : Theme.actionAccent)
                    .frame(width: isToday(date) ? 16 : 10, height: isToday(date) ? 16 : 10)
                    .overlay {
                        if !isToday(date), dayEvents.isEmpty {
                            Circle().strokeBorder(Theme.actionAccent, lineWidth: 2)
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
                                    // Windows badges disambiguate enabled accounts from the same provider.
                                    if store.state.accounts.filter({ $0.enabled && $0.provider == event.account.provider }).count > 1 {
                                        Text(plan == "Plan Unavailable" ? "?" : plan)
                                            .font(.reference(size: 10, weight: .semibold)).lineLimit(1)
                                            .referenceFallbackLineMetrics(size: 10)
                                            .padding(.horizontal, 5).padding(.vertical, 1).padding(1)
                                            .background(Color(hex: "#1C1E24"))
                                            .clipShape(RoundedRectangle(cornerRadius: 6))
                                            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(accent, lineWidth: 1))
                                    }
                                }
                            Text(event.date.formatted(Date.FormatStyle(date: .omitted, time: .shortened).withTimeZone(store.state.settings.zone))).font(.reference(size: 10))
                        }.foregroundStyle(accent).frame(width: 62, height: 74, alignment: .top)
                            .contentShape(Rectangle())
                    }.buttonStyle(.plain)
                        .modifier(ImmediateResetTooltip(context: eventCountdownContext(event), date: event.date,
                            zone: store.state.settings.zone, accessibilityText: eventTooltip(event),
                            referenceDate: store.isDemo ? now : nil, isExpiry: event.expiration))
                        .position(x: viewport.dayAnchor(date), y: CGFloat(114 + index * 76))
                }
            }
            // Match Windows: historical markers paint over the day dots and rail.
            Group {
                ForEach(HistoricalEventMarker.layout(events: historicalEvents, viewport: viewport, now: now)) { marker in
                    Button { selectedHistoricalMarker = marker } label: {
                        Group {
                            if marker.events.count > 1 {
                                Text(String(marker.events.count)).font(.reference(size: 14, weight: .semibold))
                            } else {
                                Text(marker.expiration ? "\u{E823}" : "\u{E72C}")
                                    .font(ReferenceTypography.iconFont(size: 14))
                            }
                        }.foregroundStyle(Theme.control)
                            .frame(width: 22, height: 22).background(marker.expiration ? Theme.amber : Color(hex: "#B99AF8")).clipShape(Circle())
                    }.buttonStyle(.plain)
                        .modifier(ImmediateReferenceTooltip(text: historicalTooltip(marker)))
                        .position(x: marker.x, y: Double(56 + marker.lane * 24))
                }
            }
        }.contentShape(Rectangle())
        .onChange(of: viewport.scrollOffset) { _, _ in clearHistorySample() }
        .onChange(of: store.state.settings.historyEnabled) { _, _ in clearHistorySample() }
        .onChange(of: store.state.settings.privacy) { _, _ in clearHistorySample() }
        .onChange(of: store.state.settings.hiddenHistoryAccounts) { _, _ in clearHistorySample() }
        .onChange(of: timelineAccounts.map(\.id)) { _, _ in clearHistorySample() }
    }
    private var sampleAnchor: CGPoint? {
        guard let sample = hoveredSample else { return nil }
        return CGPoint(x: historyX(sample.point.at), y: plotTop + NSDecimalNumber(decimal: sample.point.remaining).doubleValue / 100 * plotHeight)
    }
    private func clearHistorySample() {
        historyPinned = false
        hoverText = nil
        hoveredSample = nil
    }
    private func panHistory(days: Double) {
        clearHistorySample()
        viewport.scroll(to: viewport.scrollOffset + days * viewport.pixelsPerDay)
        position.scrollTo(x: viewport.scrollOffset)
    }
    private func returnToToday() {
        clearHistorySample()
        viewport.followToday()
        position.scrollTo(x: viewport.scrollOffset)
    }
    private func inspectSample(direction: Int) {
        guard store.state.settings.historyEnabled else { return }
        var samples: [(ProviderAccount, HistoryPoint)] = []
        for series in historySeries {
            for point in UsageHistory.pointsWithin(series.points, left: viewport.scrollOffset,
                                                   right: viewport.scrollOffset + viewport.viewportWidth, project: historyX) {
                samples.append((series.account, point))
            }
        }
        // Stable sorting retains the displayed series order for simultaneous samples,
        // matching Windows OrderBy(Point.At) after flattening the visible series.
        samples.sort { $0.1.at < $1.1.at }
        guard !samples.isEmpty else { return }
        let current = samples.firstIndex { $0.0.id == hoveredSample?.account.id && $0.1.at == hoveredSample?.point.at }
        let index = current.map { min(samples.count - 1, max(0, $0 + direction)) } ?? (direction > 0 ? 0 : samples.count - 1)
        let sample = samples[index]
        showHistorySample(account: sample.0, point: sample.1)
        historyPinned = true
    }
    private func updateHistoryHover(_ location: CGPoint?) {
        guard let location,
              store.state.settings.historyEnabled,
              location.x >= viewport.scrollOffset,
              location.x <= min(viewport.scrollOffset + viewport.viewportWidth, viewport.position(at: now)),
              (plotTop...plotBottom).contains(location.y) else {
            hoverText = nil; hoveredSample = nil; return
        }
        func distance(_ point: HistoryPoint) -> Double {
            let x = historyX(point.at)
            let y = plotTop + NSDecimalNumber(decimal: point.remaining).doubleValue / 100 * plotHeight
            return abs(x - location.x) + abs(y - location.y) * 0.45
        }
        let nearest = historySeries.flatMap { series in UsageHistory.pointsWithin(series.points, left: location.x - 18, right: location.x + 18, project: historyX).map { (series.account, $0) } }
            .min { distance($0.1) < distance($1.1) }
        let estimate = nearest == nil ? historySeries.compactMap { series in
            UsageHistory.estimatedPoint(points: series.points, x: location.x, y: location.y, viewport: viewport, plotTop: plotTop, plotHeight: plotHeight).map { (series.account, $0) }
        }.first : nil
        if let (account, point) = nearest ?? estimate {
            showHistorySample(account: account, point: point)
        } else { hoverText = nil; hoveredSample = nil }
    }
    private func showHistorySample(account: ProviderAccount, point: HistoryPoint) {
        hoveredSample = (account, point)
        let name = store.state.settings.privacy ? "Account" : account.nickname
        let period = account.provider.hasMonthlyHistory ? "Monthly" : "Weekly"
        var details = "\(account.provider.rawValue) / \(name) · \(Format.plan(account.provider, store.state.snapshots[account.id]?.planType))"
        details += "\n\(period) · \(Format.percent(100 - point.remaining, fractionDigits: 1)) Used\n\(Format.date(point.at, zone: store.state.settings.zone))"
        if let first = presentation.series.first(where: { $0.account.id == account.id })?.points.first,
           viewport.position(at: first.at) > 0 {
            details += "\nHistory Begins \(Format.date(first.at, zone: store.state.settings.zone))"
        }
        if point.estimated { details += "\nEstimated Linear Connection From Previous Observation" }
        if let previous = point.replenishedFrom {
            details += "\nCapacity Rose From \(Format.percent(previous, fractionDigits: 1)) to \(Format.percent(point.remaining, fractionDigits: 1))\nObserved Between Polls"
            if let prior = point.previousObservedAt {
                details += "\n\(Format.date(prior, zone: store.state.settings.zone)) – \(Format.date(point.at, zone: store.state.settings.zone))"
            }
        }
        hoverText = details
    }

    private func drawNavigatorGrip(in context: inout GraphicsContext, centerX: Double) {
        for column in -1...1 {
            for row in 0...1 {
                let x = centerX + Double(column * 4)
                let y = Double(9 + row * 4)
                context.fill(Path(ellipseIn: CGRect(x: x - 1, y: y - 1, width: 2, height: 2)),
                             with: .color(Color(hex: "#D1BEFF")))
            }
        }
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
                context.stroke(thumb, with: .color(Theme.actionAccent), lineWidth: 1)
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
                let nowX = 1 + viewport.position(at: now) / viewport.contentWidth * trackWidth
                var nowLine = Path()
                nowLine.move(to: CGPoint(x: nowX, y: 3)); nowLine.addLine(to: CGPoint(x: nowX, y: 19))
                context.stroke(nowLine, with: .color(Color(hex: "#E5DCF9")), lineWidth: 1)
                drawNavigatorGrip(in: &context, centerX: overview.left + overview.width / 2)
            }.contentShape(Rectangle()).gesture(DragGesture(minimumDistance: 0).onChanged { value in
                if navigatorDragOffset == nil {
                    clearHistorySample()
                    let start = value.startLocation.x - 1
                    let thumb = viewport.overview(trackWidth: trackWidth)
                    if start < thumb.left || start > thumb.left + thumb.width {
                        viewport.centerFromOverview(pointerX: start, trackWidth: trackWidth)
                    }
                    navigatorDragOffset = viewport.scrollOffset
                }
                viewport.dragOverview(startOffset: navigatorDragOffset ?? viewport.scrollOffset,
                                      translation: value.translation.width, trackWidth: trackWidth)
                position.scrollTo(x: viewport.scrollOffset)
            }.onEnded { _ in navigatorDragOffset = nil })
            .focusable().focusEffectDisabled()
            .onKeyPress(.leftArrow) { panHistory(days: -1); return .handled }
            .onKeyPress(.upArrow) { panHistory(days: -1); return .handled }
            .onKeyPress(.rightArrow) { panHistory(days: 1); return .handled }
            .onKeyPress(.downArrow) { panHistory(days: 1); return .handled }
            .onKeyPress(.pageUp) { panHistory(days: -7); return .handled }
            .onKeyPress(.pageDown) { panHistory(days: 7); return .handled }
            .onKeyPress(.home) { returnToToday(); return .handled }
            .onKeyPress(.escape) { clearHistorySample(); return .handled }
            .accessibilityLabel("Timeline Navigator").accessibilityValue(Format.date(viewport.visibleStart, zone: store.state.settings.zone))
            .accessibilityAdjustableAction { direction in
                viewport.scroll(to: viewport.scrollOffset + (direction == .increment ? 1 : -1) * viewport.pixelsPerDay)
                position.scrollTo(x: viewport.scrollOffset)
            }
        }
    }
    private func drawHistory(context: inout GraphicsContext, size: CGSize) {
        let nowX = viewport.position(at: now)
        let chartHeight = plotHeight
        for percent in stride(from: 0, through: 100, by: 25) {
            let y = plotTop + (1 - Double(percent) / 100) * chartHeight
            var line = Path(); line.move(to: CGPoint(x: 0, y: y)); line.addLine(to: CGPoint(x: max(0, nowX), y: y))
            context.stroke(line, with: .color(Color(hex: "#343741")), lineWidth: 1)
        }
        for day in days {
            let x = viewport.position(at: day)
            guard x >= 0, x <= nowX else { continue }
            var line = Path()
            line.move(to: CGPoint(x: x, y: plotTop))
            line.addLine(to: CGPoint(x: x, y: plotTop + chartHeight))
            context.stroke(line, with: .color(Color(hex: "#30333C")), lineWidth: 2)
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
            context.stroke(marker, with: .color((event.expiration ? Theme.amber : Color(hex: "#B99AF8")).opacity(0.6)), style: StrokeStyle(lineWidth: 1, dash: [4,4]))
        }
        if let sample = hoveredSample,
           timelineAccounts.contains(where: { $0.id == sample.account.id }),
           !store.state.settings.hiddenHistoryAccounts.contains(sample.account.id) {
            let x = historyX(sample.point.at)
            let y = plotTop + NSDecimalNumber(decimal: sample.point.remaining).doubleValue / 100 * chartHeight
            var guide = Path()
            guide.move(to: CGPoint(x: x, y: plotTop))
            guide.addLine(to: CGPoint(x: x, y: plotTop + chartHeight))
            context.stroke(guide, with: .color(Theme.dialogText.opacity(0.6)), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            let dot = Path(ellipseIn: CGRect(x: x - 4, y: y - 4, width: 8, height: 8))
            context.fill(dot, with: .color(Color(hex: sample.account.resolvedLineColor(plan: store.state.snapshots[sample.account.id]?.planType))))
            context.stroke(dot, with: .color(.white), lineWidth: 1)
        }
        if nowX >= viewport.scrollOffset - 1, nowX <= viewport.scrollOffset + viewport.viewportWidth + 1 {
            var currentTime = Path()
            currentTime.move(to: CGPoint(x: nowX, y: plotTop))
            currentTime.addLine(to: CGPoint(x: nowX, y: plotTop + chartHeight))
            context.stroke(currentTime, with: .color(Theme.actionAccent), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
        }
        let latest = historySeries.compactMap { series -> (UsageHistorySeries, HistoryPoint)? in
            guard let point = UsageHistory.pointsWithin(series.points, left: viewport.scrollOffset, right: viewport.scrollOffset + viewport.viewportWidth, project: historyX).last else { return nil }
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
            context.fill(Path(roundedRect: rect, cornerRadius: 6), with: .color(Color(hex: "#202229")))
            context.stroke(Path(roundedRect: rect, cornerRadius: 6), with: .color(color), lineWidth: 1)
            let plan = Format.plan(series.account.provider, store.state.snapshots[series.account.id]?.planType)
            context.draw(Text("\(plan) \(Format.percent(100 - point.remaining, fractionDigits: 1))").font(.reference(size: 10)).foregroundColor(color), at: CGPoint(x: rect.midX, y: rect.midY))
        }
    }
    private func prepareHistory() {
        presentation = HorizonPresentation(accounts: timelineAccounts, runs: store.history, viewport: viewport, now: now)
    }
    private func historyX(_ date: Date) -> Double { presentation.positions[date] ?? viewport.position(at: date) }
    private var historicalEvents: [HorizonEvent] {
        guard store.state.settings.historyEnabled else { return [] }
        return presentation.events.filter { !store.state.settings.hiddenHistoryAccounts.contains($0.account.id) }
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
        return date.formatted(.dateTime.weekday(.abbreviated).withTimeZone(store.state.settings.zone))
    }
    private func isToday(_ date: Date) -> Bool { calendar.isDate(date, inSameDayAs: now) }
    private func update(width: Double) {
        clearHistorySample()
        viewport.update(now: now, furthestFuture: events.map(\.date).max(), zone: store.state.settings.zone, width: width, historyEnabled: store.state.settings.historyEnabled, earliestHistory: earliestRecordedHistory ?? now)
        position.scrollTo(x: viewport.scrollOffset)
    }
}

private extension Date.FormatStyle {
    func withTimeZone(_ zone: TimeZone) -> Self { var style = self; style.timeZone = zone; return style }
}

/// Wrap individual header controls, preserving the measured reference gaps.
/// The first row reserves the settings button's height so compact and wide
/// layouts retain their existing vertical alignment.
private struct HorizonHeaderFlow: Layout {
    private struct Row {
        var items: [(index: Int, size: CGSize)] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func rows(width: CGFloat, subviews: Subviews) -> [Row] {
        var result = [Row(height: 44)]
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            if !result[result.count - 1].items.isEmpty,
               result[result.count - 1].width + size.width > width {
                result.append(Row())
            }
            result[result.count - 1].items.append((index, size))
            result[result.count - 1].width += size.width
            result[result.count - 1].height = max(result[result.count - 1].height, size.height)
        }
        return result
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = rows(width: proposal.width ?? .infinity, subviews: subviews)
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0,
                      height: rows.reduce(0) { $0 + $1.height } + CGFloat(max(0, rows.count - 1)) * 16)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in rows(width: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for item in row.items {
                subviews[item.index].place(at: CGPoint(x: x, y: y + (row.height - item.size.height) / 2),
                                          anchor: .topLeading, proposal: ProposedViewSize(item.size))
                x += item.size.width
            }
            y += row.height + 16
        }
    }
}
