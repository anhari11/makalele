//
//  ContentView.swift
//  notesapp
//
//  Created by Adam on 29/1/26.
//

import SwiftUI

// MARK: - Models

struct Notebook: Identifiable {
    let id = UUID()
    let title: String
    let pageCount: Int
    let coverColor: Color
    let spineColor: Color
    let pageEdgeColor: Color
    let hasCoverArt: Bool
    let textureURL: String
    let creationDate: Date
}

// MARK: - Main Content View

struct ContentView: View {
    @State private var notebooks: [Notebook] = [
        Notebook(title: "Maldives 2025 🌴", pageCount: 24, coverColor: Color(hex: "5A7A8A"), spineColor: Color(hex: "4A6878"), pageEdgeColor: Color(hex: "C8CDD0"), hasCoverArt: false, textureURL: "", creationDate: {
            var c = DateComponents(); c.year = 2025; c.month = 3; c.day = 14
            return Calendar.current.date(from: c)!
        }()),
        Notebook(title: "Journal", pageCount: 1, coverColor: Color(hex: "D4705A"), spineColor: Color(hex: "A84535"), pageEdgeColor: Color(hex: "C75540"), hasCoverArt: false, textureURL: "", creationDate: {
            var c = DateComponents(); c.year = 2024; c.month = 11; c.day = 2
            return Calendar.current.date(from: c)!
        }()),
        Notebook(title: "Ideas", pageCount: 8, coverColor: Color(hex: "B5AE8A"), spineColor: Color(hex: "D4B830"), pageEdgeColor: Color(hex: "D4B830"), hasCoverArt: false, textureURL: "", creationDate: {
            var c = DateComponents(); c.year = 2026; c.month = 1; c.day = 8
            return Calendar.current.date(from: c)!
        }())
    ]
    @State private var selectedIndex: Int = 1
    @State private var showOnboarding: Bool = true
    @State private var dragOffset: CGFloat = 0
    @State private var openBookIndex: Int? = nil
    @State private var openBookProgress: CGFloat = 0

