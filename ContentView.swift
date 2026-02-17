//
//  ContentView.swift
//  notesapp
//
//  Created by Adam on 29/1/26.
//

import SwiftUI

// MARK: - Models

struct Page: Identifiable {
    let id = UUID()
    var text: String
}

struct Notebook: Identifiable {
    let id = UUID()
    let title: String
    var pages: [Page]
    let coverColor: Color
    let spineColor: Color
    let pageEdgeColor: Color
    let hasCoverArt: Bool
    let textureURL: String
    let creationDate: Date

    var pageCount: Int { pages.count }
}

// MARK: - Main Content View

struct ContentView: View {
    @State private var notebooks: [Notebook] = [
        Notebook(title: "Maldives 2025 🌴", pages: (0..<24).map { _ in Page(text: "") }, coverColor: Color(hex: "5A7A8A"), spineColor: Color(hex: "4A6878"), pageEdgeColor: Color(hex: "C8CDD0"), hasCoverArt: false, textureURL: "", creationDate: {
            var c = DateComponents(); c.year = 2025; c.month = 3; c.day = 14
            return Calendar.current.date(from: c)!
        }()),
        Notebook(title: "Journal", pages: [Page(text: "")], coverColor: Color(hex: "D4705A"), spineColor: Color(hex: "A84535"), pageEdgeColor: Color(hex: "C75540"), hasCoverArt: false, textureURL: "", creationDate: {
            var c = DateComponents(); c.year = 2024; c.month = 11; c.day = 2
            return Calendar.current.date(from: c)!
        }()),
        Notebook(title: "Ideas", pages: (0..<8).map { _ in Page(text: "") }, coverColor: Color(hex: "B5AE8A"), spineColor: Color(hex: "D4B830"), pageEdgeColor: Color(hex: "D4B830"), hasCoverArt: false, textureURL: "", creationDate: {
            var c = DateComponents(); c.year = 2026; c.month = 1; c.day = 8
            return Calendar.current.date(from: c)!
        }())
    ]
    @State private var selectedIndex: Int = 1
    @State private var showOnboarding: Bool = true
    @State private var dragOffset: CGFloat = 0
    @State private var openBookIndex: Int? = nil
    @State private var openBookProgress: CGFloat = 0
    @State private var bookJump: CGFloat = 0
    @State private var bookTurn: CGFloat = 0
    @State private var currentPage: Int = 0
    @State private var flipProgress: CGFloat = 0
    @State private var showFullBook: Bool = false
    @State private var currentSpread: Int = 0

    private func formattedCreationDate(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let dayOfWeek = formatter.string(from: date)
        let day = Calendar.current.component(.day, from: date)
        formatter.dateFormat = "MMMM yyyy"
        let monthYear = formatter.string(from: date)
        let suffix: String
        switch day {
        case 1, 21, 31: suffix = "st"
        case 2, 22: suffix = "nd"
        case 3, 23: suffix = "rd"
        default: suffix = "th"
        }
        return "\(dayOfWeek), \(day)\(suffix) \(monthYear)"
    }

    private var formattedCreationDate: String {
        formattedCreationDate(for: notebooks[selectedIndex].creationDate)
    }

    private var uiColor: Color {
        let p = Double(openBookProgress)
        return p > 0 ? Color.white.opacity(0.55 + (1 - p) * 0.45) : Color.black
    }

    private var uiBgColor: Color {
        let p = Double(openBookProgress)
        return p > 0 ? Color.white.opacity(0.15) : Color(hex: "#EFEFEF")
    }

    var body: some View {
        GeometryReader { geometry in
            let isIPad = min(geometry.size.width, geometry.size.height) > 500
            ZStack {
                Color.white
                    .ignoresSafeArea()

                // Background overlay: book color when opening
                if let openIndex = openBookIndex {
                    notebooks[openIndex].coverColor
                        .opacity(Double(openBookProgress))
                        .ignoresSafeArea()
                        .animation(.spring(response: 0.6, dampingFraction: 0.85), value: openBookProgress)
                }

                VStack(spacing: 0) {

                    // Top navigation bar
                    HStack {
                        Button(action: {}) {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(uiColor)
                        }
                        Spacer()

                      //  HStack {
                        //    Text("Private")
                          //      .fontWeight(.bold)
                            //    .foregroundStyle(uiColor)
                            //Image(systemName: "chevron.down")
                              //  .foregroundColor(uiColor)
                                //.fontWeight(.semibold)
                        //}
                        //.padding(.vertical, 5)
                        //.padding(.horizontal, 20)
                        //.background(uiBgColor)

                        Spacer()

                        Image("profile")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 34, height: 34)
                            .clipShape(Circle())
                            .opacity(1 - Double(openBookProgress) * 0.5)
                            .overlay(
                                Circle()
                                    .stroke(uiBgColor, lineWidth: 2)
                                    .frame(width: 40, height: 40)
                            )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                    Spacer()

                    // Aanhari x and Share with friends
                    Group {
                        if min(geometry.size.width, geometry.size.height) > 500 {
                            HStack {
                                Button(action: {}) {
                                    HStack(spacing: 2) {
                                        Text("aanhari")
                                            .foregroundStyle(uiColor)
                                            .font(.system(size: 17))
                                            .fontWeight(.bold)
                                        Image(systemName: "xmark")
                                            .foregroundStyle(uiColor)
                                    }
                                }
                                .padding(.horizontal, 7)
                                .padding(.vertical, 5)
                                .background(uiBgColor)
                                .cornerRadius(1)

                                Spacer()

                                HStack(spacing: 4) {
                                    Image(systemName: "person.2.fill")
                                        .foregroundStyle(uiColor)
                                        .font(.system(size: 15, weight: .semibold))
                                    Text("Share with friends")
                                        .foregroundStyle(uiColor)
                                        .fontWeight(.bold)
                                        .font(.system(size: 15, weight: .semibold))
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(uiColor)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                            .frame(width: min(geometry.size.width, geometry.size.height) * 0.48)
                        } else {
                            VStack(spacing: 8) {
                                Button(action: {}) {
                                    HStack(spacing: 2) {
                                        Text("aanhari")
                                            .foregroundStyle(uiColor)
                                            .font(.system(size: 17))
                                            .fontWeight(.bold)
                                        Image(systemName: "xmark")
                                            .foregroundStyle(uiColor)
                                    }
                                }
                                .padding(.horizontal, 7)
                                .padding(.vertical, 5)
                                .background(uiBgColor)
                                .cornerRadius(1)

                                HStack(spacing: 4) {
                                    Image(systemName: "person.2.fill")
                                        .foregroundStyle(uiColor)
                                        .font(.system(size: 15, weight: .semibold))
                                    Text("Share with friends")
                                        .foregroundStyle(uiColor)
                                        .fontWeight(.bold)
                                        .font(.system(size: 15, weight: .semibold))
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(uiColor)
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                        }
                    }
                    .offset(x: dragOffset)
                    .animation(.smooth(duration: 0.5), value: selectedIndex)
                    .animation(.smooth(duration: 0.15), value: dragOffset)

                    // Notebook Carousel
                    BookCarousel(
                        notebooks: notebooks,
                        selectedIndex: $selectedIndex,
                        dragOffset: $dragOffset,
                        screenWidth: min(geometry.size.width, geometry.size.height),
                        openBookIndex: openBookIndex,
                        openBookProgress: openBookProgress,
                        bookJump: bookJump,
                        bookTurn: bookTurn,
                        onBookTap: { index in
                            handleBookTap(index: index)
                        }
                    )
                    .frame(height: isIPad ? 532 : 418)

                    // Title and ellipsis row
                    HStack {
                        HStack(spacing: 5) {
                            Text(notebooks[selectedIndex].title)
                                .fontWeight(.semibold)
                                .foregroundStyle(uiColor)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 30)
                        .background(uiBgColor)

                        HStack {
                            Image(systemName: "ellipsis")
                                .font(.title)
                                .foregroundColor(uiColor)
                        }
                        .padding(.vertical, 11)
                        .padding(.horizontal, 20)
                        .background(uiBgColor)
                    }

                    // Divider line with book name pill
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(openBookProgress > 0 ? Color.white.opacity(0.15) : Color(hex: "E0E0E0"))
                            .frame(height: 1)

                        HStack(spacing: 4) {
                            Button(action: {}) {
                                Text(formattedCreationDate)
                                    .foregroundColor(openBookProgress > 0 ? Color.white.opacity(0.7) : .black)
                                    .font(.system(size: 16))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 2)
                            .background(openBookProgress > 0 ? Color.clear : Color(hex: "#EFEFEF"))

                            Text("by")
                                .foregroundStyle(openBookProgress > 0 ? uiColor.opacity(0.6) : Color(hex: "#898988"))

                            Text("@aanhari")
                                .foregroundStyle(uiColor)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 0)
                                .fill(openBookProgress > 0 ? Color.white.opacity(0.15) : Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 0)
                                        .stroke(openBookProgress > 0 ? Color.white.opacity(0.15) : Color(hex: "E0E0E0"), lineWidth: 1)
                                )
                        )
                        .fixedSize()

                        Rectangle()
                            .fill(openBookProgress > 0 ? Color.white.opacity(0.15) : Color(hex: "E0E0E0"))
                            .frame(height: 1)
                    }
                    .padding(.top, 12)
                    .animation(.smooth(duration: 0.4), value: selectedIndex)

                    Spacer()
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.85), value: openBookProgress)
                .allowsHitTesting(openBookIndex == nil)

                // Tap anywhere to close the open book
                if openBookIndex != nil && !showFullBook {
                    Color.clear
                        .contentShape(Rectangle())
                        .ignoresSafeArea()
                        .onTapGesture {
                            closeOpenBook()
                        }
                        .zIndex(4)
                }

                // Full open book view
                if let openIndex = openBookIndex, showFullBook {
                    FullOpenBookView(
                        notebook: $notebooks[openIndex],
                        coverColor: notebooks[openIndex].coverColor,
                        spineColor: notebooks[openIndex].spineColor,
                        currentSpread: $currentSpread,
                        onClose: { closeOpenBook() }
                    )
                    .transition(.opacity)
                    .zIndex(5)
                }

            }
        }
    }

