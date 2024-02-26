//
//  File.swift
//  Translator
//
//  Created by 董承威 on 2024/2/18.
//

import SwiftUI
import ColorGrid

struct list: Hashable, Codable, Identifiable {
    var id = UUID()
    var name: String
    var color: String
    var element: [elementInlist]
    
    struct elementInlist: Hashable, Codable, Identifiable {
        var id = UUID()
        var string: String
        var starred: Bool
        var done: Bool
    }
}

extension Color {
    static subscript(name: String) -> Color {
        switch name {
        case "red":
            return Color.red
        case "orange":
            return Color.orange
        case "yellow":
            return Color.yellow
        case "green":
            return Color.green
        case "cyan":
            return Color.cyan
        case "blue":
            return Color.blue
        case "indigo":
            return Color.indigo
        case "pink":
            return Color.pink
        case "purple":
            return Color.purple
        case "brown":
            return Color.brown
        case "gray":
            return Color.gray
        case "mint":
            return Color(.init(red: 0.8196078431, green: 0.6588235294, blue: 0.6235294118))
        default:
            return Color.accentColor
        }
    }
}


struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.editMode) private var editMode
    let userDefaults = UserDefaults.standard
    @State private var searchbarItem = ""
    @State private var isSearching = false
    @State private var newItem = ""
    @State private var addingNewListAlert = false
    @State private var addingNewWordAlert = false
    @State private var showDict = false
    @State private var sortingMode = 0 //0:none
    @State private var colorPicker: Color = .red
    @State private var showColorPicker = false
    @State private var editingListIdex = 0
    @State private var selectedIcon = ""
    @State var Lists: [list] = [list(name: "list1", color: "mint", element: [list.elementInlist(string: "This is a sample list", starred: false, done: false),
                                                              list.elementInlist(string: "You can swipe left to remove an item", starred: false, done: false),
                                                              list.elementInlist(string: "Tap and Hold to rearrange", starred: false, done: false),
                                                              list.elementInlist(string: "↓ Tap on a item to expand definitions", starred: false, done: false),
                                                              list.elementInlist(string: "Apple", starred: false, done: false)]),
                                list(name: "list2", color: "orange", element: [list.elementInlist(string: "Constitude", starred: false, done: false),
                                                              list.elementInlist(string: "Convince", starred: false, done: false),
                                                              list.elementInlist(string: "Delegate", starred: false, done: false),
                                                              list.elementInlist(string: "Abbreviate", starred: false, done: false)])]
    
    func createListView(listIndexInLists: Int) -> some View {
        ZStack {
            List {
                ForEach(Array(Lists[listIndexInLists].element.indices), id: \.self) { itemIndex in
                    if Lists[listIndexInLists].element[itemIndex].string.contains(searchbarItem) || searchbarItem == ""{
                        HStack {
                            Image(systemName: Lists[listIndexInLists].element[itemIndex].done ? "checkmark.circle.fill" : "circle").foregroundStyle(Lists[listIndexInLists].element[itemIndex].done ? .green : .gray)
                                .font(.system(size: 20))
                                .onTapGesture {
                                    toggleDone(listIndexInLists, itemIndex)
                                }
                            HStack{
                                Text(Lists[listIndexInLists].element[itemIndex].string)
                                    .opacity(Lists[listIndexInLists].element[itemIndex].done ? 0.4 : 1)
                                    .strikethrough(Lists[listIndexInLists].element[itemIndex].done)
                                Spacer()
                            }
                            .onTapGesture {
                                showDefinition(Lists[listIndexInLists].element[itemIndex].string)
                            }
                            Image(systemName: Lists[listIndexInLists].element[itemIndex].starred ? "star.fill" : "star").foregroundStyle(Color.yellow)
                                .font(.system(size: 20))
                                .onTapGesture {
                                    toggleStarred(listIndexInLists, itemIndex)
                                }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button {
                                toggleDone(listIndexInLists, itemIndex)
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
                    }
                }
                .onMove(perform: { indices, newOffset in
                    Lists[listIndexInLists].element.move(fromOffsets: indices, toOffset: newOffset)
                })
            }
            .scrollContentBackground(.hidden)
            .searchable(text: $searchbarItem, isPresented: $isSearching, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search for something...")
            
            VStack {
                Spacer()
                if !isSearching && !addingNewWordAlert{
                    Text("Total: \(Lists[listIndexInLists].element.count) items")
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
                        if isSearching && !searchbarItem.isEmpty {
                            Lists[listIndexInLists].element.append(list.elementInlist(string: searchbarItem, starred:false, done: false))
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
                    .alert("Add a word", isPresented: $addingNewWordAlert) {
                        TextField("Enter something", text: $newItem)
                        Button("OK") {
                            if !newItem.isEmpty {
                                Lists[listIndexInLists].element.append(list.elementInlist(string: newItem, starred:false, done: false))
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    return
                } label: {
                    Image(systemName: "ellipsis.circle")
                }

            }
        }
        .background(colorScheme == .dark ? Color.black : Color(UIColor.systemGray6))
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    Section {
                        ForEach(Array(Lists.indices), id: \.self){ listIndex in
                                NavigationLink{
                                    createListView(listIndexInLists: listIndex)
                                        .navigationTitle(Lists[listIndex].name)
                                } label: {
                                    HStack(spacing: 10) {
                                        Image(systemName: "circle.fill")
                                            .foregroundStyle(Color[Lists[listIndex].color])
                                            .font(.largeTitle)
                                        Text(Lists[listIndex].name)
                                            .font(.body)
                                    }
                                    .onTapGesture {
                                        showColorPicker = true
                                        editingListIdex = listIndex
                                    }
                                    .swipeActions(allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            Lists.remove(at: listIndex)
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                    }
                                }
                        }//ForEach
                        .onMove(perform: moveList)
                    } header: {
                        HStack{
                            Text("My Lists").font(.title).foregroundStyle(colorScheme == .dark ? Color(.white) : Color(.black)).padding(.bottom, 5)
                            Spacer()
                            Button {
                                addingNewListAlert.toggle()
                            } label: {
                                Image(systemName: "plus")
                            }
                            .alert("Add a list", isPresented: $addingNewListAlert) {
                                TextField("Enter a title", text: $newItem)
                                Button("OK") {addNewList()}
                                Button("Cancel", role: .cancel) {
                                    addingNewListAlert.toggle()
                                    newItem = ""
                                }
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
                
                if !isSearching && !addingNewListAlert{
                    Text("Total: \(Lists.count) lists")
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
            .sheet(isPresented: $showColorPicker) {
                VStack(spacing: 15) {
                    VStack {
                        Circle()
                            .foregroundStyle(Color[Lists[editingListIdex].color].gradient)
                            .frame(width: 100, height: 100)
                            .padding(.vertical, 5)
                        TextField(Lists[editingListIdex].name, text: $Lists[editingListIdex].name)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(Color[Lists[editingListIdex].color])
                            .font(.title2)
                            .bold()
                            .padding(.vertical, 15)
                            .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(
                                                Color(colorScheme == .dark ? .systemGray4 : .white)
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
                    CGPicker(
                        colors: [.red, .orange, .yellow, .green, .cyan, .blue, .indigo, .pink, .purple, .brown, .gray, Color(.init(red: 0.8196078431, green: 0.6588235294, blue: 0.6235294118))],
                        selection: $colorPicker
                    )
                    .padding()
                    .background {
                        RoundedRectangle(cornerRadius: 20, style: .circular)
                            .fill(
                                Color(colorScheme == .dark ? .systemGray5 : .white)
                            )
                    }
                }
                .background {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(colorScheme == .dark ? Color(.systemGray6):.white)
                }//vstack
                .padding()
            }//sheet
        }
    }
    
    
    func addNewList() -> Void{
        if !newItem.isEmpty {
            Lists.append(list(name: newItem, color: "blue", element: []))
            newItem = ""
        }
    }
    
//    func deleteList(at offsets: IndexSet) {
//        Lists.remove(atOffsets: offsets)
//    }

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
//        if Lists[listIndexInLists].element[itemIndex].starred && Lists[listIndexInLists].element[itemIndex].done {
//            Lists[listIndexInLists].element[itemIndex].done.toggle()
//        }
    }
    
    func toggleDone(_ listIndexInLists: Int, _ itemIndex: Int){
        Lists[listIndexInLists].element[itemIndex].done.toggle()
//        if Lists[listIndexInLists].element[itemIndex].starred && Lists[listIndexInLists].element[itemIndex].done {
//            Lists[listIndexInLists].element[itemIndex].starred.toggle()
//        }
    }
}


#Preview {
    ContentView()
}
