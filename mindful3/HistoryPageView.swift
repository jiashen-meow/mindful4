//
//  HistoryPageView.swift
//  mindful3
//
//  Created by Jia Shen on 7/30/26.
//
//  Monthly calendar view. Win days show a historyStamp on the date number.
//  Tap any day with a recorded result to see the full duel breakdown.
//  Users can page backward/forward through months.
//

import SwiftUI
import FamilyControls
internal import ManagedSettings

struct HistoryPageView: View {

    @Environment(AppState.self) private var state

    @State private var displayYear:  Int = Calendar.current.component(.year,  from: Date())
    @State private var displayMonth: Int = Calendar.current.component(.month, from: Date())

    // Sheet state
    @State private var selectedResult: SelectedDayResult? = nil

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdaySymbols: [String] = {
        var cal = Calendar.current
        cal.firstWeekday = 1
        return cal.veryShortWeekdaySymbols
    }()

    var body: some View {
        ZStack(alignment: .topLeading) {

            Color.appBackground
                .ignoresSafeArea()


            VStack(alignment: .leading) {
                // ── Back button ───────────────────────────────────────────────
                Button {
                    state.currentPage = .main
                } label: {
                    HStack() {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text("go back")
                            .appCaption
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                }

                // ── Month header ──────────────────────────────────────────
                Text(monthYearString)
                    .appTitle
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                // ── Weekday labels ────────────────────────────────────────
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(weekdaySymbols.indices, id: \.self) { index in
                        Text(weekdaySymbols[index])
                            .appCaption
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 8)
                    }
                }
                .padding(.horizontal, 16)

                // ── Day grid ──────────────────────────────────────────────
                let allResults = HistoryStore.allResults
                let cells      = buildCells()

                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(cells, id: \.id) { cell in
                        let result    = cell.day > 0 ? allResults[cell.dateString] : nil
                        let hasResult = result != nil
                        dayCell(cell, result: result)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                guard hasResult else { return }
                                selectedResult = makeSelectedResult(for: cell.dateString)
                            }
                            .opacity(hasResult ? 1.0 : (cell.day > 0 ? 0.5 : 1.0))
                    }
                }
                .padding(.horizontal, 16)

                Spacer().frame(height: 24)

                

                // ── Month navigation ──────────────────────────────────────
                HStack {
                    Button {
                        stepMonth(by: -1)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 11, weight: .semibold))
                            Text(previousMonthName)
                                .appCaption
                        }
                        .foregroundStyle(.primary)
                    }

                    Spacer()

                    Button {
                        stepMonth(by: 1)
                    } label: {
                        HStack(spacing: 4) {
                            Text(nextMonthName)
                                .appCaption
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(.primary)
                    }
                }
                .padding(.horizontal, 24)
                
                // ── Rotating quote ────────────────────────────────────────
                Spacer()
            }
            .tint(.primary)

        }
        .sheet(item: $selectedResult) { item in
            ResultPageView(
                outcome:       item.outcome,
                friendMinutes: item.friendMinutes,
                foeMinutes:   item.foeMinutes,
                dateString:    item.id
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Day cell

    @ViewBuilder
    private func dayCell(_ cell: CalendarCell, result: HistoryStore.DayResult?) -> some View {
        if cell.day == 0 {
            Color.clear.frame(height: 40)
        } else {
            ZStack {
                switch result {
                case .catWon:
                    Image("historyStamp")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                case .foeWon, .draw:
                    Text("\(cell.day)")
                        .appCaption
                        .foregroundStyle(.primary)
                case .empty:
                    Text("\(cell.day)")
                        .appCaption
                        .foregroundStyle(.primary)
                        .opacity(0.5)
                case nil:
                    Text("\(cell.day)")
                        .appCaption
                        .foregroundStyle(.primary)
                        .opacity(0.5)
                }
            }
            .frame(height: 40)
        }
    }

    // MARK: - Sheet model

    private struct SelectedDayResult: Identifiable {
        let id: String          // dateString
        let outcome:       BattleOutcome
        let friendMinutes: Int
        let foeMinutes:   Int
        let friendTokens:  Set<ApplicationToken>
        let foeTokens:    Set<ApplicationToken>
    }

    private func makeSelectedResult(for dateString: String) -> SelectedDayResult? {
        guard let dayResult = HistoryStore.result(for: dateString) else { return nil }

        let outcome: BattleOutcome
        switch dayResult {
        case .catWon:  outcome = .catWon
        case .foeWon:  outcome = .foeWon
        case .draw:    outcome = .draw
        case .empty:   outcome = .empty
        }

        // Empty days have no time data — return zeroes and skip selections.
        if outcome == .empty {
            return SelectedDayResult(
                id:            dateString,
                outcome:       .empty,
                friendMinutes: 0,
                foeMinutes:    0,
                friendTokens:  [],
                foeTokens:     []
            )
        }

        let savedMinutes    = HistoryStore.minutes(for: dateString)
        let savedSelections = HistoryStore.selections(for: dateString)

        let friendSel = savedSelections?.friendSelection ?? state.friendSelection
        let foeSel    = savedSelections?.foeSelection   ?? state.foeSelection

        return SelectedDayResult(
            id:            dateString,
            outcome:       outcome,
            friendMinutes: savedMinutes?.friendMinutes ?? 0,
            foeMinutes:    savedMinutes?.foeMinutes    ?? 0,
            friendTokens:  friendSel.applicationTokens,
            foeTokens:     foeSel.applicationTokens
        )
    }

    // MARK: - Calendar math

    private struct CalendarCell: Identifiable {
        let id: Int
        let day: Int
        let dateString: String
    }

    private func buildCells() -> [CalendarCell] {
        var cal = Calendar.current
        cal.firstWeekday = 1

        var comps  = DateComponents()
        comps.year  = displayYear
        comps.month = displayMonth
        comps.day   = 1
        guard let firstDay = cal.date(from: comps) else { return [] }

        let weekday       = cal.component(.weekday, from: firstDay)
        let leadingBlanks = weekday - 1
        let daysInMonth   = cal.range(of: .day, in: .month, for: firstDay)!.count

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"

        var cells: [CalendarCell] = []
        for i in 0..<leadingBlanks {
            cells.append(CalendarCell(id: i, day: 0, dateString: ""))
        }
        for day in 1...daysInMonth {
            comps.day = day
            let date  = cal.date(from: comps) ?? firstDay
            cells.append(CalendarCell(id: leadingBlanks + day - 1, day: day, dateString: fmt.string(from: date)))
        }
        return cells
    }

    private func stepMonth(by delta: Int) {
        var comps   = DateComponents()
        comps.year  = displayYear
        comps.month = displayMonth + delta
        let normalized = Calendar.current.date(from: comps) ?? Date()
        displayYear  = Calendar.current.component(.year,  from: normalized)
        displayMonth = Calendar.current.component(.month, from: normalized)
    }

    private var monthYearString: String {
        var comps   = DateComponents()
        comps.year  = displayYear
        comps.month = displayMonth
        comps.day   = 1
        guard let date = Calendar.current.date(from: comps) else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: date)
    }

    private var previousMonthName: String { adjacentMonthName(delta: -1) }
    private var nextMonthName:     String { adjacentMonthName(delta:  1) }

    private func adjacentMonthName(delta: Int) -> String {
        var comps   = DateComponents()
        comps.year  = displayYear
        comps.month = displayMonth + delta
        comps.day   = 1
        guard let date = Calendar.current.date(from: comps) else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM"
        return fmt.string(from: date)
    }

}

#Preview {
    HistoryPageView()
        .environment(AppState())
}