    private func handleBookTap(index: Int) {
        if openBookIndex == index {
            closeOpenBook()
            return
        }

        if selectedIndex != index {
            withAnimation(.smooth(duration: 0.4)) {
                selectedIndex = index
                dragOffset = 0
            }
        }

        openBookIndex = index
        openBookProgress = 0
        bookJump = 0
        bookTurn = 0

        // Phase 1: Jump up
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            bookJump = 1
        }

        // Phase 2: Turn the book so right side recedes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                bookTurn = 1
            }
        }

        // Phase 3: Open the cover
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                openBookProgress = 1
                bookJump = 0
            }
        }

        // Phase 4: Show full open book view
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            if openBookProgress == 1 && openBookIndex == index {
                currentSpread = 0
                withAnimation(.easeInOut(duration: 0.4)) {
                    showFullBook = true
                }
            }
        }
    }

    private func closeOpenBook() {
        guard openBookIndex != nil else { return }

        if showFullBook {
            withAnimation(.easeInOut(duration: 0.3)) {
                showFullBook = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                performCoverCloseAnimation()
            }
        } else {
            performCoverCloseAnimation()
        }
    }

    private func performCoverCloseAnimation() {
        // Phase 1: Close the cover
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            openBookProgress = 0
        }

        // Phase 2: Turn back to face forward
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                bookTurn = 0
            }
        }

        // Phase 3: Bounce — jump up then land with springy settle
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) {
                bookJump = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                    bookJump = 0
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            if openBookProgress == 0 {
                openBookIndex = nil
            }
        }
    }
}

// MARK: - Open Book Footer


// MARK: - Header View

struct HeaderView: View {
    var body: some View {
        HStack {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 36, height: 36)
                    HStack(spacing: 2) {
                        ForEach(0..<4, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color(hex: "3D3D3D"))
                                .frame(width: 2.5, height: [10, 14, 14, 10][i])
                        }
                    }
                }
                Text("Paper Store")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color(hex: "2D2D2D"))
            }

            Spacer()

            HStack(spacing: 12) {
                CircleButton {
                    Text("¹₂³")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "4A4A4A"))
                }

                CircleButton {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color(hex: "4A4A4A"))
                }

                CircleButton {
                    VStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color(hex: "4A4A4A"))
                                .frame(width: 18, height: 2)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
}

struct CircleButton<Content: View>: View {
    let content: Content
    @Environment(\.horizontalSizeClass) var sizeClass

    private var isIPad: Bool {
        sizeClass == .regular
    }

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        Button(action: {}) {
            content
                .frame(width: isIPad ? 60 : 44, height: isIPad ? 60 : 44)
                .background(
                    Circle()
                        .stroke(Color(hex: "E0E0E0"), lineWidth: 1.5)
                )
        }
    }
}

// MARK: - Book Carousel

struct BookCarousel: View {
    let notebooks: [Notebook]
    @Binding var selectedIndex: Int
    @Binding var dragOffset: CGFloat
    let screenWidth: CGFloat
    let openBookIndex: Int?
    let openBookProgress: CGFloat
    let bookJump: CGFloat
    let bookTurn: CGFloat
    let onBookTap: (Int) -> Void

    private var isIPad: Bool {
        screenWidth > 500
    }

    private var bookWidth: CGFloat {
        isIPad ? screenWidth * 0.48 : screenWidth * 0.58
    }

    private var bookHeight: CGFloat {
        isIPad ? 456 : 342
    }

    private var bookSpacing: CGFloat {
        isIPad ? 40 : 20
    }

    @State private var isDragging: Bool = false