    private var formattedCreationDate: String {
        let date = notebooks[selectedIndex].creationDate
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

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.white
                    .ignoresSafeArea()

                // Background overlay: book color when opening
                if let openIndex = openBookIndex {
                    notebooks[openIndex].coverColor
                        .opacity(Double(openBookProgress) * 0.3)
                        .ignoresSafeArea()
                        .animation(.spring(response: 0.6, dampingFraction: 0.85), value: openBookProgress)
                }

                VStack(spacing: 0) {

                    // Top navigation bar
                    HStack {
                        Button(action: {}) {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(.black)
                        }
                        Spacer()

                        HStack {
                            Text("Private")
                                .fontWeight(.bold)
                            Image(systemName: "chevron.down")
                                .foregroundColor(.black)
                                .fontWeight(.semibold)
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 20)
                        .background(Color(hex: "#EFEFEF"))

                        Spacer()

                        Image("profile")
                            .resizable()
                            .scaledToFill()
                            .frame(width: 34, height: 34)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color(hex: "#efefef"), lineWidth: 2)
                                    .frame(width: 40, height: 40)
                            )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                    .opacity(1 - Double(openBookProgress))

                    Spacer()

                    // Aanhari x and Share with friends
                    Group {
                        if min(geometry.size.width, geometry.size.height) > 500 {
                            HStack {
                                Button(action: {}) {
                                    HStack(spacing: 2) {
                                        Text("aanhari")
                                            .foregroundStyle(Color.black)
                                            .font(.system(size: 17))
                                            .fontWeight(.bold)
                                        Image(systemName: "xmark")
                                            .foregroundStyle(Color.black)
                                    }
                                }
                                .padding(.horizontal, 7)
                                .padding(.vertical, 5)
                                .background(Color(hex: "#edebed"))
                                .cornerRadius(1)

                                Spacer()

                                HStack(spacing: 4) {
                                    Image(systemName: "person.2.fill")
                                        .foregroundStyle(Color.black)
                                        .font(.system(size: 15, weight: .semibold))
                                    Text("Share with friends")
                                        .fontWeight(.bold)
                                        .font(.system(size: 15, weight: .semibold))
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                            .frame(width: min(geometry.size.width, geometry.size.height) * 0.48)
                        } else {
                            VStack(spacing: 8) {
                                Button(action: {}) {
                                    HStack(spacing: 2) {
                                        Text("aanhari")
                                            .foregroundStyle(Color.black)
                                            .font(.system(size: 17))
                                            .fontWeight(.bold)
                                        Image(systemName: "xmark")
                                            .foregroundStyle(Color.black)
                                    }
                                }
                                .padding(.horizontal, 7)
                                .padding(.vertical, 5)
                                .background(Color(hex: "#edebed"))
                                .cornerRadius(1)

                                HStack(spacing: 4) {
                                    Image(systemName: "person.2.fill")
                                        .foregroundStyle(Color.black)
                                        .font(.system(size: 15, weight: .semibold))
                                    Text("Share with friends")
                                        .fontWeight(.bold)
                                        .font(.system(size: 15, weight: .semibold))
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                        }
                    }
                    .offset(x: dragOffset)
                    .animation(.smooth(duration: 0.5), value: selectedIndex)
                    .animation(.smooth(duration: 0.15), value: dragOffset)
                    .opacity(1 - Double(openBookProgress))

                    // Notebook Carousel
                    BookCarousel(
                        notebooks: notebooks,
                        selectedIndex: $selectedIndex,
                        dragOffset: $dragOffset,
                        screenWidth: min(geometry.size.width, geometry.size.height),
                        openBookIndex: openBookIndex,
                        openBookProgress: openBookProgress,
                        onBookTap: { index in
                            handleBookTap(index: index)
                        }
                    )
                    .frame(height: min(geometry.size.width, geometry.size.height) > 500 ? 532 : 418)

                    // Title and ellipsis row
                    HStack {
                        HStack(spacing: 5) {
                            Text(notebooks[selectedIndex].title)
                                .fontWeight(.semibold)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 30)
                        .background(Color(hex: "#EFEFEF"))

                        HStack {
                            Image(systemName: "ellipsis")
                                .font(.title)
                                .foregroundColor(.black)
                        }
                        .padding(.vertical, 11)
                        .padding(.horizontal, 20)
                        .background(Color(hex: "#EFEFEF"))
                    }
                    .opacity(1 - Double(openBookProgress))

                    // Divider line with book name pill
                    ZStack {
                        Rectangle()
                            .fill(Color(hex: "E0E0E0"))
                            .frame(height: 1)

                        HStack(spacing: 4) {
                            Button(action: {}) {
                                Text(formattedCreationDate)
                                    .foregroundColor(.black)
                                    .font(.system(size: 16))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 2)
                            .background(Color(hex: "#EFEFEF"))

                            Text("by")
                                .foregroundStyle(Color(hex: "#898988"))

                            Text("@aanhari")
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color(hex: "E0E0E0"), lineWidth: 1)
                                )
                        )
                    }
                    .padding(.top, 12)
                    .animation(.smooth(duration: 0.4), value: selectedIndex)
                    .opacity(1 - Double(openBookProgress))

                    Spacer()
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.85), value: openBookProgress)
                .allowsHitTesting(openBookIndex == nil)

                // Tap anywhere to close the open book
                if openBookIndex != nil {
                    Color.clear
                        .contentShape(Rectangle())
                        .ignoresSafeArea()
                        .onTapGesture {
                            closeOpenBook()
                        }
                        .zIndex(4)
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
        withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
            openBookProgress = 1
        }
    }

    private func closeOpenBook() {
        guard openBookIndex != nil else { return }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.9)) {
            openBookProgress = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            if openBookProgress == 0 {
                openBookIndex = nil
            }
        }
    }
}

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
                        openProgress: isOpeningThis ? openBookProgress : 0
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

    private var isElevated: Bool {
        isSelected && !isDragging
    }

    private var elevation: CGFloat {
        isElevated ? -30 : 0
    }

    private var scale: CGFloat {
        isSelected ? 1.0 : 0.92
    }

    /// The angle the front cover rotates open (0 = closed, ~180 = fully open)
    private var coverOpenAngle: Double {
        Double(openProgress) * -160
    }

    /// Shift right so the full visual (flipped cover on left + pages on right)
    /// is centered, not just the pages alone
    private var centeringOffset: CGFloat {
        // The cover extends ~bookWidth * sin(20°) ≈ 0.34 to the left when open
        // Shift right by half that to center the combined visual
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
        .offset(x: centeringOffset)
        .scaleEffect(scale)
        .offset(y: elevation)
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isSelected)
        .animation(.spring(response: 0.3, dampingFraction: 0.55), value: isDragging)
        .animation(.spring(response: 0.6, dampingFraction: 0.85), value: openProgress)
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

#Preview {
    ContentView()
}
