//
//  LibraryView.swift
//  Kiwix
//
//  Created by Chris Li on 11/23/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import Combine
import SwiftUI
import RealmSwift

@available(iOS 14.0, *)
class LibraryViewController_iOS14: UIHostingController<LibraryView> {
    convenience init() {
        self.init(rootView: LibraryView())
        rootView.dismiss =  { [unowned self] in
            self.dismiss(animated: true)
        }
        modalPresentationStyle = .overFullScreen
    }
}

@available(iOS 14.0, *)
struct LibraryView: View {
    @ObservedObject private var viewModel = ViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    var dismiss: (() -> Void) = {}
    
    var body: some View {
        let itemsPerCategory = horizontalSizeClass == .regular ? 6 : 4
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 300))], spacing: 10) {
                    ForEach(viewModel.result.categories, id: \.rawValue.hash) { category in
                        let header = HStack(alignment: .firstTextBaseline) {
                            Text(category.description).font(.title2).fontWeight(.bold)
                            Spacer()
                            if viewModel.result.counts[category, default: 0] > itemsPerCategory {
                                NavigationLink(destination: Text("Second View")) {
                                    HStack(spacing: 4) {
                                        Text("See All")
                                        Image(systemName: "chevron.right")
                                    }.font(Font.footnote.weight(.medium))
                                }
                            }
                        }
                        let zimFiles = viewModel.result.metaData[category, default: []].prefix(itemsPerCategory)
                        Section(header: header) {
                            ForEach(zimFiles) { zimFile in
                                ZimFileCell(zimFile) {}
                            }
                        }
                    }
                }.padding()
            }
            .navigationTitle("Library")
            .toolbar { ToolbarItem(placement: .navigationBarLeading) {
                Button(action: dismiss, label: { Text("Done").bold()})
            }}
            .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
        }.navigationViewStyle(StackNavigationViewStyle())
    }
    
    struct QueryResult {
        private(set) var categories = [ZimFile.Category]()
        private(set) var metaData = [ZimFile.Category: [ZimFile]]()
        private(set) var counts = [ZimFile.Category: Int]()
        
        init(results: Results<ZimFile>? = nil) {
            guard let results = results else { return }
            for zimFile in results {
                counts[zimFile.category, default: 0] += 1
                guard metaData[zimFile.category, default: []].count < 6 else { continue }
                metaData[zimFile.category, default: []].append(zimFile)
            }
            categories = Array(metaData.keys).sorted()
        }
    }

    class ViewModel: ObservableObject {
        private let queue = DispatchQueue(label: "org.kiwix.libraryUI", qos: .userInitiated)
        private let database: Realm?
        private var zimFilesPipeline: AnyCancellable? = nil
        @Published var result = QueryResult()
        
        init() {
            self.database = try? Realm(configuration: Realm.defaultConfig)
            
            let predicate = NSPredicate(format: "languageCode == %@", "en")
            zimFilesPipeline = database?.objects(ZimFile.self)
                .filter(predicate)
                .sorted(byKeyPath: "size", ascending: false)
                .collectionPublisher
                .subscribe(on: queue)
                .freeze()
                .map { QueryResult(results: $0) }
                .receive(on: DispatchQueue.main)
                .catch { _ in Just(QueryResult()) }
                .assign(to: \.result, on: self)
        }
        
        deinit {
            zimFilesPipeline?.cancel()
        }
    }
}
