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
    let hasCoverArt: Bool
}

// MARK: - Main Content View

struct ContentView: View {
    @State private var notebooks: [Notebook] = [
        Notebook(title: "Paper Demo", pageCount: 17, coverColor: Color(hex: "5BBF7A"), spineColor: Color(hex: "4AA866"), hasCoverArt: true),
        Notebook(title: "Personal", pageCount: 24, coverColor: Color(hex: "5BBF7A"), spineColor: Color(hex: "4AA866"), hasCoverArt: false),
        Notebook(title: "Work", pageCount: 12, coverColor: Color(hex: "C75B4A"), spineColor: Color(hex: "A84D3F"), hasCoverArt: false),
        Notebook(title: "Ideas", pageCount: 8, coverColor: Color(hex: "E8C547"), spineColor: Color(hex: "C9A93D"), hasCoverArt: false)
    ]
    @State private var selectedIndex: Int = 0
    @State private var showOnboarding: Bool = true
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.white
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    HeaderView()
                        .padding(.top, 10)

                    // Notebook Title
                    VStack(spacing: geometry.size.width > 500 ? 12 : 8) {
                        Text(notebooks[selectedIndex].title)
                            .font(.system(size: geometry.size.width > 500 ? 42 : 32, weight: .semibold))
                            .foregroundColor(Color(hex: "2D2D2D"))

                        HStack(spacing: 6) {
                            Image(systemName: "pencil.and.outline")
                                .font(.system(size: geometry.size.width > 500 ? 18 : 14))
                            Text("\(notebooks[selectedIndex].pageCount) Pages")
                                .font(.system(size: geometry.size.width > 500 ? 20 : 16, weight: .medium))
                        }
                        .foregroundColor(Color(hex: "888888"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, geometry.size.width > 500 ? 50 : 30)
                    .animation(.smooth(duration: 0.4), value: selectedIndex)

                    Spacer()

                    // Notebook Carousel
                    BookCarousel(
                        notebooks: notebooks,
                        selectedIndex: $selectedIndex,
                        dragOffset: $dragOffset,
                        screenWidth: geometry.size.width
                    )
                    .frame(height: geometry.size.width > 500 ? 550 : 400)

                    Spacer()

                    // Bottom Action Buttons
                    BottomActionBar()
                        .padding(.bottom, 20)

                    // Onboarding Prompt
                    if showOnboarding {
                        OnboardingPrompt {
                            withAnimation(.spring(response: 0.3)) {
                                showOnboarding = false
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
        }
    }
}

// MARK: - Header View

struct HeaderView: View {
    var body: some View {
        HStack {
            CircleButton {
                HStack(spacing: 2) {
                    ForEach(0..<4, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color(hex: "4A4A4A"))
                            .frame(width: 2.5, height: [12, 16, 16, 12][i])
                    }
                }
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
                .frame(width: isIPad ? 60 : 50, height: isIPad ? 60 : 50)
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

    // Responsive book sizes
    private var isIPad: Bool {
        screenWidth > 500
    }

    private var bookWidth: CGFloat {
        isIPad ? 280 : 180
    }

    private var bookHeight: CGFloat {
        isIPad ? 400 : 260
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
                    BookItem(
                        notebook: notebook,
                        isSelected: index == selectedIndex,
                        isDragging: isDragging,
                        bookWidth: bookWidth,
                        bookHeight: bookHeight
                    )
                }
            }
            .frame(height: geometry.size.height, alignment: .bottom)
            .offset(x: offset)
            .animation(.smooth(duration: 0.5), value: selectedIndex)
            .animation(.smooth(duration: 0.15), value: dragOffset)
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

                        // Delay the lift animation slightly for smoother feel
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

    // When dragging, selected book looks like non-selected (on floor, no shadow)
    private var isElevated: Bool {
        isSelected && !isDragging
    }

    private var elevation: CGFloat {
        isElevated ? -60 : 0
    }

    private var scale: CGFloat {
        isElevated ? 1.05 : 0.9
    }

    private var shadowOpacity: Double {
        isElevated ? 0.35 : 0
    }

    private var shadowRadius: CGFloat {
        isElevated ? 25 : 0
    }

    private var shadowY: CGFloat {
        isElevated ? 55 : 0
    }

    var body: some View {
        ZStack {
            // Shadow (only when elevated)
            Ellipse()
                .fill(Color.black.opacity(shadowOpacity))
                .frame(width: bookWidth * 0.85, height: 35)
                .blur(radius: shadowRadius)
                .offset(y: bookHeight / 2 + shadowY)

            // Book
            BookCover(notebook: notebook, width: bookWidth, height: bookHeight)
                .scaleEffect(scale)
                .offset(y: elevation)
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isSelected)
        .animation(.spring(response: 0.3, dampingFraction: 0.55), value: isDragging)
    }
}

// MARK: - Book Cover

struct BookCover: View {
    let notebook: Notebook
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack {
            // Base shape with outer shadow for depth
            RoundedRectangle(cornerRadius: 18)
                .fill(notebook.coverColor)
                .frame(width: width, height: height)
                .shadow(color: Color.black.opacity(0.22), radius: 14, x: 2, y: 8)

            // Matte plastic body: broad diffuse radial highlight (top-left light source)
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.22),
                            Color.white.opacity(0.08),
                            Color.clear,
                            Color.black.opacity(0.06)
                        ],
                        center: .init(x: 0.3, y: 0.25),
                        startRadius: 0,
                        endRadius: max(width, height) * 0.85
                    )
                )
                .frame(width: width, height: height)

            // Vertical soft ambient gradient (overhead light → bottom shadow)
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.10), location: 0),
                            .init(color: Color.clear, location: 0.35),
                            .init(color: Color.clear, location: 0.7),
                            .init(color: Color.black.opacity(0.08), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: width, height: height)

            // Soft edge rim light (simulates light wrapping around matte surface)
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.30), location: 0),
                            .init(color: Color.white.opacity(0.10), location: 0.25),
                            .init(color: Color.clear, location: 0.5),
                            .init(color: Color.black.opacity(0.06), location: 0.85),
                            .init(color: Color.black.opacity(0.10), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1.5
                )
                .frame(width: width, height: height)

            // Inner shadow overlay clipped to shape — gives a subtle recessed plastic feel
            RoundedRectangle(cornerRadius: 18)
                .fill(
                    RadialGradient(
                        colors: [
                            Color.clear,
                            Color.clear,
                            Color.black.opacity(0.04)
                        ],
                        center: .center,
                        startRadius: min(width, height) * 0.3,
                        endRadius: max(width, height) * 0.6
                    )
                )
                .frame(width: width, height: height)

            // 3 vertical grooved lines (suitcase ridges)
            HStack(spacing: width * 0.08) {
                ForEach(0..<3, id: \.self) { _ in
                    ZStack {
                        // Groove shadow (left side, light comes from top-left)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.black.opacity(0.10))
                            .frame(width: 4.5, height: height * 0.48)
                            .offset(x: -1)

                        // Groove highlight (right side catch-light)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.20))
                            .frame(width: 2, height: height * 0.48)
                            .offset(x: 2)

                        // Groove channel
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.black.opacity(0.09),
                                        Color.black.opacity(0.03),
                                        Color.white.opacity(0.12)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 3.5, height: height * 0.48)
                    }
                }
            }
            .offset(x: width * 0.04)

            // Spine on left edge
            HStack(spacing: 0) {
                UnevenRoundedRectangle(
                    topLeadingRadius: 18,
                    bottomLeadingRadius: 18,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
                .fill(
                    LinearGradient(
                        colors: [
                            notebook.spineColor.opacity(0.75),
                            notebook.spineColor,
                            notebook.spineColor.opacity(0.9)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 14)
                Spacer()
            }
            .frame(width: width, height: height)

            // Sunken surface near the bottom with embossed title
            VStack {
                Spacer()
                ZStack {
                    // Sunken panel base (slightly darker than cover)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.06))
                        .frame(width: width * 0.6, height: height * 0.1)

                    // Inner shadow top edge (light comes from top-left, so top edge is dark)
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            LinearGradient(
                                stops: [
                                    .init(color: Color.black.opacity(0.14), location: 0),
                                    .init(color: Color.black.opacity(0.06), location: 0.3),
                                    .init(color: Color.clear, location: 0.5),
                                    .init(color: Color.white.opacity(0.18), location: 0.85),
                                    .init(color: Color.white.opacity(0.22), location: 1.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: width * 0.6, height: height * 0.1)

                    // Embossed title text — same groove technique as the 3 lines
                    ZStack {
                        // Text shadow (dark offset top-left, simulating pressed-in)
                        Text(notebook.title.uppercased())
                            .font(.system(size: width * 0.065, weight: .bold, design: .rounded))
                            .foregroundColor(Color.black.opacity(0.12))
                            .offset(x: -0.5, y: -0.5)

                        // Text highlight (light offset bottom-right, catch-light on pressed edge)
                        Text(notebook.title.uppercased())
                            .font(.system(size: width * 0.065, weight: .bold, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.25))
                            .offset(x: 0.8, y: 0.8)

                        // Main text body (subtle groove fill)
                        Text(notebook.title.uppercased())
                            .font(.system(size: width * 0.065, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color.black.opacity(0.10),
                                        Color.black.opacity(0.04),
                                        Color.white.opacity(0.12)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
                .offset(x: width * 0.04)
                .padding(.bottom, height * 0.1)
            }
            .frame(width: width, height: height)

            // Cover art
            if notebook.hasCoverArt {
                PaperDemoCoverArt()
                    .frame(width: width - 30, height: height - 40)
            }

            // Page edges on right
            HStack {
                Spacer()
                VStack(spacing: 2) {
                    ForEach(0..<15, id: \.self) { _ in
                        Rectangle()
                            .fill(Color(hex: "F5F3EE"))
                            .frame(width: 3, height: 1)
                    }
                }
                .padding(.trailing, 3)
            }
            .frame(width: width, height: height)
        }
    }
}

// MARK: - Paper Demo Cover Art

struct PaperDemoCoverArt: View {
    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height

            ZStack {
                // Dark gray stones
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

                // Yellow/orange banana shapes
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

                // Orange wedge shapes
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

                // Cream/white pebbles
                Ellipse()
                    .fill(Color(hex: "F0EBE0"))
                    .frame(width: w * 0.16, height: w * 0.12)
                    .position(x: w * 0.52, y: h * 0.8)

                // Red/coral pencil shape
                Capsule()
                    .fill(Color(hex: "D9574A"))
                    .frame(width: w * 0.32, height: w * 0.07)
                    .rotationEffect(.degrees(70))
                    .position(x: w * 0.32, y: h * 0.74)

                // Small sticks/lines
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

                // Title Text
                VStack(spacing: 2) {
                    Text("PAPER")
                        .font(.system(size: w * 0.19, weight: .bold))
                    Text("DEMO")
                        .font(.system(size: w * 0.19, weight: .bold))
                }
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 1, y: 1)
                .position(x: w * 0.5, y: h * 0.5)
            }
        }
    }
}

// MARK: - Bottom Action Bar

struct BottomActionBar: View {
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        HStack(spacing: sizeClass == .regular ? 24 : 16) {
            ActionButton(icon: "ellipsis")
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
                .font(.system(size: isIPad ? 26 : 20, weight: .medium))
                .foregroundColor(Color(hex: "4A4A50"))
                .frame(width: isIPad ? 70 : 56, height: isIPad ? 70 : 56)
                .background(
                    Circle()
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.15), radius: isIPad ? 12 : 8, x: 0, y: 4)
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
