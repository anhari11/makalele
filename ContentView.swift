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
    let textureURL: String
}

// MARK: - Main Content View

struct ContentView: View {
    @State private var notebooks: [Notebook] = [
       
        Notebook(title: "Personal", pageCount: 24, coverColor: Color(hex: "5BBF7A"), spineColor: Color(hex: "4AA866"), hasCoverArt: false, textureURL: "https://www.sketchuptextureclub.com/public/texture_m/0017-green-velvet-fabric-texture-seamless.jpg"),
        Notebook(title: "Work", pageCount: 12, coverColor: Color(hex: "C75B4A"), spineColor: Color(hex: "A84D3F"), hasCoverArt: false, textureURL: "https://www.sketchuptextureclub.com/public/texture_m/0013-red-velvet-fabric-texture-seamless.jpg"),
        Notebook(title: "Ideas", pageCount: 8, coverColor: Color(hex: "E8C547"), spineColor: Color(hex: "C9A93D"), hasCoverArt: false, textureURL: "https://www.sketchuptextureclub.com/public/texture_m/0021-yellow-velvet-fabric-texture-seamless.jpg")
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
        screenWidth * 0.45
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
        isElevated ? 0.90 : 0.90
    }

    private var shadowRadius: CGFloat {
        isElevated ? 25 : 0
    }

    private var shadowY: CGFloat {
        isElevated ? 55 : 0
    }

    var body: some View {
        ZStack {
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
            // Base color fill
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(notebook.coverColor)
                .frame(width: width, height: height)
                .shadow(color: Color.black.opacity(0.10), radius: 30, x: 0, y: 14)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 4)

            // Texture from assets — tiled across cover
            Image("texture")
                .resizable(resizingMode: .tile)
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(notebook.coverColor.opacity(0.45))
                )

            // Velvet nap directional sheen
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.12), location: 0),
                            .init(color: Color.white.opacity(0.04), location: 0.15),
                            .init(color: Color.clear, location: 0.35),
                            .init(color: Color.black.opacity(0.03), location: 0.55),
                            .init(color: Color.black.opacity(0.08), location: 0.80),
                            .init(color: Color.black.opacity(0.12), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: width, height: height)

            // Soft radial sheen
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.02),
                            Color.clear
                        ],
                        center: .init(x: 0.45, y: 0.2),
                        startRadius: 0,
                        endRadius: max(width, height) * 0.55
                    )
                )
                .frame(width: width, height: height)

            // Soft edge border
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.14), location: 0),
                            .init(color: Color.white.opacity(0.04), location: 0.3),
                            .init(color: Color.clear, location: 0.5),
                            .init(color: Color.black.opacity(0.04), location: 0.8),
                            .init(color: Color.black.opacity(0.08), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
                .frame(width: width, height: height)

            // Spine groove on the left (library style)
            LinearGradient(
                stops: [
                    .init(color: Color.clear, location: 0),
                    .init(color: Color.black.opacity(0.18), location: 0.35),
                    .init(color: Color.black.opacity(0.22), location: 0.5),
                    .init(color: Color.black.opacity(0.10), location: 0.7),
                    .init(color: Color.white.opacity(0.12), location: 0.85),
                    .init(color: Color.clear, location: 1.0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 10, height: height)
            .offset(x: -(width / 2) + (width * 0.07) + 5)
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            // 3 vertical grooved lines
            HStack(spacing: width * 0.08) {
                ForEach(0..<3, id: \.self) { _ in
                    ZStack {
                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(Color.black.opacity(0.08))
                            .frame(width: 5, height: height * 0.46)
                            .offset(x: -0.5)

                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(Color.white.opacity(0.14))
                            .frame(width: 2, height: height * 0.46)
                            .offset(x: 2.5)

                        RoundedRectangle(cornerRadius: 2.5)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.black.opacity(0.10),
                                        Color.black.opacity(0.04),
                                        Color.white.opacity(0.06)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 3.5, height: height * 0.46)
                    }
                }
            }
            .offset(x: width * 0.08)

            // Cover art
            if notebook.hasCoverArt {
                PaperDemoCoverArt()
                    .frame(width: width - 30, height: height - 40)
            }

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
