//
//  Untitled.swift
//  MacExplorer
//
//  Created by Garrett O'Carroll on 28/01/2026.
//
import SwiftUI
import Quartz

struct QuickLookPreview: NSViewRepresentable {
    let url: URL?
    
    func makeNSView(context: Context) -> QLPreviewView {
        let view = QLPreviewView()
        view.autostarts = true
        return view
    }
   

    func updateNSView(_ nsView: QLPreviewView, context: Context) {
        if let url = url {
            nsView.previewItem = url as NSURL
        } else {
            nsView.previewItem = nil
        }
    }
}

