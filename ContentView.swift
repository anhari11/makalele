//
//  ContentView.swift
//  notesapp
//
//  Created by Adam on 29/1/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Haptics

#if canImport(UIKit)
/// Shared haptic generators — created once, prepared early so the first
/// impactOccurred() doesn't hitch the Taptic Engine init.
enum Haptics {
    static let medium = UIImpactFeedbackGenerator(style: .medium)
    static let heavy  = UIImpactFeedbackGenerator(style: .heavy)

    /// Call once after launch animations settle (~0.7 s).
    /// .prepare() is lightweight (~10 ms) — just wakes the Taptic Engine.
    static func prepareAll() {
        medium.prepare()
        heavy.prepare()
    }
}
#endif

// MARK: - Keyboard Pre-warmer

#if canImport(UIKit)
/// Invisible UITextField with empty inputView (no keyboard shown).
/// Briefly becomes first responder after a delay to warm the text input
/// hosting layer, so the real TextField's first focus is instant.
struct TextInputWarmer: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let container = UIView(frame: .zero)
        container.isUserInteractionEnabled = false
        let tf = UITextField(frame: .zero)
        tf.inputView = UIView()          // empty → no visible keyboard
        tf.autocorrectionType = .no
        tf.alpha = 0
        container.addSubview(tf)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            tf.becomeFirstResponder()
            DispatchQueue.main.async {
                tf.resignFirstResponder()
            }
        }
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
#endif

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
    @State private var newBookDrop: CGFloat = 1
    @State private var droppingBookIndex: Int? = nil
    @State private var isAddingBook: Bool = false
    @State private var isNamingNewBook: Bool = false
    @State private var newBookTitle: String = ""
    @State private var cursorVisible: Bool = false
    @State private var cursorTimer: Timer? = nil
    @State private var entranceSlide: CGFloat = 1500
    @State private var hasAppeared: Bool = false
    @FocusState private var isTitleFieldFocused: Bool

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
                    .onTapGesture {
                        if isNamingNewBook {
                            finishNaming()
                        }
                    }

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

                        //HStack(spacing: 3) {
                          //  Image("profile")
                            //    .resizable()
                              //  .scaledToFill()
                                //.frame(width: 19, height: 19)
                                //.clipShape(Circle())
                                //.opacity(1 - Double(openBookProgress) * 0.5)

                            //Text("aanhari")
                              //  .foregroundStyle(Color.black)
                                //.fontWeight(.bold)
                            

                            //Image(systemName: "chevron.right")
                              //  .font(.system(size: 15, weight: .medium))
                                //.foregroundColor(Color(hex: "#898988"))
                                //.fontWeight(.bold)
                        //}

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 10)
                    
                    ZStack  {
                        // Centered: title + ellipsis
                        HStack(spacing: 3) {
                            ZStack {
                                // Always-present TextField (avoids first-keyboard lag)
                                TextField("", text: $newBookTitle)
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(.black)
                                    .multilineTextAlignment(.center)
                                    .tint(.clear)
                                    .focused($isTitleFieldFocused)
                                    .onSubmit { finishNaming() }
                                    .opacity(isNamingNewBook ? 1 : 0)
                                    .allowsHitTesting(isNamingNewBook)

                                if isNamingNewBook && newBookTitle.isEmpty {
                                    HStack(spacing: 0) {
                                        Text("Untitled")
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundColor(.gray.opacity(0.5))
                                        Rectangle()
                                            .fill(Color.black)
                                            .frame(width: 2, height: 20)
                                            .opacity(cursorVisible ? 1 : 0)
                                    }
                                    .allowsHitTesting(false)
                                }

                                if !isNamingNewBook {
                                    Text(notebooks[selectedIndex].title)
                                        .font(.system(size: 22, weight: .bold))
                                        .foregroundColor(.black)
                                }
                            }
                            .padding(.vertical, 9)
                            .padding(.horizontal, 18)
                            .background(Color(hex: "EFEFEF"))
                            .fixedSize()
                            Button(action: {}) {
                                HStack(spacing: 0) {   // 👈 control
                                    Image(systemName: "chevron.down")
                                        .foregroundStyle(Color.white)
                                        .fontWeight(.bold)
                                        .font(.system(size: 23, weight: .bold))
                                        
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 13.5)
                            .background(Color(hex: "#0e89fc"))
                            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 0, bottomTrailingRadius: 8, topTrailingRadius: 8))
                        }
                        .scaleEffect(isNamingNewBook ? 1.25 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: isNamingNewBook)
                        .offset(x: dragOffset)


                        if isIPad {
                            HStack {
                                Spacer()
                                Button(action: { addNewAlbum() }) {
                                    HStack(alignment: .center, spacing: 6) {
                                        Image("new2")
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 62, height: 62)
                                            .clipShape(Circle())
                                            .opacity(1 - Double(openBookProgress) * 0.5)

                                        Text("Make a new album")
                                            .foregroundStyle(Color.black)
                                            .fontWeight(.bold)
                                            .font(.system(size: 17))

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 17, weight: .bold))
                                            .foregroundColor(Color(hex: "#898988"))
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .animation(.smooth(duration: 0.5), value: selectedIndex)
                    .animation(.smooth(duration: 0.15), value: dragOffset)
                    .padding(.bottom, 40)

                    // Aanhari x and Share with friends
                    Group {
                        if isIPad {
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
                                .background(Color(hex: "EFEFEF"))
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
                                .background(Color(hex: "EFEFEF"))
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
                    .zIndex(2)
                    .padding(.bottom, 4)

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
                        },
                        currentPage: $currentPage,
                        newBookDrop: newBookDrop,
                        droppingBookIndex: droppingBookIndex,
                        entranceSlide: entranceSlide
                    )
                    .frame(height: isIPad ? 575 : 450)
                    .onAppear {
                        if !hasAppeared {
                            hasAppeared = true
                            entranceSlide = geometry.size.width
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                withAnimation(.easeOut(duration: 0.5)) {
                                    entranceSlide = 0
                                }
                            }
                        }
                    }

                    // Title and ellipsis row (moved to shelf overlay)

                    // Divider line with book name pill
                    //HStack(spacing: 0) {
                      //  Rectangle()
                        //    .fill(openBookProgress > 0 ? //Color.white.opacity(0.15) : Color(hex: "E0E0E0"))
                            //.frame(height: 1)

                        //HStack(spacing: 4) {
                          //  Button(action: {}) {
                            //    Text(formattedCreationDate)
                                  //  .foregroundColor(openBookProgress > 0 ? Color.white.opacity(0.7) : .black)
                                    //.font(.system(size: 16))
                            //}
                            //.padding(.horizontal, 10)
                            //.padding(.vertical, 2)
                            //.background(openBookProgress > 0 ? Color.clear : Color(hex: "#EFEFEF"))

                            //Text("by")
                              //  .foregroundStyle(openBookProgress > 0 ? uiColor.opacity(0.6) : Color(hex: "#898988"))

                            //Text("@aanhari")
                              //  .foregroundStyle(uiColor)
                        //}
                        
                       // .padding(.horizontal, 16)
                        //.padding(.vertical, 8)
                        //.background(
                          //  RoundedRectangle(cornerRadius: 0)
                            //    .fill(openBookProgress > 0 ? Color.white.opacity(0.15) : Color.white)
                                //.overlay(
                                  //  RoundedRectangle(cornerRadius: 0)
                                    //    .stroke(openBookProgress > 0 ? Color.white.opacity(0.15) : Color(hex: "E0E0E0"), lineWidth: 1)
                              //  )
                       // )
                      //  .fixedSize()
                        
                       
                        
                        

                       // Rectangle()
                         //   .fill(openBookProgress > 0 ? Color.white.opacity(0.15) : Color(hex: "E0E0E0"))
                           // .frame(height: 1)
                    //}
                    //.padding(.top, 12)
                    //.animation(.smooth(duration: 0.4), value: selectedIndex)

                    Spacer()

                    // Make a new album (mobile only, at bottom)
                    if !isIPad {
                        Button(action: { addNewAlbum() }) {
                            HStack(alignment: .center, spacing: 6) {
                                Spacer()
                                Image("new2")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 75, height: 75)
                                    .clipShape(Circle())
                                    .opacity(1 - Double(openBookProgress) * 0.5)

                                Text("Make a new album")
                                    .foregroundStyle(Color.black)
                                    .fontWeight(.bold)
                                    .font(.system(size: 17))

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 17, weight: .bold))
                                    .foregroundColor(Color(hex: "#898988"))
                                Spacer()
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                }
                .scaleEffect(isNamingNewBook ? 1.15 : 1.0, anchor: UnitPoint(x: 0.5, y: 0.13))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isNamingNewBook)
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
        .ignoresSafeArea(.keyboard)
        #if canImport(UIKit)
        .background(TextInputWarmer().frame(width: 0, height: 0))
        #endif
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
        currentPage = 0

        // Open cover + scale up
        withAnimation(.spring(response: 0.55, dampingFraction: 0.78)) {
            openBookProgress = 1
        }
    }

    private func closeOpenBook() {
        guard openBookIndex != nil else { return }
        performCoverCloseAnimation()
    }

    private func performCoverCloseAnimation() {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
            openBookProgress = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if openBookProgress == 0 {
                openBookIndex = nil
            }
        }
    }

    private func addNewAlbum() {
        guard !isAddingBook else { return }
        isAddingBook = true

        let colors: [(cover: String, spine: String, edge: String)] = [
            ("6B8E9B", "5A7C89", "B8BDC0"),
            ("C4604A", "984535", "B74530"),
            ("A59E7A", "C4A820", "C4A820"),
            ("7A6B8A", "685A78", "A8A0B0"),
            ("8A7A5A", "786848", "C0B890"),
        ]
        let pick = colors[Int.random(in: 0..<colors.count)]

        let newBook = Notebook(
            title: "Untitled",
            pages: [Page(text: "")],
            coverColor: Color(hex: pick.cover),
            spineColor: Color(hex: pick.spine),
            pageEdgeColor: Color(hex: pick.edge),
            hasCoverArt: false,
            textureURL: "",
            creationDate: Date()
        )

        notebooks.append(newBook)
        let newIndex = notebooks.count - 1
        droppingBookIndex = newIndex
        newBookDrop = 0
        newBookTitle = ""

        // Phase 1: Scroll to new book
        withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
            selectedIndex = newIndex
            dragOffset = 0
        }

        // Phase 2: Rise from below
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                newBookDrop = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                #if canImport(UIKit)
                Haptics.heavy.impactOccurred()
                #endif
                droppingBookIndex = nil
            }
        }

        // Phase 3: Show naming UI after bounce settles, then focus
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            isAddingBook = false
            isNamingNewBook = true
            cursorVisible = true
            cursorTimer?.invalidate()
            cursorTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
                DispatchQueue.main.async {
                    cursorVisible.toggle()
                }
            }
            // Focus on next render pass — naming UI (cursor + placeholder)
            // appears instantly, keyboard follows right after.
            DispatchQueue.main.async {
                self.isTitleFieldFocused = true
            }
        }
    }

    private func finishNaming() {
        let title = newBookTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !title.isEmpty {
            notebooks[selectedIndex] = Notebook(
                title: title,
                pages: notebooks[selectedIndex].pages,
                coverColor: notebooks[selectedIndex].coverColor,
                spineColor: notebooks[selectedIndex].spineColor,
                pageEdgeColor: notebooks[selectedIndex].pageEdgeColor,
                hasCoverArt: notebooks[selectedIndex].hasCoverArt,
                textureURL: notebooks[selectedIndex].textureURL,
                creationDate: notebooks[selectedIndex].creationDate
            )
        }
        cursorTimer?.invalidate()
        cursorTimer = nil
        cursorVisible = false
        withAnimation(.easeInOut(duration: 0.2)) {
            isNamingNewBook = false
        }
        isTitleFieldFocused = false
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

// MARK: - Diagonal Shadow Shape

struct DiagonalShadowShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Wedge from bottom-right (book corner) going diagonally up-left to vertical shade
        path.move(to: CGPoint(x: rect.maxX, y: rect.maxY))           // bottom-right (book corner)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY * 0.7))  // slightly above on right edge
        path.addLine(to: CGPoint(x: 0, y: 0))                        // top-left (meets vertical shade)
        path.addLine(to: CGPoint(x: 0, y: rect.maxY * 0.4))          // lower-left
        path.closeSubpath()
        return path
    }
}

