//
//  PastieShortcuts.swift
//  PastieShortcuts
//
//  Created by Tanner Bennett on 11/6/23.
//

import AppIntents
import UIKit

struct PastieShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: SaveToPastie(), phrases: ["Save Clipboard to \(.applicationName)"])
    }
}

struct SaveToPastie: AppIntent {
    enum FeedbackLevel: String, AppEnum {
        static var typeDisplayRepresentation: TypeDisplayRepresentation = "Feedback Level"
        static var typeDisplayName: LocalizedStringResource = "Feedback Level"
        
        case none
        case onlyErrors
        case all
        
        static var caseDisplayRepresentations: [SaveToPastie.FeedbackLevel: DisplayRepresentation] = [
            .none: "Nothing",
            .onlyErrors: "Problems Saving",
            .all: "What Was Saved"
        ]
    }
    
    static var title: LocalizedStringResource = "Save Clipboard with Pastie"
    
    @Parameter(title: "Notify me about")
    var feedbackLevel: FeedbackLevel
    
    func perform() async throws -> some IntentResult {
        let db: PDBManager = try await .open()
        
        if UIPasteboard.general.hasStrings {
            let strings = UIPasteboard.general.strings!
            await db.add(UIPasteboard.general.strings!)
            return .result(dialog: "Saved \(strings.count) items(s)")
        }
        else if UIPasteboard.general.hasURLs {
            let urls = UIPasteboard.general.urls!.map(\.absoluteString)
            await db.add(urls)
            return .result(dialog: "Saved \(urls.count) URL(s)")
        }
        else {
            return .result(dialog: "Nothing to copy")
        }
    }
}
