//
//  URLExt.swift
//  HeapchatSDK
//
//  Created by Aman Kumar on 26/08/25.
//

import Foundation

extension String {
    func toURL() -> URL? {
        URL(string: self)
    }
}

extension URL {
    var cacheKey: String? {
        let lastComponent = self.deletingPathExtension().lastPathComponent
        let ext = self.pathExtension
        Log.info("Last component: \(lastComponent), Extension: \(ext)")
        return ext.isEmpty ? lastComponent : "\(lastComponent).\(ext)"
    }
}