// MARK: - Book Floor Shadow Shape

enum FloorShadowSide { case left, right }

struct BookFloorShadow: Shape {
    let side: FloorShadowSide

    func path(in rect: CGRect) -> Path {
        var path = Path()
        switch side {
        case .left:
            // Wedge: starts narrow at top-right (book corner), fans out to bottom-left
            path.move(to: CGPoint(x: rect.maxX, y: 0))
            path.addLine(to: CGPoint(x: rect.maxX * 0.7, y: 0))
            path.addLine(to: CGPoint(x: 0, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX * 0.5, y: rect.maxY))
            path.closeSubpath()
        case .right:
            // Wedge: starts narrow at top-left (book corner), fans out to bottom-right
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: rect.maxX * 0.3, y: 0))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX * 0.5, y: rect.maxY))
            path.closeSubpath()
        }
        return path
    }
}

// MARK: - Shelf Shape

struct ShelfTopShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
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
    @Binding var currentPage: Int
    var newBookDrop: CGFloat = 1
    var droppingBookIndex: Int? = nil
    var entranceSlide: CGFloat = 0

    private var isIPad: Bool { screenWidth > 500 }
    private var bookWidth: CGFloat { isIPad ? screenWidth * 0.48 : screenWidth * 0.58 }
    private var bookHeight: CGFloat { isIPad ? 456 : 342 }
    private var bookSpacing: CGFloat { 20 }

    @State private var isDragging: Bool = false
    @State private var dragVelocity: CGFloat = 0
    @State private var floatPhase: CGFloat = 0

    // Physics constants
    private let maxRotationY: Double = 25
    private let perspectiveAmount: Double = 0.35
    private let minScale: CGFloat = 0.32
    private let maxScale: CGFloat = 1.0

    // Shelf dimensions
    private var shelfTopSurface: CGFloat { isIPad ? 95 : 73 }
    private var shelfFrontFace: CGFloat { isIPad ? 32 : 24 }
    private var shelfShadowHeight: CGFloat { isIPad ? 50 : 38 }
    private var shelfTotal: CGFloat { shelfTopSurface + shelfFrontFace + 1.5 + shelfShadowHeight }

    /// Continuous normalized position for an item (0 = center, ±1 = one slot away)
    private func continuousPosition(index: Int, totalBookWidth: CGFloat) -> CGFloat {
        CGFloat(index - selectedIndex) + dragOffset / totalBookWidth
    }

    /// Smooth interpolation: scale from distance — reaches non-selected size at dist 1, stays there
    private func scaleForDistance(_ dist: CGFloat) -> CGFloat {
        let t = min(abs(dist), 1.0)
        let nonSelectedScale: CGFloat = 0.75
        let curved = t * t // quadratic: stays big near center, drops to non-selected
        return maxScale - (maxScale - nonSelectedScale) * curved
    }

    /// Y-axis rotation from distance — all books face straight forward
    private func rotationForDistance(_ dist: CGFloat) -> Double {
        return 0
    }

    /// Shadow opacity: softer when centered, stronger on sides
    private func shadowOpacityForDistance(_ dist: CGFloat) -> Double {
        let base = 0.12
        let extra = min(abs(Double(dist)), 2.0) * 0.08
        return base + extra
    }

    /// Vertical offset: selected book at front edge, others on shelf surface
    private func verticalOffsetForDistance(_ dist: CGFloat) -> CGFloat {
        let frontDrop = shelfTopSurface * 0.78 // selected book at front edge
        let backDrop = shelfTopSurface * 0.31  // non-selected on shelf surface
        let t = min(abs(dist), 1.0) / 1.0
        return frontDrop + (backDrop - frontDrop) * t
    }

    /// Parallax factor: items further from center lag slightly
    private func parallaxFactor(for dist: CGFloat) -> CGFloat {
        let factor = 1.0 - min(abs(dist), 3.0) * 0.03
        return factor
    }

    var body: some View {
        GeometryReader { geometry in
            let totalBookWidth = bookWidth + bookSpacing
            let baseOffset = (geometry.size.width / 2) - (bookWidth / 2) - (CGFloat(selectedIndex) * totalBookWidth) + dragOffset

            // ── Shelf ──
            VStack {
                Spacer()
                VStack(spacing: 0) {
                    // Top surface - perspective trapezoid
                    ShelfTopShape()
                        .fill(Color.white)
                        .frame(height: shelfTopSurface)

                    // Highlight lip
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.9), Color(hex: "E0E0E0")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 1)

                    // Front face
                    Rectangle()
                        .fill(Color(hex: "F3F3F3"))
                        .frame(height: shelfFrontFace)

                    // Bottom edge
                    Rectangle()
                        .fill(Color(hex: "B0B0B0"))
                        .frame(height: 0.5)

                    // Under-shelf drop shadow
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.black.opacity(0.16),
                                    Color.black.opacity(0.08),
                                    Color.black.opacity(0.03),
                                    Color.black.opacity(0.0)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: shelfShadowHeight)
                }
                .compositingGroup()
                .shadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 4)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .opacity(openBookIndex == nil ? 1 : max(0, 1 - Double(openBookProgress) * 1.5))
            .animation(.spring(response: 0.6, dampingFraction: 0.85), value: openBookProgress)

            // ── Books ──
            HStack(alignment: .bottom, spacing: bookSpacing) {
                ForEach(Array(notebooks.enumerated()), id: \.element.id) { index, notebook in
                    let isOpeningThis = openBookIndex == index
                    let dist = continuousPosition(index: index, totalBookWidth: totalBookWidth)
                    let itemScale = isOpeningThis ? (1.0 + openBookProgress * 0.55) : scaleForDistance(dist)
                    let rotationDeg = isOpeningThis ? 0.0 : rotationForDistance(dist)
                    let shadowOp = shadowOpacityForDistance(dist)
                    // Center the book in the carousel when opening
                    let openCenterOffset = shelfTotal + (bookHeight - geometry.size.height) / 2
                    let vOffset = isOpeningThis ? openCenterOffset : verticalOffsetForDistance(dist)
                    let zIdx: Double = isOpeningThis ? 10 : Double(1000) - abs(Double(dist)) * 100

                    // Micro float: only the centered book gets a subtle breathing animation
                    let microFloat: CGFloat = (abs(dist) < 0.15 && !isOpeningThis)
                        ? sin(floatPhase) * 1.2
                        : 0

                    BookItem(
                        notebook: notebook,
                        isSelected: index == selectedIndex,
                        isDragging: isDragging,
                        bookWidth: bookWidth,
                        bookHeight: bookHeight,
                        isOpening: isOpeningThis,
                        openProgress: isOpeningThis ? openBookProgress : 0,
                        jump: isOpeningThis ? bookJump : 0,
                        turn: isOpeningThis ? bookTurn : 0,
                        currentPage: $currentPage,
                        distanceFromCenter: dist,
                        shadowOpacity: shadowOp,
                        scrollVelocity: dragVelocity,
                        dropProgress: index == droppingBookIndex ? newBookDrop : 1
                    )
                    .scaleEffect(itemScale, anchor: isOpeningThis ? .center : .bottom)
                    .rotation3DEffect(
                        .degrees(rotationDeg),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: perspectiveAmount
                    )
                    .offset(y: vOffset + microFloat)
                    .opacity(openBookIndex == nil || isOpeningThis ? 1 : 1 - Double(openBookProgress))
                    .contentShape(Rectangle())
                    .onTapGesture { onBookTap(index) }
                    .zIndex(zIdx)
                }
            }
            .padding(.bottom, shelfTotal)
            .frame(height: geometry.size.height, alignment: .bottom)
            .offset(x: baseOffset + entranceSlide)
            .animation(.spring(response: 0.45, dampingFraction: 0.92), value: selectedIndex)
            .animation(.interpolatingSpring(stiffness: 300, damping: 30), value: dragOffset)
            .animation(.spring(response: 0.6, dampingFraction: 0.85), value: openBookProgress)
            .gesture(
                DragGesture(minimumDistance: 5)
                    .onChanged { value in
                        if !isDragging {
                            withAnimation(.spring(response: 0.2, dampingFraction: 1.0)) {
                                isDragging = true
                            }
                        }
                        // Rubber-band at edges
                        let raw = value.translation.width
                        let atLeftEdge = selectedIndex == 0 && raw > 0
                        let atRightEdge = selectedIndex == notebooks.count - 1 && raw < 0
                        if atLeftEdge || atRightEdge {
                            // Rubber-band: diminishing returns
                            let sign: CGFloat = raw > 0 ? 1 : -1
                            dragOffset = sign * pow(abs(raw), 0.7)
                        } else {
                            dragOffset = raw
                        }
                        dragVelocity = value.velocity.width
                    }
                    .onEnded { value in
                        let velocity = value.velocity.width
                        let translation = value.translation.width
                        dragVelocity = 0

                        // Determine how many slots to move based on velocity + distance
                        let threshold: CGFloat = totalBookWidth * 0.3
                        let velocityThreshold: CGFloat = 300

                        let oldIndex = selectedIndex
                        var newIndex = selectedIndex

                        if abs(velocity) > velocityThreshold {
                            // Velocity-based: always move exactly 1
                            if velocity < 0 {
                                newIndex = min(notebooks.count - 1, selectedIndex + 1)
                            } else {
                                newIndex = max(0, selectedIndex - 1)
                            }
                        } else if abs(translation) > threshold {
                            // Distance-based
                            if translation < 0 {
                                newIndex = min(notebooks.count - 1, selectedIndex + 1)
                            } else {
                                newIndex = max(0, selectedIndex - 1)
                            }
                        }

                        // Critically-damped spring snap
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.92)) {
                            selectedIndex = newIndex
                            dragOffset = 0
                        }

                        if newIndex != oldIndex {
                            #if canImport(UIKit)
                            Haptics.medium.impactOccurred()
                            #endif
                        }

                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 1.0)) {
                                isDragging = false
                            }
                        }
                    }
            )
        }
        .onAppear {
            // Delay micro-float so it doesn't compete with entrance animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                    floatPhase = .pi * 2
                }
            }
        }
    }
}

