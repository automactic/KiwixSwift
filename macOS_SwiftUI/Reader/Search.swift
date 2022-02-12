//
//  Search.swift
//  Kiwix for macOS
//
//  Created by Chris Li on 11/6/21.
//  Copyright © 2021 Chris Li. All rights reserved.
//

import Combine
import CoreData
import SwiftUI

import Defaults

/// Search interface in the sidebar.
struct Search: View {
    @Binding var url: URL?
    @State private var selectedSearchText: String?
    @StateObject private var viewModel = ViewModel()
    @Default(.recentSearchTexts) private var recentSearchTexts: [String]
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\.size, order: .reverse)],
        predicate: NSPredicate(format: "fileURLBookmark != nil")
    ) private var zimFiles: FetchedResults<ZimFile>
    @State private var showingPopover = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                SearchField(searchText: $viewModel.searchText)
                Spacer()
                Button {
                    showingPopover = true
                } label: {
                    if allIncluded {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    } else {
                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    }
                }
                .buttonStyle(.borderless)
                .disabled(zimFiles.count == 0)
                .help("Filter search results by zim files")
                .foregroundColor(zimFiles.count > 0 ? .blue : .gray)
                .popover(isPresented: $showingPopover) {
                    SearchFilter().frame(width: 250, height: 200)
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 6)
            if viewModel.searchText.isEmpty, !recentSearchTexts.isEmpty {
                List(selection: $selectedSearchText) {
                    Section("Recent Search") {
                        ForEach(recentSearchTexts, id: \.self) { searchText in
                            Text(searchText)
                        }
                    }
                }.onChange(of: selectedSearchText) { self.updateCurrentSearchText($0) }
            } else if !viewModel.searchText.isEmpty, !viewModel.results.isEmpty {
                List(viewModel.results, id: \.url, selection: $url) { searchResult in
                    Text(searchResult.title)
                }.onChange(of: url) { _ in self.updateRecentSearchTexts(viewModel.searchText) }
            } else if !viewModel.searchText.isEmpty, viewModel.results.isEmpty, !viewModel.inProgress {
                List { Text("No Result") }
            } else {
                List { }
            }
        }
    }
    
    var allIncluded: Bool {
        zimFiles.map { $0.includedInSearch }.reduce(true) { $0 && $1 }
    }
    
    private func updateCurrentSearchText(_ searchText: String?) {
        guard let searchText = searchText else { return }
        viewModel.searchText = searchText
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            selectedSearchText = nil
        }
    }
    
    private func updateRecentSearchTexts(_ searchText: String) {
        guard !searchText.isEmpty else { return }
        var recentSearchTexts = self.recentSearchTexts
        recentSearchTexts.removeAll { $0 == searchText }
        recentSearchTexts.insert(searchText, at: 0)
        self.recentSearchTexts = recentSearchTexts
    }
}

private class ViewModel: NSObject, ObservableObject, NSFetchedResultsControllerDelegate {
    @Published var searchText: String = ""  // text in the search field
    @Published private var zimFileIDs: [UUID]  // ID of zim files that are included in search
    @Published private(set) var inProgress = false
    @Published private(set) var results = [SearchResult]()
    
    private let fetchedResultsController: NSFetchedResultsController<ZimFile>
    private var searchSubscriber: AnyCancellable?
    private var searchTextSubscriber: AnyCancellable?
    private let queue = OperationQueue()
    
    override init() {
        // initilize fetched results controller
        let predicate = NSPredicate(format: "includedInSearch == true AND fileURLBookmark != nil")
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: ZimFile.fetchRequest(predicate: predicate),
            managedObjectContext: Database.shared.container.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        // initilze zim file IDs
        try? fetchedResultsController.performFetch()
        zimFileIDs = fetchedResultsController.fetchedObjects?.map { $0.fileID } ?? []
        
        super.init()
        
        // additional configurations
        queue.maxConcurrentOperationCount = 1
        fetchedResultsController.delegate = self
        
        // subscribers
        searchSubscriber = Publishers.CombineLatest($zimFileIDs, $searchText)
            .debounce(for: 0.2, scheduler: queue, options: nil)
            .receive(on: DispatchQueue.main, options: nil)
            .sink { zimFileIDs, searchText in
                self.updateSearchResults(searchText, Set(zimFileIDs))
            }
        searchTextSubscriber = $searchText.sink { searchText in self.inProgress = true }
    }
    
    private func updateSearchResults(_ searchText: String, _ zimFileIDs: Set<UUID>) {
        queue.cancelAllOperations()
        let zimFileIDs = Set(zimFileIDs.map { $0.uuidString.lowercased() })
        let operation = SearchOperation(searchText: searchText, zimFileIDs: zimFileIDs)
        operation.completionBlock = { [unowned self] in
            guard !operation.isCancelled else { return }
            DispatchQueue.main.sync {
                self.results = operation.results
                self.inProgress = false
            }
        }
        queue.addOperation(operation)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        zimFileIDs = fetchedResultsController.fetchedObjects?.map { $0.fileID } ?? []
    }
}

struct Search_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            Search(url: .constant(nil))
        }.frame(width: 250, height: 550).listStyle(.sidebar)
    }
}
