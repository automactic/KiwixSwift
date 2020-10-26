//
//  ZimFilesViewModel.swift
//  Kiwix
//
//  Created by Chris Li on 10/25/20.
//  Copyright © 2020 Chris Li. All rights reserved.
//

import Combine
import RealmSwift

@available(iOS 14.0, *)
class ZimFilesViewModel: ObservableObject {
    @Published var onDeviceZimFiles = [ZimFile]()
    private var onDeviceZimFilesPipeline: AnyCancellable? = nil
    
    init() {
        do {
            let database = try Realm(configuration: Realm.defaultConfig)
            let predicate = NSPredicate(format: "stateRaw == %@", ZimFile.State.onDevice.rawValue)
            onDeviceZimFilesPipeline = database.objects(ZimFile.self)
                .filter(predicate)
                .sorted(byKeyPath: "size", ascending: false)
                .collectionPublisher
                .subscribe(on: DispatchQueue.main)
                .freeze()
                .map { Array($0) }
                .receive(on: DispatchQueue.main)
                .catch { _ in Just([]) }
                .assign(to: \.onDeviceZimFiles, on: self)
        } catch { }
    }
    
    deinit {
        onDeviceZimFilesPipeline?.cancel()
    }
}