// MARK: - 3D Button

struct Button3DTopShape: Shape {
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = cornerRadius
        let inset = rect.width * 0.04

        // Top-left (inset)
        path.move(to: CGPoint(x: inset + r, y: 0))
        // Top edge
        path.addLine(to: CGPoint(x: rect.width - inset - r, y: 0))
        // Top-right curve
        path.addQuadCurve(to: CGPoint(x: rect.width - inset, y: r), control: CGPoint(x: rect.width - inset, y: 0))
        // Right edge going outward
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        // Bottom edge
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        // Left edge going inward
        path.addLine(to: CGPoint(x: inset, y: r))
        // Top-left curve
        path.addQuadCurve(to: CGPoint(x: inset + r, y: 0), control: CGPoint(x: inset, y: 0))
        path.closeSubpath()
        return path
    }
}

struct Button3D: View {
    var label: String? = nil
    var icon: String? = nil

    private let frontHeight: CGFloat = 4
    private let topHeight: CGFloat = 4
    private let cornerRad: CGFloat = 5

    private let topColor = Color.white
    private let frontColor = Color(hex: "EFEFEF")
    private let textColor = Color(hex: "888888")

    var body: some View {
        Button(action: {}) {
            VStack(spacing: 0) {
                // Top surface (perspective trapezoid like shelf)
                Button3DTopShape(cornerRadius: cornerRad)
                    .fill(topColor)
                    .frame(height: topHeight)

                // Highlight lip
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.9), Color(hex: "E0E0E0")],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 0.5)