    var body: some View {
        GeometryReader { geometry in
            let totalBookWidth = bookWidth + bookSpacing
            let offset = (geometry.size.width / 2) - (bookWidth / 2) - (CGFloat(selectedIndex) * totalBookWidth) + dragOffset

            HStack(alignment: .bottom, spacing: bookSpacing) {
                ForEach(Array(notebooks.enumerated()), id: \.element.id) { index, notebook in
                    let isOpeningThis = openBookIndex == index
                    BookItem(
                        notebook: notebook,
                        isSelected: index == selectedIndex,
                        isDragging: isDragging,
                        bookWidth: bookWidth,
                        bookHeight: bookHeight,
                        isOpening: isOpeningThis,
                        openProgress: isOpeningThis ? openBookProgress : 0,
                        jump: isOpeningThis ? bookJump : 0,
                        turn: isOpeningThis ? bookTurn : 0
                    )
                    .opacity(openBookIndex == nil || isOpeningThis ? 1 : 1 - Double(openBookProgress))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onBookTap(index)
                    }
                    .zIndex(isOpeningThis ? 10 : 0)
                }
            }
            .frame(height: geometry.size.height, alignment: .bottom)
            .offset(x: offset)
            .animation(.smooth(duration: 0.5), value: selectedIndex)
            .animation(.smooth(duration: 0.15), value: dragOffset)
            .animation(.spring(response: 0.6, dampingFraction: 0.85), value: openBookProgress)
            .gesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        if !isDragging {
                            withAnimation(.smooth(duration: 0.35)) {
                                isDragging = true
                            }
                        }
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        let threshold: CGFloat = 50
                        let velocity = value.predictedEndTranslation.width

                        let oldIndex = selectedIndex
                        withAnimation(.smooth(duration: 0.5)) {
                            if value.translation.width < -threshold || velocity < -200 {
                                if selectedIndex < notebooks.count - 1 {
                                    selectedIndex += 1
                                }
                            } else if value.translation.width > threshold || velocity > 200 {
                                if selectedIndex > 0 {
                                    selectedIndex -= 1
                                }
                            }
                            dragOffset = 0
                        }
                        if selectedIndex != oldIndex {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.55)) {
                                isDragging = false
                            }
                        }
                    }
            )
        }
    }
}

// MARK: - Book Item

struct BookItem: View {
    let notebook: Notebook
    let isSelected: Bool
    let isDragging: Bool
    let bookWidth: CGFloat
    let bookHeight: CGFloat
    var isOpening: Bool = false
    var openProgress: CGFloat = 0
    var jump: CGFloat = 0
    var turn: CGFloat = 0

    private var isElevated: Bool {
        isSelected && !isDragging
    }

    private var elevation: CGFloat {
        isElevated ? -30 : 0
    }

    private var scale: CGFloat {
        isSelected ? 1.0 : 0.92
    }

    /// The angle the front cover rotates open (0 = closed, ~160 = fully open)
    private var coverOpenAngle: Double {
        Double(openProgress) * -160
    }

    /// The whole book turns so the right side recedes
    private var wholeTurnAngle: Double {
        Double(turn) * -35
    }

    /// Shift right to center the full open visual
    private var centeringOffset: CGFloat {
        openProgress * (bookWidth * 0.35)
    }

    var body: some View {
        ZStack {
            // Pages revealed behind the cover when opening
            if isOpening || openProgress > 0 {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "FCFBF7"))
                    .frame(width: bookWidth, height: bookHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
                    )
                    .overlay(
                        // Page lines
                        VStack(spacing: 24) {
                            ForEach(0..<8, id: \.self) { _ in
                                Rectangle()
                                    .fill(Color.black.opacity(0.05))
                                    .frame(height: 1)
                            }
                        }
                        .padding(.horizontal, bookWidth * 0.15)
                        .padding(.vertical, bookHeight * 0.12)
                        .opacity(Double(openProgress))
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 2, y: 2)
            }

            // The book cover that rotates open
            BookCover(notebook: notebook, width: bookWidth, height: bookHeight)
                .frame(width: bookWidth, height: bookHeight)
                .rotation3DEffect(
                    .degrees(coverOpenAngle),
                    axis: (x: 0, y: 1, z: 0),
                    anchor: .leading,
                    perspective: 0.4
                )
        }
        .frame(width: bookWidth, height: bookHeight)
        // Turn the whole book
        .rotation3DEffect(
            .degrees(wholeTurnAngle),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.3
        )
        .offset(x: centeringOffset)
        .scaleEffect(scale)
        // Jump + elevation
        .offset(y: elevation + (jump * -40))
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isSelected)
        .animation(.spring(response: 0.3, dampingFraction: 0.55), value: isDragging)
        .animation(.spring(response: 0.6, dampingFraction: 0.85), value: openProgress)
        .animation(.spring(response: 0.35, dampingFraction: 0.5), value: jump)
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: turn)
    }
}

// MARK: - Book Cover

struct BookShape: Shape {
    let cornerRadius: CGFloat
    let insetRight: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = cornerRadius
        let w = rect.width
        let h = rect.height

        path.move(to: CGPoint(x: r * 0.4, y: 0))
        path.addLine(to: CGPoint(x: w - r, y: 0))
        path.addQuadCurve(
            to: CGPoint(x: w, y: r),
            control: CGPoint(x: w, y: 0)
        )
        path.addLine(to: CGPoint(x: w, y: h - r))
        path.addQuadCurve(
            to: CGPoint(x: w - r, y: h),
            control: CGPoint(x: w, y: h)
        )
        path.addLine(to: CGPoint(x: r * 0.4, y: h))
        path.addLine(to: CGPoint(x: r * 0.4, y: 0))
        path.closeSubpath()
        return path
    }
}

struct BookCover: View {
    let notebook: Notebook
    let width: CGFloat
    let height: CGFloat

    private var cornerRad: CGFloat { 12 }
    private var insetWidth: CGFloat { width * 0.08 }
    private var groove1X: CGFloat { width * 0.075 }
    private var groove2X: CGFloat { width * 0.095 }

