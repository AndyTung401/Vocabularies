//
//  File.swift
//  Translator
//
//  Created by 董承威 on 2024/2/18.
//

import SwiftUI
import ColorGrid

extension Color: Codable {
  init(hex: String) {
    let rgba = hex.toRGBA()
    
    self.init(.sRGB,
              red: Double(rgba.r),
              green: Double(rgba.g),
              blue: Double(rgba.b),
              opacity: Double(rgba.alpha))
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let hex = try container.decode(String.self)
    
    self.init(hex: hex)
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(toHex)
  }
  
  var toHex: String? {
    return toHex()
  }
  
  func toHex(alpha: Bool = false) -> String? {
    guard let components = cgColor?.components, components.count >= 3 else {
      return nil
    }
    
    let r = Float(components[0])
    let g = Float(components[1])
    let b = Float(components[2])
    var a = Float(1.0)
    
    if components.count >= 4 {
      a = Float(components[3])
    }
    
    if alpha {
      return String(format: "%02lX%02lX%02lX%02lX",
                    lroundf(r * 255),
                    lroundf(g * 255),
                    lroundf(b * 255),
                    lroundf(a * 255))
    }
    else {
      return String(format: "%02lX%02lX%02lX",
                    lroundf(r * 255),
                    lroundf(g * 255),
                    lroundf(b * 255))
    }
  }
}

extension String {
  func toRGBA() -> (r: CGFloat, g: CGFloat, b: CGFloat, alpha: CGFloat) {
    var hexSanitized = self.trimmingCharacters(in: .whitespacesAndNewlines)
    hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
    
    var rgb: UInt64 = 0
    
    var r: CGFloat = 0.0
    var g: CGFloat = 0.0
    var b: CGFloat = 0.0
    var a: CGFloat = 1.0
    
    let length = hexSanitized.count
    
    Scanner(string: hexSanitized).scanHexInt64(&rgb)
    
    if length == 6 {
      r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
      g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
      b = CGFloat(rgb & 0x0000FF) / 255.0
    }
    else if length == 8 {
      r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
      g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
      b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
      a = CGFloat(rgb & 0x000000FF) / 255.0
    }
    
    return (r, g, b, a)
  }
}

struct list: Hashable, Identifiable, Codable {
    var id = UUID()
    var name: String
    var color: Color
    var icon: String
    var element: [elementInlist]
    
    struct elementInlist: Hashable, Identifiable, Codable {
        var id = UUID()
        var string: String
        var starred: Bool
        var checked: Bool
    }
}

let icons = ["list.bullet", "bookmark.fill", "mappin", "graduationcap.fill", "backpack.fill", "pencil.and.ruler.fill", "doc.fill", "book.fill", "note.text", "textformat.alt", "highlighter", "book.pages.fill"]


struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.editMode) private var editMode
    let userDefaults = UserDefaults.standard
    @State private var searchbarItem = ""
    @State private var isSearching = false
    @State private var newItem = ""
    @State private var addingNewWordAlert = false
    @State private var showSortFilterAlert = false
    @State private var showDict = false
    @State private var sortingMode: Int = 0 //0: none, 1: ascending, 2: descending
    @State private var showPopUp = false
    @State private var editingListIdex: Int = 0
    @State private var listFilterOption: Int = 0 //0: none, 1: starred, 2: unstarred
    @State private var starredOnTop = false
    @State private var checkedOnBottom = false
    @State private var showCheckedItems = true
    @State var Lists: [list] = [list(name: "An example list", color: .blue, icon: "list.bullet", element: [list.elementInlist(string: "This is a sample list", starred: false, checked: false),
                                                                                                           list.elementInlist(string: "Swipe left to remove/star an item", starred: false, checked: false),
                                                                                                           list.elementInlist(string: "Swipe right to chack an item", starred: false, checked: false),
                                                                                                           list.elementInlist(string: "Tap and Hold to rearrange", starred: false, checked: false),
                                                                                                           list.elementInlist(string: "↓ Tap on it for definitions", starred: false, checked: false),
                                                                                                           list.elementInlist(string: "Apple", starred: false, checked: false),
                                                                                                           list.elementInlist(string: "Try the search bar", starred: false, checked: false)]),
                                list(name: "Tap on the icon to customize", color: .orange, icon: "mappin", element: [list.elementInlist(string: "Constitude", starred: false, checked: false),
                                                                                                                     list.elementInlist(string: "Provision", starred: false, checked: false),
                                                                                                                     list.elementInlist(string: "Convince", starred: false, checked: false),
                                                                                                                     list.elementInlist(string: "Appropriate", starred: false, checked: false),
                                                                                                                     list.elementInlist(string: "Delegate", starred: false, checked: false),
                                                                                                                     list.elementInlist(string: "Adequate", starred: false, checked: false),
                                                                                                                     list.elementInlist(string: "Seduce", starred: false, checked: false),
                                                                                                                     list.elementInlist(string: "Abbreviate", starred: false, checked: false)])]
    
    func sortingBool (_ a: Bool, _ b: Bool, _ method: Int, _ groupingOnTop: Bool) -> Bool {
        if !groupingOnTop {
            return false
        } else if !a && b {
            return true
        } else {
            return false
        }
    }
    
    func sorting(_ a: list.elementInlist, _ b: list.elementInlist, _ method: Int) -> Bool {
        if method == 0 {
            return false
        } else if method == 1 {
            return a.string < b.string
        } else if method == 2 {
            return a.string > b.string
        } else {
            return false
        }
    }
    
    func filtering(_ a: list.elementInlist, _ method: Int) -> Bool {
        if !showCheckedItems && a.checked {
            return false
        } else {
            if method == 1 {
                return a.starred
            } else if method == 2 {
                return !a.starred
            } else {
                return true
            }
        }
    }
    
    func createListView(listIndexInLists: Int) -> some View {
        ZStack {
            List {
                ForEach(Array(Lists[listIndexInLists].element.enumerated().filter {filtering($0.1, listFilterOption)}.sorted(by: {sorting($0.1, $1.1, sortingMode)}).sorted(by: {sortingBool($0.1.checked, $1.1.checked, listFilterOption, checkedOnBottom)}).sorted(by: {sortingBool(!$0.1.starred, !$1.1.starred, listFilterOption, starredOnTop)})), id: \.element.id) { itemIndex, item in
                    if item.string.contains(searchbarItem) || searchbarItem == ""{
                        HStack {
                            Image(systemName: item.checked ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(item.checked ? .green : .gray)
                                .font(.system(size: 20))
                                .onTapGesture {
                                    toggleChecked(listIndexInLists, itemIndex)
                                }
                            HStack {
                                Text(item.string)
                                    .opacity(item.checked ? 0.4 : 1)
                                    .strikethrough(item.checked && !item.starred)
                                    .bold(item.starred)
                                    .underline(item.starred)
                                    Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                showDefinition(item.string)
                            }
                            Image(systemName: item.starred ? "star.fill" : "star")
                                .foregroundStyle(.yellow)
                                .font(.system(size: item.starred ? 21 : 19))
                                .fontWeight(.thin)
                                .frame(width: 25)
                                .onTapGesture {
                                    toggleStarred(listIndexInLists, itemIndex)
                                }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                toggleChecked(listIndexInLists, itemIndex)
                            } label: {
                                Image(systemName: "checkmark.circle")
                            }
                            .tint(.green)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                toggleStarred(listIndexInLists, itemIndex)
                            } label: {
                                Image(systemName: "star")
                            }
                            .tint(.yellow)
                            Button(role: .destructive) {
                                Lists[listIndexInLists].element.remove(at: itemIndex)
                            } label: {
                                Image(systemName: "trash")
                            }
                        }
                        .contentShape(Rectangle())
                        .alert("Turn off grouping, sorting, and filtering to movme items", isPresented: $showSortFilterAlert) {
                            Button {
                                showSortFilterAlert = false
                            } label: {
                                Text("OK")
                            }
                        }
                    }
                }
                .onMove(perform: { indices, newOffset in
                    if sortingMode != 0 || listFilterOption != 0 {
                        showSortFilterAlert = true
                    }
                    Lists[listIndexInLists].element.move(fromOffsets: indices, toOffset: newOffset)
                    isSearching = false
                    searchbarItem = ""
                })
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .searchable(text: $searchbarItem, isPresented: $isSearching, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search for something...")
            
            VStack {
                Spacer()
                if !isSearching && !addingNewWordAlert {
                    Text("\(Lists[listIndexInLists].element.count) items")
                        .font(.callout)
                        .foregroundStyle(Color.gray)
                        .padding()
                }
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        if isSearching && !searchbarItem.isEmpty && !Lists[listIndexInLists].element.contains(where: {$0.string == searchbarItem} ) {
                            Lists[listIndexInLists].element.append(list.elementInlist(string: searchbarItem, starred:false, checked: false))
                            searchbarItem = ""
                        } else if !isSearching || isSearching && searchbarItem.isEmpty {
                            addingNewWordAlert = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.cyan.gradient)
                    }
                    .opacity(addingNewWordAlert ? 0 : 1)
                    .padding()
                    .alert("Append a new item", isPresented: $addingNewWordAlert) {
                        TextField("Enter something", text: $newItem)
                        Button("OK") {
                            if !newItem.isEmpty && !Lists[listIndexInLists].element.contains(where: {$0.string == newItem} ){
                                Lists[listIndexInLists].element.append(list.elementInlist(string: newItem, starred:false, checked: false))
                            }
                            newItem = ""
                        }
                        Button("Cancel", role: .cancel) {
                            addingNewWordAlert = false
                            newItem = ""
                        }
                    }
                }
            }
        }
        .animation(addingNewWordAlert == false ? .easeInOut(duration: 0.2) : .none, value: addingNewWordAlert)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Menu {
                        Picker(selection: $listFilterOption) {
                            Text("None").tag(0)
                            Text("Show starred only").tag(1)
                            Text("Show NON-starred only").tag(2)
                        } label: {
                            EmptyView()
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                        Text("\(["", "Starred only", "NON-starred only"][listFilterOption])")
                    }//filter menu
                    
                    Menu {
                        Button {
                            starredOnTop.toggle()
                        } label: {
                            Label(starredOnTop ? "Ungroup starred items" : "Group starred items", systemImage: starredOnTop ? "square.slash" : "rectangle.3.group")
                        }
                        Button {
                            checkedOnBottom.toggle()
                        } label: {
                            Label(checkedOnBottom ? "Ungroup checked items" : "Group checked items", systemImage: checkedOnBottom ? "square.slash" : "rectangle.3.group")
                        }
                    } label: {
                        Label("Grouping", systemImage: "rectangle.3.group")
                        Text("\(starredOnTop ? "Stars" : "")\(starredOnTop && checkedOnBottom ? " & " : "")\(checkedOnBottom ? "Checkmarks" : "")")
                    }//grouping menu
                    
                    Menu {
                        Picker(selection: $sortingMode) {
                            Text("Manual").tag(0)
                            Text("Ascending (A→Z)").tag(1)
                            Text("Descending (Z→A)").tag(2)
                        } label: {
                            EmptyView()
                        }
                    } label: {
                        Label("Sorting", systemImage: "arrow.up.arrow.down")
                        Text("\(["Manual", "Ascending", "Descending"][sortingMode])")
                    }//sorting menu
                    
                    Divider()
                    
                    Button {
                        showCheckedItems.toggle()
                    } label: {
                        Text("\(showCheckedItems ? "Hide" : "Show") checked items")
                        Image(systemName: showCheckedItems ? "eye.slash" : "eye")
                    }

                    
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section {
                        ForEach(Array(Lists.enumerated()), id: \.element.id) { listIndex, list in
                                NavigationLink{
                                    createListView(listIndexInLists: listIndex)
                                        .navigationTitle(list.name)
                                } label: {
                                    HStack {
                                        Image(systemName: "circle.fill")
                                            .foregroundStyle(list.color)
                                            .font(.largeTitle)
                                            .overlay {
                                                Image(systemName: list.icon)
                                                    .font(.headline)
                                                    .foregroundStyle(.white)
                                            }
                                            .padding(-1)
                                            .padding(.leading, -3)
                                            .onTapGesture {
                                                editingListIdex = listIndex
                                                showPopUp = true
                                            }//on tap gesture
                                        Text(list.name)
                                            .font(.body)
                                        Spacer()
                                        Text("\(Lists[listIndex].element.count)")
                                            .foregroundStyle(.gray)
                                    }//Hstack
                                    .swipeActions(allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            Lists.remove(at: listIndex)
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                    }//swipe actions
                                }
                        }//ForEach
                        .onMove(perform: {indicies, newOffest in
                            moveList(from: indicies, to: newOffest)
                            isSearching = false
                            searchbarItem = ""
                        })
                    } header: {
                        HStack{
                            Text("My Lists")
                                .font(.title)
                                .foregroundStyle(colorScheme == .dark ? Color(.white) : Color(.black))
                                .padding(.bottom, 5)
                                .bold()
                            Text("\(editingListIdex)")
                                .foregroundStyle(colorScheme == .dark ? Color(.black) : Color(.systemGray6))
                            Spacer()
                            Button {
                                editingListIdex = Lists.count
                                Lists.append(list(name: "New List", color: .red, icon: "list.bullet", element: []))
                                showPopUp.toggle()
                            } label: {
                                Image(systemName: "plus")
                            }
                            EditButton().padding(5)
                        }.textCase(nil)
                    }
                }
                .searchable(text: $searchbarItem, isPresented: $isSearching, placement: .navigationBarDrawer(displayMode: .always), prompt: "Look up something...")
                .onSubmit(of: .search) {
                    showDefinition(searchbarItem)
                    isSearching = false
                    searchbarItem = ""
                }
                
                if !isSearching {
                    Text("\(Lists.count) lists")
                        .font(.callout)
                        .foregroundStyle(Color.gray)
                        .padding()
                }
            }//Vstack
            .background(colorScheme == .dark ? Color.black : Color(UIColor.systemGray6))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        return
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }

                }
            }
            
        }
        .sheet(isPresented: $showPopUp) {
            VStack(spacing: 15) {
                VStack(spacing: 10) {
                    Circle()
                        .fill(Lists[editingListIdex].color.gradient)
                        .shadow(color: colorScheme == .dark ? Color(white: 0, opacity: 0.33) : Lists[editingListIdex].color.opacity(0.3), radius: 10, x: 0, y: 0)
                        .frame(width: 100, height: 100)
                        .padding(.vertical, 10)
                        .animation(.easeInOut(duration: 0.2), value: Lists[editingListIdex].color)
                        .overlay {
                            Image(systemName: Lists[editingListIdex].icon)
                                .bold()
                                .foregroundStyle(colorScheme == .dark ? Color(.white) : Color(.systemGray6))
                                .font(.system(size: 50))
                                .animation(.easeInOut(duration: 0.1), value: Lists[editingListIdex].icon)
                        }
                        
                    TextField(Lists[editingListIdex].name, text: $Lists[editingListIdex].name)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Lists[editingListIdex].color)
                        .font(.title2)
                        .bold()
                        .padding(.vertical, 15)
                        .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(
                                            Color(colorScheme == .dark ? .systemGray4 : .systemGray6)
                                        )
                        )
                    
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .circular)
                        .fill(
                            Color(colorScheme == .dark ? .systemGray5 : .white)
                        )
                }
                .padding(.top, 25)
                CGPicker(
                    colors: [.red, .orange, .yellow, .green, .cyan, .blue, .indigo, .pink, .purple, .brown, .gray, Color(.init(red: 0.8196078431, green: 0.6588235294, blue: 0.6235294118))],
                    selection: $Lists[editingListIdex].color
                )
                .padding(20)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .circular)
                        .fill(
                            Color(colorScheme == .dark ? .systemGray5 : .white)
                        )
                }
                VStack(spacing: 15) {
                    ForEach(0..<icons.count/6) { row in // create number of rows
                        HStack(spacing: 5) {
                            ForEach(0..<6) { column in // create 3 columns
                                ZStack {
                                    Image(systemName: icons[row * 6 + column])
                                        .foregroundStyle(Color(colorScheme == .dark ? .white : .init(hue: 0, saturation: 0, brightness: 0.3)))
                                        .bold()
                                        .font(.title3)
                                        .frame(width: 40, height: 40)
                                        .background {
                                            Circle()
                                                .fill(
                                                    Color(colorScheme == .dark ? .systemGray4 : .systemGray6)
                                                )
                                        }
                                        .onTapGesture {
                                            Lists[editingListIdex].icon = icons[row * 6 + column]
                                        }
                                    if Lists[editingListIdex].icon == icons[row * 6 + column] {
                                        Circle()
                                            .fill(Color.clear)
                                            .stroke(Color(colorScheme == .dark ? .systemGray2 : .systemGray3), lineWidth: 3)
                                    }
                                }
                                .frame(width: 50, height: 50)
                            }
                        }
                    }
                }
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .circular)
                        .fill(
                            Color(colorScheme == .dark ? .systemGray5 : .white)
                        )
                }
                Spacer()
            }//vstack
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .presentationBackground(colorScheme == .dark ? Color(.systemGray6):Color(.systemGray6))
            .presentationDragIndicator(.visible)
            .presentationDetents([.fraction(0.9)])
            .presentationCornerRadius(15)
        }//sheet
    }

    func moveList(from source: IndexSet, to destination: Int) {
        Lists.move(fromOffsets: source, toOffset: destination)
    }
    
    func showDefinition(_ word: String){
        UIApplication
            .shared.connectedScenes.map({$0 as? UIWindowScene}).compactMap({$0}).first?.windows.first?
            .rootViewController?.present(UIReferenceLibraryViewController(term: word), animated: true, completion: nil)
    }
    
    func toggleStarred(_ listIndexInLists: Int, _ itemIndex: Int){
        Lists[listIndexInLists].element[itemIndex].starred.toggle()
    }
    
    func toggleChecked(_ listIndexInLists: Int, _ itemIndex: Int){
        Lists[listIndexInLists].element[itemIndex].checked.toggle()
    }
}


#Preview {
    ContentView()
}