                // Front face with content
                Group {
                    if let label = label {
                        Text(label)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(textColor)
                    } else if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(textColor)
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, label != nil ? 12 : 8)
                .frame(minWidth: 28)
                .frame(maxWidth: .infinity)
                .background(frontColor)

                // Bottom edge
                Rectangle()
                    .fill(Color(hex: "D5D5D5"))
                    .frame(height: 1)
            }
        }
        .buttonStyle(.plain)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Lined Page View

struct LinedPageView: View {
    let pageText: String
    let pageNumber: Int
    let totalPages: Int
    let creationDate: Date
    let pageWidth: CGFloat
    let pageHeight: CGFloat

    private let lineSpacing: CGFloat = 28
    private let topMargin: CGFloat = 56

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM yyyy"
        return formatter.string(from: creationDate)
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background
            Color(hex: "F4F2EC")

            // Ruled lines
            Canvas { context, size in
                var y = topMargin
                while y < size.height - 20 {
                    context.stroke(
                        Path { p in
                            p.move(to: CGPoint(x: 24, y: y))
                            p.addLine(to: CGPoint(x: size.width - 24, y: y))
                        },
                        with: .color(Color(hex: "C8C4BC").opacity(0.55)),
                        lineWidth: 0.5
                    )
                    y += lineSpacing
                }
            }