    var body: some View {
        Canvas { context, size in
            let rect = CGRect(origin: .zero, size: size)

            let bookPath = BookShape(
                cornerRadius: cornerRad,
                insetRight: groove2X + 4
            ).path(in: rect)

            // 1. Base cover fill
            context.fill(bookPath, with: .color(notebook.coverColor))

            // 2. Paper grain texture
            let grainGrad = Gradient(stops: [
                .init(color: Color.white.opacity(0.03), location: 0),
                .init(color: Color.black.opacity(0.02), location: 0.5),
                .init(color: Color.white.opacity(0.01), location: 1.0)
            ])
            context.fill(bookPath, with: .radialGradient(
                grainGrad,
                center: CGPoint(x: size.width * 0.3, y: size.height * 0.2),
                startRadius: 0,
                endRadius: max(size.width, size.height) * 0.9
            ))

            // 3. Primary groove line
            let g1Rect = CGRect(x: groove1X - 3, y: 0, width: 7, height: size.height)
            let g1Path = Path(g1Rect).intersection(bookPath)
            let g1Grad = Gradient(stops: [
                .init(color: Color.black.opacity(0.22), location: 0),
                .init(color: Color.black.opacity(0.28), location: 0.45),
                .init(color: Color.black.opacity(0.10), location: 0.6),
                .init(color: Color.white.opacity(0.10), location: 0.85),
                .init(color: Color.clear, location: 1.0)
            ])
            context.fill(g1Path, with: .linearGradient(
                g1Grad,
                startPoint: CGPoint(x: g1Rect.minX, y: rect.midY),
                endPoint: CGPoint(x: g1Rect.maxX, y: rect.midY)
            ))

            // 4. Second thinner groove line
            let g2Rect = CGRect(x: groove2X - 0.75, y: 0, width: 2, height: size.height)
            let g2Path = Path(g2Rect).intersection(bookPath)
            let g2Grad = Gradient(stops: [
                .init(color: Color.black.opacity(0.18), location: 0),
                .init(color: Color.black.opacity(0.22), location: 0.4),
                .init(color: Color.clear, location: 0.6),
                .init(color: Color.white.opacity(0.08), location: 0.9),
                .init(color: Color.clear, location: 1.0)
            ])
            context.fill(g2Path, with: .linearGradient(
                g2Grad,
                startPoint: CGPoint(x: g2Rect.minX, y: rect.midY),
                endPoint: CGPoint(x: g2Rect.maxX, y: rect.midY)
            ))

            // 5. Raised highlight lip
            let lipRect = CGRect(x: groove2X + 3, y: 0, width: 6, height: size.height)
            let lipPath = Path(lipRect).intersection(bookPath)
            let lipGrad = Gradient(stops: [
                .init(color: Color.white.opacity(0.14), location: 0),
                .init(color: Color.white.opacity(0.06), location: 0.3),
                .init(color: Color.clear, location: 1.0)
            ])
            context.fill(lipPath, with: .linearGradient(
                lipGrad,
                startPoint: CGPoint(x: lipRect.minX, y: rect.midY),
                endPoint: CGPoint(x: lipRect.maxX, y: rect.midY)
            ))

            // 6. Ambient occlusion
            let aoRect = CGRect(x: groove2X + 2, y: 0, width: 3, height: size.height)
            let aoPath = Path(aoRect).intersection(bookPath)
            let aoGrad = Gradient(stops: [
                .init(color: Color.black.opacity(0.08), location: 0),
                .init(color: Color.clear, location: 1.0)
            ])
            context.fill(aoPath, with: .linearGradient(
                aoGrad,
                startPoint: CGPoint(x: aoRect.minX, y: rect.midY),
                endPoint: CGPoint(x: aoRect.maxX, y: rect.midY)
            ))

            // 7. Studio lighting
            let lightGrad = Gradient(stops: [
                .init(color: Color.white.opacity(0.10), location: 0),
                .init(color: Color.white.opacity(0.04), location: 0.25),
                .init(color: Color.clear, location: 0.55)
            ])
            context.fill(bookPath, with: .radialGradient(
                lightGrad,
                center: CGPoint(x: size.width * 0.2, y: size.height * 0.05),
                startRadius: 0,
                endRadius: max(size.width, size.height) * 0.7
            ))

            // 8. Bottom-right darkening
            let shadowGrad = Gradient(stops: [
                .init(color: Color.clear, location: 0),
                .init(color: Color.clear, location: 0.5),
                .init(color: Color.black.opacity(0.04), location: 0.8),
                .init(color: Color.black.opacity(0.10), location: 1.0)
            ])
            context.fill(bookPath, with: .linearGradient(
                shadowGrad,
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: size.width, y: size.height)
            ))

            // 9. Edge stroke
            context.stroke(bookPath, with: .color(Color.black.opacity(0.06)), lineWidth: 0.5)

            // 10. Deep pressed title text
            let cleanTitle = String(notebook.title.unicodeScalars.filter { !$0.properties.isEmojiPresentation }).trimmingCharacters(in: .whitespaces)
            let titleFont: Font = .system(size: size.width * 0.09, weight: .medium)

            let measureResolved = context.resolve(Text(cleanTitle).font(titleFont).foregroundColor(.black))
            let titleSize = measureResolved.measure(in: CGSize(width: size.width * 0.75, height: size.height))
            let titleCenter = CGPoint(
                x: (size.width + groove2X + 4) / 2,
                y: size.height - titleSize.height / 2 - size.height * 0.06
            )

            var darkCtx = context
            darkCtx.opacity = 1.0
            let darkResolved = darkCtx.resolve(Text(cleanTitle).font(titleFont).foregroundColor(Color.black.opacity(0.28)))
            darkCtx.draw(darkResolved, at: CGPoint(x: titleCenter.x + 1.0, y: titleCenter.y + 1.5), anchor: .center)

            var depthCtx = context
            depthCtx.opacity = 1.0
            let depthResolved = depthCtx.resolve(Text(cleanTitle).font(titleFont).foregroundColor(Color.black.opacity(0.22)))
            depthCtx.draw(depthResolved, at: CGPoint(x: titleCenter.x, y: titleCenter.y), anchor: .center)

            var lightCtx = context
            lightCtx.opacity = 1.0
            let lightResolved = lightCtx.resolve(Text(cleanTitle).font(titleFont).foregroundColor(Color.white.opacity(0.14)))
            lightCtx.draw(lightResolved, at: CGPoint(x: titleCenter.x - 0.8, y: titleCenter.y - 1.0), anchor: .center)

            var aoCtx = context
            aoCtx.opacity = 1.0
            aoCtx.addFilter(.blur(radius: 1.5))
            let aoResolved2 = aoCtx.resolve(Text(cleanTitle).font(titleFont).foregroundColor(Color.black.opacity(0.10)))
            aoCtx.draw(aoResolved2, at: CGPoint(x: titleCenter.x, y: titleCenter.y + 0.5), anchor: .center)
        }
        .frame(width: width, height: height)
    }
}

// MARK: - Open Book Overlay

struct BookOpenOverlay: View {
    let notebook: Notebook
    let progress: CGFloat
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "C8BFAF")
                .ignoresSafeArea()

            RealisticOpenBook(
                coverColor: notebook.coverColor,
                spineColor: notebook.spineColor,
                pageColor: Color(hex: "FCFBF7"),
                progress: progress
            )
            .frame(maxWidth: 680)
            .padding(.horizontal, 24)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onClose()
        }
    }
}

struct RealisticOpenBook: View {
    let coverColor: Color
    let spineColor: Color
    let pageColor: Color
    let progress: CGFloat

    private var clampedProgress: CGFloat {
        min(1, max(0, progress))
    }

