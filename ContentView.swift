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
    @State private var showFullBook: Bool = false
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

                        HStack(spacing: 3) {
                            Image("profile")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 19, height: 19)
                                .clipShape(Circle())
                                .opacity(1 - Double(openBookProgress) * 0.5)

                            Text("aanhari")
                                .foregroundStyle(Color.black)
                                .fontWeight(.bold)
                            

                            Image(systemName: "chevron.right")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(Color(hex: "#898988"))
                                .fontWeight(.bold)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 50)
                    
                    ZStack {
                        // Centered: title + ellipsis
                        HStack(spacing: 4) {
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
                                            .font(.system(size: 17, weight: .bold))
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
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.black)
                                }
                            }
                            .padding(.vertical, 6)
                            .padding(.horizontal, 14)
                            .background(Color(hex: "EFEFEF"))
                            .fixedSize()
                            Button(action: {}) {
                                HStack(spacing: 6) {   // 👈 control
                                    Rectangle()
                                        .frame(width: 6.5, height: 6.5)
                                           Rectangle()
                                        .frame(width: 6.5, height: 6.5)
                                           Rectangle()
                                        .frame(width: 6.5, height: 6.5)
                                }
                                .foregroundStyle(.black)
                            }
                            .padding(.horizontal, 19)
                            .padding(.vertical, 13.8
                            )
                            .background(Color(hex: "EFEFEF"))
                           
                        }
                        .offset(x: dragOffset)

                   
                        if isIPad {
                            HStack {
                                Spacer()
                                Button(action: { addNewAlbum() }) {
                                    HStack(alignment: .center, spacing: 6) {
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
                    CarouselBookView(
                        notebook: $notebooks[openIndex],
                        coverColor: notebooks[openIndex].coverColor,
                        spineColor: notebooks[openIndex].spineColor,
                        onClose: { closeOpenBook() }
                    )
                    .transition(.opacity)
                    .zIndex(5)
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
    var newBookDrop: CGFloat = 1
    var droppingBookIndex: Int? = nil
    var entranceSlide: CGFloat = 0

    private var isIPad: Bool { screenWidth > 500 }
    private var bookWidth: CGFloat { isIPad ? screenWidth * 0.48 : screenWidth * 0.58 }
    private var bookHeight: CGFloat { isIPad ? 456 : 342 }
    private var bookSpacing: CGFloat { isIPad ? 40 : 20 }

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
                    let itemScale = isOpeningThis ? 1.0 : scaleForDistance(dist)
                    let rotationDeg = isOpeningThis ? 0.0 : rotationForDistance(dist)
                    let shadowOp = shadowOpacityForDistance(dist)
                    let vOffset = isOpeningThis ? CGFloat(0) : verticalOffsetForDistance(dist)
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
                        distanceFromCenter: dist,
                        shadowOpacity: shadowOp,
                        scrollVelocity: dragVelocity,
                        dropProgress: index == droppingBookIndex ? newBookDrop : 1
                    )
                    .scaleEffect(itemScale, anchor: .bottom)
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
    var distanceFromCenter: CGFloat = 0
    var shadowOpacity: Double = 0.15
    var scrollVelocity: CGFloat = 0
    var dropProgress: CGFloat = 1

    /// Drop offset: starts 500pt below, rises to 0
    private var dropOffset: CGFloat {
        (1 - dropProgress) * 300
    }

    /// Slight tilt during fall
    private var dropTilt: Double {
        dropProgress < 1 ? Double(1 - dropProgress) * 8 : 0
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
            // ── Pages revealed behind the cover when opening ──
            if isOpening || openProgress > 0 {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "FCFBF7"))
                    .frame(width: bookWidth, height: bookHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black.opacity(0.06), lineWidth: 0.5)
                    )
                    .overlay(
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

            // ── The book cover ──
            BookCover(notebook: notebook, width: bookWidth, height: bookHeight)
                .frame(width: bookWidth, height: bookHeight)
                .overlay(alignment: .topTrailing) {
                    if isSelected && !isOpening {
                        Button(action: {}) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .frame(width: 32, height: 32)
                        .background(Color.black.opacity(0.20))
                        .cornerRadius(0)
                        .padding(.trailing, 8)
                        .padding(.top, 10)
                    }
                }
                .rotation3DEffect(
                    .degrees(coverOpenAngle),
                    axis: (x: 0, y: 1, z: 0),
                    anchor: .leading,
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
        // Turn the whole book
        .rotation3DEffect(
            .degrees(wholeTurnAngle),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.3
        )
        .offset(x: centeringOffset)
        // Jump offset (for open animation)
        .offset(y: jump * -40)
        // Drop from above animation (new book add)
        .offset(y: dropOffset)
        .rotation3DEffect(
            .degrees(dropTilt),
            axis: (x: 0, y: 0, z: 1)
        )
        .opacity(dropProgress < 0.01 ? 0 : 1)
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

// MARK: - Carousel Book View (Pop-up Carousel Style)

struct CarouselBookView: View {
    @Binding var notebook: Notebook
    let coverColor: Color
    let spineColor: Color
    let onClose: () -> Void

    @State private var rotation: Double = 0
    @State private var dragRotation: Double = 0
    @State private var appear: CGFloat = 0

    var body: some View {
        GeometryReader { geo in
            let isIPad = min(geo.size.width, geo.size.height) > 500
            let pageCount = notebook.pages.count
            let sliceAngle = 360.0 / Double(max(pageCount, 1))
            let size = min(geo.size.width, geo.size.height)

            let radius: CGFloat = isIPad ? size * 0.3 : size * 0.26
            let pageW: CGFloat = isIPad ? min(size * 0.24, 180) : min(size * 0.32, 140)
            let pageH = pageW * 1.4

            ZStack {
                coverColor.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
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

                    // 3D Carousel
                    ZStack {
                        // Ground shadow
                        Ellipse()
                            .fill(
                                RadialGradient(
                                    colors: [Color.black.opacity(0.3), Color.black.opacity(0.05), Color.clear],
                                    center: .center,
                                    startRadius: radius * 0.1,
                                    endRadius: radius * 1.4
                                )
                            )
                            .frame(width: radius * 3, height: radius * 0.9)
                            .offset(y: pageH * 0.52 + 10)
                            .opacity(Double(appear))

                        // Center hub
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [coverColor, coverColor.opacity(0.5)],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 14
                                )
                            )
                            .frame(width: 22, height: 22)
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                            .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
                            .opacity(Double(appear))
                            .zIndex(1)

                        // Pages arranged in circle
                        ForEach(Array(notebook.pages.enumerated()), id: \.element.id) { index, page in
                            let totalRot = rotation + dragRotation
                            let rawAngle = sliceAngle * Double(index) + totalRot
                            let normA = carouselNormAngle(rawAngle)
                            let rad = rawAngle * .pi / 180.0
                            let currentR = Double(radius) * Double(appear)

                            let x = sin(rad) * currentR
                            let z = cos(rad) * currentR

                            // Cosine depth: 1 at front (0°), 0 at back (180°)
                            let cosVal = cos(normA * .pi / 180.0)
                            let depth01 = (cosVal + 1.0) / 2.0

                            // Sharp falloff — only ~2 front pages fully visible
                            let vis = pow(depth01, 2.5)
                            let pageScale = 0.25 + vis * 0.75
                            let pageOpacity = max(0.06, vis)

                            // Page + fold tab
                            VStack(spacing: 0) {
                                CarouselPagePanel(
                                    page: page,
                                    pageNumber: index + 1,
                                    width: pageW,
                                    height: pageH
                                )

                                // Fold tab connecting to center
                                ZStack(alignment: .top) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(
                                            LinearGradient(
                                                colors: [coverColor.opacity(0.55), coverColor.opacity(0.15)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                    Rectangle()
                                        .fill(Color.black.opacity(0.2))
                                        .frame(height: 1.5)
                                }
                                .frame(width: pageW * 0.55, height: 10)
                            }
                            .scaleEffect(pageScale * (0.5 + 0.5 * appear))
                            .offset(x: CGFloat(x))
                            .opacity(pageOpacity * Double(appear))
                            .zIndex(depth01 * 100)
                            .rotation3DEffect(
                                .degrees(-rawAngle),
                                axis: (x: 0, y: 1, z: 0),
                                perspective: 0.4
                            )
                        }
                    }
                    // Top-down tilt
                    .rotation3DEffect(
                        .degrees(22),
                        axis: (x: 1, y: 0, z: 0),
                        perspective: 0.5
                    )
                    .frame(height: pageH * 1.35)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 5)
                            .onChanged { value in
                                dragRotation = Double(value.translation.width) * 0.5
                            }
                            .onEnded { value in
                                let vel = Double(value.predictedEndTranslation.width - value.translation.width) * 0.2
                                rotation += dragRotation + vel
                                dragRotation = 0

                                let nearest = round(rotation / sliceAngle) * sliceAngle
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.78)) {
                                    rotation = nearest
                                }
                            }
                    )

                    Spacer()

                    // Page indicator
                    let idx = frontPageIndex(pageCount: pageCount, sliceAngle: sliceAngle)
                    Text("Page \(idx + 1) of \(pageCount)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.bottom, 24)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                appear = 1
            }
        }
    }

    private func carouselNormAngle(_ angle: Double) -> Double {
        var a = angle.truncatingRemainder(dividingBy: 360)
        if a > 180 { a -= 360 }
        if a < -180 { a += 360 }
        return a
    }

    private func frontPageIndex(pageCount: Int, sliceAngle: Double) -> Int {
        guard pageCount > 0, sliceAngle > 0 else { return 0 }
        let total = rotation + dragRotation
        let norm = total.truncatingRemainder(dividingBy: 360)
        let adjusted = norm < 0 ? norm + 360 : norm
        let idx = Int(round(adjusted / sliceAngle)) % pageCount
        return (pageCount - idx) % pageCount
    }

    private func addPage() {
        notebook.pages.append(Page(text: ""))
    }
}

// MARK: - Carousel Page Panel

struct CarouselPagePanel: View {
    let page: Page
    let pageNumber: Int
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Paper
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: "FAFAF7"))
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)

            // Paper texture
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.3), Color.clear, Color.black.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Border
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black.opacity(0.06), lineWidth: 0.5)

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text("\(pageNumber)")
                    .font(.system(size: 11, weight: .medium, design: .serif))
                    .foregroundColor(Color(hex: "B0ADA8"))
                    .frame(maxWidth: .infinity, alignment: .trailing)

                if !page.text.isEmpty {
                    Text(page.text)
                        .font(.system(size: 12, design: .serif))
                        .foregroundColor(Color(hex: "2D2D2D"))
                        .lineLimit(nil)
                } else {
                    // Ruled lines
                    VStack(spacing: height * 0.06) {
                        ForEach(0..<10, id: \.self) { _ in
                            Rectangle()
                                .fill(Color(hex: "E0DDD8").opacity(0.5))
                                .frame(height: 0.5)
                        }
                    }
                    .padding(.top, 6)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .frame(width: width, height: height)
    }
}

#Preview {
    ContentView()
}