            // Date header
            VStack(alignment: .leading, spacing: 4) {
                Text(dateString)
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundColor(Color.black.opacity(0.75))
                    .padding(.top, 16)
                    .padding(.leading, 28)

                // Page text content
                if !pageText.isEmpty {
                    Text(pageText)
                        .font(.system(size: 15, design: .serif))
                        .foregroundColor(Color.black.opacity(0.8))
                        .padding(.leading, 28)
                        .padding(.trailing, 28)
                        .padding(.top, 4)
                }
            }

            // "Tap to edit" placeholder
            if pageText.isEmpty {
                VStack {
                    Spacer()
                    HStack {
                        Text("Tap to edit")
                            .font(.system(size: 15, design: .serif))
                            .foregroundColor(Color.gray.opacity(0.5))
                            .italic()
                            .padding(.leading, 28)
                            .padding(.bottom, 16)
                        Spacer()
                    }
                }
            }

            // Page number
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text("\(pageNumber)/\(totalPages)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.gray.opacity(0.55))
                        .padding(.trailing, 24)
                        .padding(.bottom, 16)
                }
            }
        }
        .frame(width: pageWidth, height: pageHeight)
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
    @Binding var currentPage: Int
    var distanceFromCenter: CGFloat = 0
    var shadowOpacity: Double = 0.15
    var scrollVelocity: CGFloat = 0
    var dropProgress: CGFloat = 1

    @State private var pageDragOffset: CGFloat = 0

    /// Drop offset: starts 500pt below, rises to 0
    private var dropOffset: CGFloat {
        (1 - dropProgress) * 300
    }

    /// Slight tilt during fall
    private var dropTilt: Double {
        dropProgress < 1 ? Double(1 - dropProgress) * 8 : 0
    }

    /// Turn angle (disabled — book stays portrait)
    private var turnAngle: Double { 0 }

    /// Vertical centering handled by carousel vOffset; no extra rise needed
    private var riseOffset: CGFloat { 0 }


    /// Motion blur amount based on scroll velocity
    private var motionBlurRadius: CGFloat {
        let v = abs(scrollVelocity)
        guard v > 400 else { return 0 }
        return min((v - 400) / 2000.0 * 2.0, 2.0)
    }

    /// Dynamic shadow X offset based on position (light from above-center)
    private var dynamicShadowX: CGFloat {
        let clamped = max(-2.0, min(2.0, distanceFromCenter))
        return clamped * 4
    }

    /// 0 = centered (selected), 1 = fully away (non-selected). Smooth interpolation.
    private var shadeFactor: CGFloat {
        min(abs(distanceFromCenter), 1.0)
    }

    /// Linearly interpolate between two values based on shadeFactor
    private func shadeLerp(_ selected: CGFloat, _ nonSelected: CGFloat) -> CGFloat {
        selected + (nonSelected - selected) * shadeFactor
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // ── Open book view (single page with cover frame) ──
            if isOpening || openProgress > 0 {
                let pageInset: CGFloat = 10
                let safeIndex = min(currentPage, max(notebook.pages.count - 1, 0))
                let pageText = notebook.pages.indices.contains(safeIndex) ? notebook.pages[safeIndex].text : ""
                let pagesAfter = max(0, notebook.pages.count - safeIndex - 1)
                let dragNorm = pageDragOffset / (bookHeight * 0.5)
                let tiltDeg = max(-25, min(25, Double(dragNorm) * 25))

                ZStack {
                    // Book interior (back cover visible as frame)
                    notebook.coverColor

                    // Inner edge shadow for depth
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.black.opacity(0.4), lineWidth: 4)
                        .blur(radius: 4)
                        .padding(3)

                    // Page stack underneath (shows thickness)
                    ForEach(0..<min(max(pagesAfter, 1), 5), id: \.self) { i in
                        let stackOffset = CGFloat(min(max(pagesAfter, 1), 5) - i)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: i % 2 == 0 ? "ECEAE4" : "F0EDE7"))
                            .padding(pageInset)
                            .offset(x: stackOffset * 1.0, y: stackOffset * 0.6)
                            .shadow(color: Color.black.opacity(0.03), radius: 0.5, x: 0.5, y: 0.3)
                    }

                    // Right-side page edges (thickness lines)
                    let edgeCount = min(pagesAfter, 10)
                    if edgeCount > 0 {
                        Canvas { context, size in
                            for i in 0..<edgeCount {
                                let x = size.width - CGFloat(edgeCount - i) * 1.2
                                let shade: Color = i % 2 == 0
                                    ? Color(hex: "E0DDD7") : Color(hex: "D5D2CC")
                                context.fill(
                                    Path(CGRect(x: x, y: 6, width: 0.8, height: size.height - 12)),
                                    with: .color(shade)
                                )
                            }
                        }
                        .frame(
                            width: CGFloat(edgeCount) * 1.2 + 2,
                            height: bookHeight - pageInset * 2 - 8
                        )
                        .offset(x: (bookWidth / 2) - pageInset - 2)
                        .allowsHitTesting(false)
                    }

                    // Bottom page edges (thickness lines)
                    let bottomEdgeCount = min(notebook.pageCount, 10)
                    if bottomEdgeCount > 0 {
                        Canvas { context, size in
                            for i in 0..<bottomEdgeCount {
                                let y = size.height - CGFloat(bottomEdgeCount - i) * 1.2
                                let shade: Color = i % 2 == 0
                                    ? Color(hex: "E0DDD7") : Color(hex: "D5D2CC")
                                context.fill(
                                    Path(CGRect(x: 6, y: y, width: size.width - 12, height: 0.8)),
                                    with: .color(shade)
                                )
                            }
                        }
                        .frame(
                            width: bookWidth - pageInset * 2 - 8,
                            height: CGFloat(bottomEdgeCount) * 1.2 + 2
                        )
                        .offset(y: (bookHeight / 2) - pageInset - 2)
                        .allowsHitTesting(false)
                    }

                    // Current page with drag tilt effect
                    LinedPageView(
                        pageText: pageText,
                        pageNumber: safeIndex + 1,
                        totalPages: notebook.pages.count,
                        creationDate: notebook.creationDate,
                        pageWidth: bookWidth - pageInset * 2,
                        pageHeight: bookHeight - pageInset * 2
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(pageInset)
                    .scaleEffect(1 + abs(dragNorm) * 0.008)
                    .rotation3DEffect(
                        .degrees(tiltDeg),
                        axis: (x: 1, y: 0, z: 0),
                        anchor: tiltDeg < 0 ? .top : .bottom,
                        perspective: 0.3
                    )
                    .shadow(
                        color: Color.black.opacity(min(Double(abs(dragNorm)) * 0.1, 0.1)),
                        radius: 5,
                        x: 0,
                        y: tiltDeg < 0 ? -2 : 2
                    )
                }
                .frame(width: bookWidth, height: bookHeight)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black.opacity(0.12), lineWidth: 0.5)
                )
                .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
                .opacity(Double(openProgress))
                .contentShape(Rectangle())
                .highPriorityGesture(
                    DragGesture(minimumDistance: 20)
                        .onChanged { value in
                            pageDragOffset = value.translation.height
                        }
                        .onEnded { value in
                            let threshold: CGFloat = 50
                            let velocity = value.velocity.height
                            if pageDragOffset < -threshold || velocity < -300 {
                                // Swipe up → next page
                                if currentPage < notebook.pages.count - 1 {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                        currentPage += 1
                                    }
                                }
                            } else if pageDragOffset > threshold || velocity > 300 {
                                // Swipe down → previous page
                                if currentPage > 0 {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                                        currentPage -= 1
                                    }
                                }
                            }
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.9)) {
                                pageDragOffset = 0
                            }
                        }
                )
            }

            // ── The book cover ──
            BookCover(notebook: notebook, width: bookWidth, height: bookHeight)
                .frame(width: bookWidth, height: bookHeight)
                .overlay(alignment: .topTrailing) {
                    if isSelected && !isOpening {
                        Button(action: {}) {
                            Text("Edit")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 17)
                        .padding(.vertical, 7)
                        .background(Color.black.opacity(0.20))
                        .cornerRadius(100)
                        .padding(.trailing, 13)
                        .padding(.top, 13)
                    }
                }
                // Cover flips upward from top edge — pages revealed below
                .rotation3DEffect(
                    .degrees(Double(openProgress) * -95),
                    axis: (x: 1, y: 0, z: 0),
                    anchor: .top,
                    perspective: 0.4
                )
        }
        .frame(width: bookWidth, height: bookHeight)
        // Vertical shade along the left edge
        .background(alignment: .bottomLeading) {
            if !isOpening && openProgress == 0 {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(shadeLerp(0.30, 0.20)))
                    .frame(width: bookWidth * shadeLerp(0.18, 0.16), height: bookHeight * shadeLerp(0.78, 0.70))
                    .blur(radius: shadeLerp(13, 14))
                    .offset(x: -bookWidth * shadeLerp(0.15, 0.12), y: -bookHeight * 0.04)
            }
        }
        // Diagonal shade from book's bottom-left corner up-left to vertical shade
        .background(alignment: .bottomLeading) {
            if !isOpening && openProgress == 0 {
                DiagonalShadowShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(shadeLerp(0.12, 0.08)),
                                Color.black.opacity(shadeLerp(0.05, 0.03)),
                                Color.clear
                            ],
                            startPoint: .bottomTrailing,
                            endPoint: .topLeading
                        )
                    )
                    .frame(width: bookWidth * shadeLerp(0.18, 0.14), height: bookHeight * shadeLerp(0.21, 0.20))
                    .blur(radius: shadeLerp(6, 5))
                    .offset(x: -bookWidth * shadeLerp(0.18, 0.14))
            }
        }
        // Sun from the right — shadow casts to the left
        .shadow(color: Color.black.opacity(shadeLerp(0.12, 0.08)), radius: shadeLerp(10, 6), x: shadeLerp(-10, -5), y: shadeLerp(8, 5))
        .shadow(color: Color.black.opacity(shadeLerp(0.06, 0.03)), radius: shadeLerp(3, 2), x: shadeLerp(-3, -2), y: shadeLerp(3, 2))
        // Subtle motion blur during fast scrolling
        .blur(radius: motionBlurRadius)
        .rotationEffect(.degrees(turnAngle))
        // Concave perspective — looking down at the open book
        .rotation3DEffect(
            .degrees(Double(openProgress) * -15),
            axis: (x: 1, y: 0, z: 0),
            anchor: .center,
            perspective: 0.5
        )
        // Vertical offset
        .offset(y: riseOffset)
        // Jump offset (for open animation)
        .offset(y: jump * -40)
        // Drop from above animation (new book add)
        .offset(y: dropOffset)
        .rotation3DEffect(
            .degrees(dropTilt),
            axis: (x: 0, y: 0, z: 1)
        )
        .opacity(dropProgress < 0.01 ? 0 : 1)
        .animation(.spring(response: 0.6, dampingFraction: 0.75), value: openProgress)
        .animation(.spring(response: 0.35, dampingFraction: 0.5), value: jump)
        .animation(.spring(response: 0.6, dampingFraction: 0.72), value: turn)
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
                .init(color: Color.black.opacity(0.26), location: 0),
                .init(color: Color.black.opacity(0.34), location: 0.45),
                .init(color: Color.black.opacity(0.12), location: 0.6),
                .init(color: Color.white.opacity(0.08), location: 0.85),
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
                .init(color: Color.black.opacity(0.22), location: 0),
                .init(color: Color.black.opacity(0.26), location: 0.4),
                .init(color: Color.clear, location: 0.6),
                .init(color: Color.white.opacity(0.06), location: 0.9),
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
                .init(color: Color.white.opacity(0.11), location: 0),
                .init(color: Color.white.opacity(0.05), location: 0.3),
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
                .init(color: Color.black.opacity(0.10), location: 0),
                .init(color: Color.clear, location: 1.0)
            ])
            context.fill(aoPath, with: .linearGradient(
                aoGrad,
                startPoint: CGPoint(x: aoRect.minX, y: rect.midY),
                endPoint: CGPoint(x: aoRect.maxX, y: rect.midY)
            ))

            // 7. Edge stroke (subtle)
            context.stroke(bookPath, with: .color(Color.black.opacity(0.04)), lineWidth: 0.5)

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
                .shadow(color: Color.black.opacity(1), radius: 12, x: 0, y: 4)
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