    var body: some View {
        GeometryReader { geometry in
            let maxWidth = min(geometry.size.width * 0.92, geometry.size.height * 1.35)
            let bookWidth = max(280, maxWidth)
            let bookHeight = bookWidth * 0.62
            let spineWidth = max(10, bookWidth * 0.035)
            let pageWidth = (bookWidth - spineWidth) / 2
            let pageHeight = bookHeight
            let coverBleed = bookWidth * 0.035

            let closedAngle: CGFloat = 68
            let openAngle: CGFloat = 6
            let leftAngle = Angle(degrees: Double(lerp(-closedAngle, -openAngle, clampedProgress)))
            let rightAngle = Angle(degrees: Double(lerp(closedAngle, openAngle, clampedProgress)))

            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.clear)
                    .shadow(color: Color.black.opacity(0.28), radius: 26, x: 0, y: 16)

                ZStack {
                    HStack(spacing: 0) {
                        OpenBookCover(color: coverColor)
                            .frame(width: pageWidth + coverBleed, height: pageHeight + coverBleed * 1.15)
                            .offset(x: -coverBleed * 0.5)
                        OpenBookCover(color: coverColor)
                            .frame(width: pageWidth + coverBleed, height: pageHeight + coverBleed * 1.15)
                            .offset(x: coverBleed * 0.5)
                    }

                    HStack(spacing: 0) {
                        OpenBookPage(side: .left, color: pageColor)
                            .frame(width: pageWidth, height: pageHeight)
                            .rotation3DEffect(
                                leftAngle,
                                axis: (x: 0, y: 1, z: 0),
                                anchor: .trailing,
                                perspective: 0.85
                            )

                        OpenBookPage(side: .right, color: pageColor)
                            .frame(width: pageWidth, height: pageHeight)
                            .rotation3DEffect(
                                rightAngle,
                                axis: (x: 0, y: 1, z: 0),
                                anchor: .leading,
                                perspective: 0.85
                            )
                    }

                    OpenBookSpine(color: spineColor)
                        .frame(width: spineWidth, height: pageHeight * 0.98)
                        .scaleEffect(x: 0.92, y: 1.0)
                }
                .frame(width: bookWidth, height: bookHeight)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

enum PageSide {
    case left
    case right
}

struct OpenBookPage: View {
    let side: PageSide
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            let innerCurve = w * 0.07
            let outerCurve = w * 0.05
            let segments = 6
            let segmentWidth = w / CGFloat(segments)
            let bendAmplitude: CGFloat = 3.2

            ZStack {
                HStack(spacing: 0) {
                    ForEach(0..<segments, id: \.self) { index in
                        let t = side == .left
                            ? CGFloat(segments - 1 - index) / CGFloat(segments - 1)
                            : CGFloat(index) / CGFloat(segments - 1)
                        let delta = side == .left
                            ? (0.5 - t) * bendAmplitude
                            : (t - 0.5) * bendAmplitude

                        Rectangle()
                            .fill(color)
                            .frame(width: segmentWidth + 0.5, height: h)
                            .rotation3DEffect(
                                Angle(degrees: Double(delta)),
                                axis: (x: 0, y: 1, z: 0),
                                anchor: side == .left ? .trailing : .leading,
                                perspective: 0.85
                            )
                    }
                }
                .mask(
                    PageShape(side: side, cornerRadius: 10, innerCurve: innerCurve, outerCurve: outerCurve)
                )

                PageShape(side: side, cornerRadius: 10, innerCurve: innerCurve, outerCurve: outerCurve)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.18),
                                Color.clear,
                                Color.black.opacity(0.04)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                PageShape(side: side, cornerRadius: 10, innerCurve: innerCurve, outerCurve: outerCurve)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.16),
                                Color.clear
                            ],
                            startPoint: side == .left ? .trailing : .leading,
                            endPoint: side == .left ? .leading : .trailing
                        )
                    )
                    .blendMode(.multiply)

                PageShape(side: side, cornerRadius: 10, innerCurve: innerCurve, outerCurve: outerCurve)
                    .stroke(Color.black.opacity(0.08), lineWidth: 0.6)
            }
            .frame(width: w, height: h)
            .shadow(color: Color.black.opacity(0.12), radius: 6, x: side == .left ? -2 : 2, y: 4)
        }
    }
}

struct OpenBookCover: View {
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(color)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.16),
                                Color.clear,
                                Color.black.opacity(0.12)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.black.opacity(0.12), lineWidth: 0.6)
            )
    }
}

struct OpenBookSpine: View {
    let color: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(color)
            .overlay(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.26),
                        Color.white.opacity(0.04),
                        Color.black.opacity(0.3)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .overlay(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.2),
                        Color.clear,
                        Color.black.opacity(0.18)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
    }
}

struct PageShape: Shape {
    let side: PageSide
    let cornerRadius: CGFloat
    let innerCurve: CGFloat
    let outerCurve: CGFloat

    func path(in rect: CGRect) -> Path {
        let r = cornerRadius
        let minX = rect.minX
        let maxX = rect.maxX
        let minY = rect.minY
        let maxY = rect.maxY

        var path = Path()

        if side == .left {
            path.move(to: CGPoint(x: minX + r, y: minY))
            path.addLine(to: CGPoint(x: maxX - r, y: minY))
            path.addQuadCurve(to: CGPoint(x: maxX, y: minY + r), control: CGPoint(x: maxX, y: minY))
            path.addQuadCurve(to: CGPoint(x: maxX, y: maxY - r), control: CGPoint(x: maxX - innerCurve, y: rect.midY))
            path.addQuadCurve(to: CGPoint(x: maxX - r, y: maxY), control: CGPoint(x: maxX, y: maxY))
            path.addLine(to: CGPoint(x: minX + r, y: maxY))
            path.addQuadCurve(to: CGPoint(x: minX, y: maxY - r), control: CGPoint(x: minX - outerCurve, y: maxY))
            path.addLine(to: CGPoint(x: minX, y: minY + r))
            path.addQuadCurve(to: CGPoint(x: minX + r, y: minY), control: CGPoint(x: minX - outerCurve, y: minY))
        } else {
            path.move(to: CGPoint(x: minX + r, y: minY))
            path.addLine(to: CGPoint(x: maxX - r, y: minY))
            path.addQuadCurve(to: CGPoint(x: maxX, y: minY + r), control: CGPoint(x: maxX + outerCurve, y: minY))
            path.addLine(to: CGPoint(x: maxX, y: maxY - r))
            path.addQuadCurve(to: CGPoint(x: maxX - r, y: maxY), control: CGPoint(x: maxX + outerCurve, y: maxY))
            path.addLine(to: CGPoint(x: minX + r, y: maxY))
            path.addQuadCurve(to: CGPoint(x: minX, y: maxY - r), control: CGPoint(x: minX, y: maxY))
            path.addQuadCurve(to: CGPoint(x: minX, y: minY + r), control: CGPoint(x: minX + innerCurve, y: rect.midY))
            path.addQuadCurve(to: CGPoint(x: minX + r, y: minY), control: CGPoint(x: minX, y: minY))
        }

        path.closeSubpath()
        return path
    }
}

private func lerp(_ start: CGFloat, _ end: CGFloat, _ t: CGFloat) -> CGFloat {
    start + (end - start) * t
}

// MARK: - Paper Demo Cover Art

struct PaperDemoCoverArt: View {
    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height

