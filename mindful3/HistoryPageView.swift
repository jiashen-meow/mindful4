//
//  HistoryPageView.swift
//  mindful3
//
//  Created by Jia Shen on 7/30/26.
//
//  Monthly calendar view. Win days show a historyStamp on the date number.
//  Users can page backward/forward through months.
//

import SwiftUI

struct HistoryPageView: View {

    @Environment(AppState.self) private var state

    @State private var displayYear:  Int = Calendar.current.component(.year,  from: Date())
    @State private var displayMonth: Int = Calendar.current.component(.month, from: Date())

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    private let weekdaySymbols: [String] = {
        var cal = Calendar.current
        cal.firstWeekday = 1
        return cal.veryShortWeekdaySymbols
    }()

    var body: some View {
        ZStack(alignment: .topLeading) {

            Color(red: 250/255, green: 246/255, blue: 238/255)
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
                            .font(.appCaption)
                    }
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                }

//                Spacer().frame(height: 60)

                // ── Month navigation header ───────────────────────────────
                HStack {
                    Button {
                        stepMonth(by: -1)
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.primary)
                    }

                    Spacer()

                    Text(monthYearString)
                        .font(.appHeadline)
                        .foregroundStyle(.primary)

                    Spacer()

                    Button {
                        stepMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                }
                .padding(.horizontal, 24)

                Spacer().frame(height: 24)

                // ── Weekday labels ────────────────────────────────────────
                LazyVGrid(columns: columns, spacing: 0) {
                    ForEach(weekdaySymbols.indices, id: \.self) { index in
                        Text(weekdaySymbols[index])
                            .font(.appCaption)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.bottom, 8)
                    }
                }
                .padding(.horizontal, 16)

                // ── Day grid ──────────────────────────────────────────────
                let winDates = HistoryStore.winDates(in: displayYear, month: displayMonth)
                let cells    = buildCells()

                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(cells, id: \.id) { cell in
                        dayCell(cell, isWin: winDates.contains(cell.dateString))
                    }
                }
                .padding(.horizontal, 16)

                Spacer().frame(height: 16)

                Spacer()

                // ── Silhouette & quote ────────────────────────────────────
                ZStack(alignment: .center) {

                    GeometryReader { proxy in
                        Image("historySilhouette")
                            .resizable()
                            .scaledToFit()
                            .frame(width: proxy.size.width / 3)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 48)
                    }
                    
                    Text("Quicato defending the world from\nmundane things.\nHelp her along her journey.")
                        .font(.appCaption)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 48)
                }
            }
            .tint(.primary)

        }
    }

    // MARK: - Day cell

    @ViewBuilder
    private func dayCell(_ cell: CalendarCell, isWin: Bool) -> some View {
        if cell.day == 0 {
            Color.clear.frame(height: 40)
        } else {
            ZStack {
                if isWin {
                    Image("historyStamp")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                } else {
                    Text("\(cell.day)")
                        .font(.appCaption)
                        .foregroundStyle(.primary)
                }
            }
            .frame(height: 40)
        }
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

}

#Preview {
    HistoryPageView()
        .environment(AppState())
}