            ZStack {
                Ellipse()
                    .fill(Color(hex: "4A5560"))
                    .frame(width: w * 0.4, height: w * 0.28)
                    .rotationEffect(.degrees(-15))
                    .position(x: w * 0.4, y: h * 0.18)

                Ellipse()
                    .fill(Color(hex: "5A6570"))
                    .frame(width: w * 0.32, height: w * 0.24)
                    .rotationEffect(.degrees(10))
                    .position(x: w * 0.7, y: h * 0.44)

                Ellipse()
                    .fill(Color(hex: "4A5560"))
                    .frame(width: w * 0.26, height: w * 0.2)
                    .position(x: w * 0.6, y: h * 0.84)

                Capsule()
                    .fill(
                        LinearGradient(colors: [Color(hex: "F4B942"), Color(hex: "E8A030")],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: w * 0.44, height: w * 0.14)
                    .rotationEffect(.degrees(-50))
                    .position(x: w * 0.54, y: h * 0.12)

                Capsule()
                    .fill(
                        LinearGradient(colors: [Color(hex: "F4B942"), Color(hex: "D4943A")],
                                       startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: w * 0.4, height: w * 0.13)
                    .rotationEffect(.degrees(25))
                    .position(x: w * 0.64, y: h * 0.3)

                Triangle()
                    .fill(Color(hex: "E8734A"))
                    .frame(width: w * 0.18, height: w * 0.18)
                    .rotationEffect(.degrees(180))
                    .position(x: w * 0.34, y: h * 0.36)

                Triangle()
                    .fill(Color(hex: "D4633A"))
                    .frame(width: w * 0.14, height: w * 0.14)
                    .rotationEffect(.degrees(90))
                    .position(x: w * 0.6, y: h * 0.74)

                Ellipse()
                    .fill(Color(hex: "F0EBE0"))
                    .frame(width: w * 0.16, height: w * 0.12)
                    .position(x: w * 0.52, y: h * 0.8)

                Capsule()
                    .fill(Color(hex: "D9574A"))
                    .frame(width: w * 0.32, height: w * 0.07)
                    .rotationEffect(.degrees(70))
                    .position(x: w * 0.32, y: h * 0.74)

                Rectangle()
                    .fill(Color(hex: "2D3535"))
                    .frame(width: w * 0.22, height: 2)
                    .rotationEffect(.degrees(-40))
                    .position(x: w * 0.6, y: h * 0.26)

                Rectangle()
                    .fill(Color(hex: "2D3535"))
                    .frame(width: w * 0.15, height: 2)
                    .rotationEffect(.degrees(50))
                    .position(x: w * 0.74, y: h * 0.56)

                Rectangle()
                    .fill(Color(hex: "2D3535"))
                    .frame(width: w * 0.18, height: 2)
                    .rotationEffect(.degrees(-20))
                    .position(x: w * 0.4, y: h * 0.56)
            }
        }
    }
}

// MARK: - Bottom Action Bar

struct BottomActionBar: View {
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        HStack(spacing: sizeClass == .regular ? 20 : 14) {
            ActionButton(icon: "ellipsis")
            ActionButton(icon: "square.and.arrow.up")
            ActionButton(icon: "trash")
            ActionButton(icon: "plus")
        }
        .frame(maxWidth: .infinity)
    }
}

struct ActionButton: View {
    let icon: String
    @Environment(\.horizontalSizeClass) var sizeClass

    private var isIPad: Bool {
        sizeClass == .regular
    }

    var body: some View {
        Button(action: {}) {
            Image(systemName: icon)
                .font(.system(size: isIPad ? 22 : 18, weight: .medium))
                .foregroundColor(Color(hex: "3D3D3D"))
                .frame(width: isIPad ? 60 : 48, height: isIPad ? 60 : 48)
                .background(
                    Circle()
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 3)
                )
        }
    }
}

// MARK: - Onboarding Prompt

struct OnboardingPrompt: View {
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: "F5A623"))
                    .frame(width: 44, height: 44)

                Image(systemName: "gift.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Answer a couple of questions to")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "3D3D3D"))
                Text("get the most out of Paper!")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(hex: "3D3D3D"))
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: 4)
        )
        .onTapGesture {
            onDismiss()
        }
    }
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Full Open Book View (Two-Page Spread + Concave)

struct FullOpenBookView: View {
    @Binding var notebook: Notebook
    let coverColor: Color
    let spineColor: Color
    @Binding var currentSpread: Int
    let onClose: () -> Void

    // currentPage = index of the LEFT page in the spread (always even: 0, 2, 4…)
    @State private var currentPage: Int = 0
    @State private var flipProgress: CGFloat = 0  // -1…1, positive = forward
    @State private var isDragging: Bool = false

    // Subtle 3D tilt during flip (book stays in place, only tilts)
    @State private var tiltY: Double = 0
    @State private var shadowBlur: CGFloat = 24
    @State private var shadowOffsetY: CGFloat = 10
    @State private var shadowOpacity: Double = 0.28

    // Constants
    private let concaveAngle: Double = 5.5    // concave curvature per page half
    private let gutterW: CGFloat = 6          // spine gutter width
    private let maxTiltY: Double = 8          // subtle tilt during flip
    private let bookThickness: CGFloat = 14

    private var hasRightPage: Bool { currentPage + 1 < notebook.pages.count }
    private var canGoNext: Bool { currentPage + 2 < notebook.pages.count }
    private var canGoPrev: Bool { currentPage >= 2 }

    var body: some View {
        GeometryReader { geo in
            let coverPad: CGFloat = 10
            let totalW = min(geo.size.width - 24, 620)
            let pageH = min(geo.size.height * 0.58, totalW * 0.68)
            let pageW = (totalW - gutterW) / 2
            let fullW = totalW + coverPad * 2
            let fullH = pageH + coverPad * 2
            let edgeThickness: CGFloat = min(CGFloat(notebook.pages.count) * 0.4, 5)

            ZStack {
                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture { onClose() }

                VStack(spacing: 0) {
                    // Top bar
                    HStack {
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 34, height: 34)
                                .background(Circle().fill(Color.white.opacity(0.15)))
                        }
                        Spacer()
                        Text(notebook.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                        Spacer()
                        Button(action: addPage) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 34, height: 34)
                                .background(Circle().fill(Color.white.opacity(0.15)))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    Spacer()

                    // ═══ TWO-PAGE SPREAD BOOK ═══
                    ZStack {
                        // Ground-plane shadow
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.black.opacity(shadowOpacity))
                            .frame(width: fullW + 4, height: fullH + 4)
                            .blur(radius: shadowBlur)
                            .offset(y: shadowOffsetY)

                        // Book body
                        ZStack {
                            // Cover
                            RoundedRectangle(cornerRadius: 12)
                                .fill(coverColor)
                                .frame(width: fullW, height: fullH)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(LinearGradient(
                                            colors: [Color.white.opacity(0.1), Color.clear, Color.black.opacity(0.06)],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        ))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.black.opacity(0.15), lineWidth: 0.5)
                                )

                            // Page edge — top
                            RoundedRectangle(cornerRadius: 2)
                                .fill(LinearGradient(
                                    colors: [Color(hex: "E8E5E0"), Color(hex: "F0EDE8"), Color(hex: "E8E5E0")],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                                .frame(width: totalW + 2, height: max(2, edgeThickness * 0.5))
                                .offset(y: -(pageH / 2 + max(2, edgeThickness * 0.5) / 2 - 1))

                            // Page edge — bottom
                            RoundedRectangle(cornerRadius: 2)
                                .fill(LinearGradient(
                                    colors: [Color(hex: "E0DDD8"), Color(hex: "EAE7E2"), Color(hex: "E0DDD8")],
                                    startPoint: .leading, endPoint: .trailing
                                ))
                                .frame(width: totalW + 2, height: max(2, edgeThickness * 0.5))
                                .offset(y: pageH / 2 + max(2, edgeThickness * 0.5) / 2 - 1)

                            // Page edge — left (read pages stack)
                            let leftStack = min(CGFloat(currentPage / 2) * 0.7, edgeThickness)
                            if leftStack > 0 {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(LinearGradient(
                                        colors: [Color(hex: "E8E5E0"), Color(hex: "F2F0EC"), Color(hex: "EAE7E2")],
                                        startPoint: .leading, endPoint: .trailing
                                    ))
                                    .frame(width: leftStack, height: pageH - 8)
                                    .offset(x: -(totalW / 2 + leftStack / 2 - 1))
                            }

                            // Page edge — right (unread pages stack)
                            let unreadSpreads = max(0, (notebook.pages.count - currentPage - 2) / 2)
                            let rightStack = min(CGFloat(unreadSpreads) * 0.7, edgeThickness)
                            if rightStack > 0 {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(LinearGradient(
                                        colors: [Color(hex: "EAE7E2"), Color(hex: "F2F0EC"), Color(hex: "E8E5E0")],
                                        startPoint: .leading, endPoint: .trailing
                                    ))
                                    .frame(width: rightStack, height: pageH - 8)
                                    .offset(x: totalW / 2 + rightStack / 2 - 1)
                            }

                            // ── Page stack thickness (3D depth layers) ──
                            // Elevation shadow — pages float above cover
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.black.opacity(0.07))
                                .frame(width: totalW - 4, height: pageH - 4)
                                .blur(radius: 4)
                                .offset(y: 5)

                            // Stacked page layers beneath top pages (visible thickness)
                            let stackCount = min(max(notebook.pages.count / 2, 1), 5)
                            ForEach(0..<stackCount, id: \.self) { i in
                                let dy = CGFloat(stackCount - i) * 1.0
                                let shade = 0.95 - Double(stackCount - 1 - i) * 0.012
                                HStack(spacing: gutterW) {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(Color(white: shade))
                                        .frame(width: pageW - 1, height: pageH - 1)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 5)
                                                .stroke(Color.black.opacity(0.03), lineWidth: 0.5)
                                        )
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(Color(white: shade))
                                        .frame(width: pageW - 1, height: pageH - 1)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 5)
                                                .stroke(Color.black.opacity(0.03), lineWidth: 0.5)
                                        )
                                }
                                .offset(y: dy)
                            }

                            // === PAGE LAYERS ===

                            // Bottom layer: next/prev spread (revealed during flip)
                            if flipProgress > 0.01 && canGoNext {
                                spreadView(
                                    leftIdx: currentPage + 2,
                                    rightIdx: currentPage + 3,
                                    pageW: pageW, pageH: pageH,
                                    interactive: false
                                )
                                .allowsHitTesting(false)
                            }
                            if flipProgress < -0.01 && canGoPrev {
                                spreadView(
                                    leftIdx: currentPage - 2,
                                    rightIdx: currentPage - 1,
                                    pageW: pageW, pageH: pageH,
                                    interactive: false
                                )
                                .allowsHitTesting(false)
                            }

                            // Top layer: current spread with flip animation
                            HStack(spacing: gutterW) {
                                // ── LEFT PAGE (concave: outer edge toward viewer) ──
                                if currentPage < notebook.pages.count {
                                    ZStack(alignment: .bottom) {
                                        // Page thickness edge (visible at bottom)
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(LinearGradient(
                                                colors: [Color(hex: "E8E5E0"), Color(hex: "D8D5D0")],
                                                startPoint: .top, endPoint: .bottom
                                            ))
                                            .frame(width: pageW - 4, height: 2.5)
                                            .offset(y: 2)

                                        BookPageView(
                                            page: $notebook.pages[currentPage],
                                            pageNumber: currentPage + 1,
                                            width: pageW,
                                            height: pageH
                                        )
                                    }
                                    .frame(width: pageW, height: pageH + 3)
                                    // Concave curvature — left edge comes toward viewer
                                    .rotation3DEffect(
                                        .degrees(concaveAngle),
                                        axis: (x: 0, y: 1, z: 0),
                                        anchor: .trailing,
                                        perspective: 0.8
                                    )
                                    // Backward flip: left page turns over to the right
                                    .rotation3DEffect(
                                        flipProgress < 0
                                            ? .degrees(Double(-flipProgress) * 180)
                                            : .degrees(0),
                                        axis: (x: 0, y: 1, z: 0),
                                        anchor: .trailing,
                                        perspective: 0.4
                                    )
                                    .opacity(flipProgress < -0.5 ? 0 : 1)
                                    .opacity(flipProgress > 0.4
                                        ? max(0, 1 - Double(flipProgress - 0.4) / 0.6)
                                        : 1)
                                    .shadow(
                                        color: flipProgress < 0
                                            ? Color.black.opacity(Double(abs(flipProgress)) * 0.12)
                                            : .clear,
                                        radius: 6, x: 4, y: 2
                                    )
                                    .zIndex(flipProgress < 0 ? 2 : 0)
                                } else {
                                    elevatedBlankPage(width: pageW, height: pageH)
                                }

                                // ── RIGHT PAGE (concave: outer edge toward viewer) ──
                                if hasRightPage {
                                    ZStack(alignment: .bottom) {
                                        // Page thickness edge (visible at bottom)
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(LinearGradient(
                                                colors: [Color(hex: "E8E5E0"), Color(hex: "D8D5D0")],
                                                startPoint: .top, endPoint: .bottom
                                            ))
                                            .frame(width: pageW - 4, height: 2.5)
                                            .offset(y: 2)

                                        BookPageView(
                                            page: $notebook.pages[currentPage + 1],
                                            pageNumber: currentPage + 2,
                                            width: pageW,
                                            height: pageH
                                        )
                                    }
                                    .frame(width: pageW, height: pageH + 3)
                                    // Concave curvature — right edge comes toward viewer
                                    .rotation3DEffect(
                                        .degrees(-concaveAngle),
                                        axis: (x: 0, y: 1, z: 0),
                                        anchor: .leading,
                                        perspective: 0.8
                                    )
                                    // Forward flip: right page turns over to the left
                                    .rotation3DEffect(
                                        flipProgress > 0
                                            ? .degrees(Double(-flipProgress) * 180)
                                            : .degrees(0),
                                        axis: (x: 0, y: 1, z: 0),
                                        anchor: .leading,
                                        perspective: 0.4
                                    )
                                    .opacity(flipProgress > 0.5 ? 0 : 1)
                                    .opacity(flipProgress < -0.4
                                        ? max(0, 1 - Double(abs(flipProgress) - 0.4) / 0.6)
                                        : 1)
                                    .shadow(
                                        color: flipProgress > 0
                                            ? Color.black.opacity(Double(flipProgress) * 0.12)
                                            : .clear,
                                        radius: 6, x: -4, y: 2
                                    )
                                    .zIndex(flipProgress > 0 ? 2 : 0)
                                } else {
                                    elevatedBlankPage(width: pageW, height: pageH)
                                }
                            }
                            .allowsHitTesting(false)

                            // Spine gutter — center crease shadow
                            ZStack {
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color.black.opacity(0.14),
                                                Color.black.opacity(0.24),
                                                Color.black.opacity(0.14)
                                            ],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: gutterW + 10, height: pageH)
                                    .blur(radius: 3)

                                HStack(spacing: gutterW - 2) {
                                    Rectangle()
                                        .fill(Color.white.opacity(0.06))
                                        .frame(width: 1, height: pageH)
                                    Rectangle()
                                        .fill(Color.white.opacity(0.06))
                                        .frame(width: 1, height: pageH)
                                }
                            }
                            .allowsHitTesting(false)
                        }
                        // Gesture on the book body — contentShape ensures full area responds
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 8)
                                .onChanged { value in
                                    handleFlipDrag(value, pageW: pageW)
                                }
                                .onEnded { value in
                                    handleFlipEnd(value, pageW: pageW)
                                }
                        )
                        // Subtle 3D tilt during page flip
                        .rotation3DEffect(
                            .degrees(tiltY),
                            axis: (x: 0, y: 1, z: 0),
                            anchor: .center,
                            perspective: 0.5
                        )
                    }

                    Spacer()

                    // Spread indicator
                    HStack(spacing: 16) {
                        Text("Pages \(currentPage + 1)–\(min(currentPage + 2, notebook.pages.count)) of \(notebook.pages.count)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .onAppear { currentPage = 0 }
    }

    // MARK: - Elevated Blank Page

    @ViewBuilder
    private func elevatedBlankPage(width: CGFloat, height: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            // Page thickness edge
            RoundedRectangle(cornerRadius: 4)
                .fill(LinearGradient(
                    colors: [Color(hex: "E8E5E0"), Color(hex: "D8D5D0")],
                    startPoint: .top, endPoint: .bottom
                ))
                .frame(width: width - 4, height: 2.5)
                .offset(y: 2)

            // Blank page surface
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: "FAFAF7"))
                .frame(width: width, height: height)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.black.opacity(0.04), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 2)
        }
        .frame(width: width, height: height + 3)
    }

    // MARK: - Underneath Spread (read-only preview)

    @ViewBuilder
    private func spreadView(leftIdx: Int, rightIdx: Int, pageW: CGFloat, pageH: CGFloat, interactive: Bool) -> some View {
        HStack(spacing: gutterW) {
            if leftIdx >= 0 && leftIdx < notebook.pages.count {
                BookPageView(
                    page: interactive ? $notebook.pages[leftIdx] : .constant(notebook.pages[leftIdx]),
                    pageNumber: leftIdx + 1,
                    width: pageW,
                    height: pageH
                )
                .rotation3DEffect(
                    .degrees(concaveAngle),
                    axis: (x: 0, y: 1, z: 0),
                    anchor: .trailing,
                    perspective: 0.8
                )
            } else {
                Color(hex: "FAFAF7").frame(width: pageW, height: pageH).cornerRadius(6)
            }

            if rightIdx >= 0 && rightIdx < notebook.pages.count {
                BookPageView(
                    page: interactive ? $notebook.pages[rightIdx] : .constant(notebook.pages[rightIdx]),
                    pageNumber: rightIdx + 1,
                    width: pageW,
                    height: pageH
                )
                .rotation3DEffect(
                    .degrees(-concaveAngle),
                    axis: (x: 0, y: 1, z: 0),
                    anchor: .leading,
                    perspective: 0.8
                )
            } else {
                Color(hex: "FAFAF7").frame(width: pageW, height: pageH).cornerRadius(6)
            }
        }
    }

    // MARK: - Flip Gesture (no book dragging — swipe only flips pages)

    private func handleFlipDrag(_ value: DragGesture.Value, pageW: CGFloat) {
        isDragging = true
        let drag = value.translation.width
        let maxDrag = pageW * 0.8

        // Flip progress from drag
        var progress = -drag / maxDrag
        if progress > 0 && !canGoNext { progress *= 0.15 }
        if progress < 0 && !canGoPrev { progress *= 0.15 }
        flipProgress = min(max(progress, -1), 1)

        // Subtle book tilt follows the flip direction
        let tiltTarget = Double(flipProgress) * -maxTiltY * 0.5
        withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.8, blendDuration: 0.05)) {
            tiltY = tiltTarget
            // Shadow responds to elevation during flip
            shadowBlur = 24 + abs(CGFloat(flipProgress)) * 8
            shadowOffsetY = 10 + abs(CGFloat(flipProgress)) * 4
            shadowOpacity = 0.28 - Double(abs(flipProgress)) * 0.06
        }
    }

    private func handleFlipEnd(_ value: DragGesture.Value, pageW: CGFloat) {
        isDragging = false
        let velocity = -value.predictedEndTranslation.width / (pageW * 0.8)
        let threshold: CGFloat = 0.3

        if flipProgress > threshold || velocity > 1.2 {
            if canGoNext {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                    flipProgress = 1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    currentPage += 2
                    flipProgress = 0
                }
            } else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    flipProgress = 0
                }
            }
        } else if flipProgress < -threshold || velocity < -1.2 {
            if canGoPrev {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                    flipProgress = -1
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    currentPage -= 2
                    flipProgress = 0
                }
            } else {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    flipProgress = 0
                }
            }
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                flipProgress = 0
            }
        }

        // Settle tilt and shadow
        withAnimation(.spring(response: 0.55, dampingFraction: 0.72)) {
            tiltY = 0
            shadowBlur = 24
            shadowOffsetY = 10
            shadowOpacity = 0.28
        }
    }

    private func addPage() {
        notebook.pages.append(Page(text: ""))
        let lastSpreadStart = max(0, (notebook.pages.count - 1) / 2 * 2)
        if currentPage != lastSpreadStart {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.78)) {
                flipProgress = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                currentPage = lastSpreadStart
                flipProgress = 0
            }
        }
    }
}

// MARK: - Book Page View

struct BookPageView: View {
    @Binding var page: Page
    let pageNumber: Int
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Page paper
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: "FAFAF7"))
            // Subtle paper texture gradient
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.3), Color.clear, Color.black.opacity(0.02)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
            // Page border
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)

            // Content
            VStack(alignment: .leading, spacing: 0) {
                Text("\(pageNumber)")
                    .font(.system(size: 11, weight: .medium, design: .serif))
                    .foregroundColor(Color(hex: "B0ADA8"))
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.bottom, 8)

                TextEditor(text: $page.text)
                    .font(.system(size: 14, design: .serif))
                    .foregroundColor(Color(hex: "2D2D2D"))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
        }
        .frame(width: width, height: height)
    }
}

#Preview {
    ContentView()
}
