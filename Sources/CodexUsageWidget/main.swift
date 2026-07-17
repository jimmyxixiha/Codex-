import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSPanel?
    private var statusItem: NSStatusItem?
    private let store = UsageStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        createStatusItem()
        createWidgetWindow()
    }

    private func createStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = menuBarIcon()
        item.button?.imagePosition = .imageOnly

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "刷新用量", action: #selector(refreshUsage), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "显示/隐藏小组件", action: #selector(toggleWidget), keyEquivalent: "w"))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q"))
        item.menu = menu
        statusItem = item
    }

    private func menuBarIcon() -> NSImage? {
        let image = NSImage(named: "CodexUsageMenuIcon") ?? NSImage(systemSymbolName: "bolt.horizontal.circle", accessibilityDescription: "Codex 用量")
        image?.size = NSSize(width: 18, height: 18)
        image?.isTemplate = true
        return image
    }

    private func createWidgetWindow() {
        let size = NSSize(width: 356, height: 154)
        let screenFrame = bestScreen().visibleFrame
        let origin = NSPoint(x: screenFrame.minX + 18, y: screenFrame.maxY - size.height - 18)
        let rect = NSRect(origin: origin, size: size)

        let panel = NSPanel(
            contentRect: rect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)))
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false

        panel.ignoresMouseEvents = false
        panel.contentView = DraggableHostingView(rootView: UsageWidgetView(store: store))
        panel.orderFrontRegardless()
        window = panel
    }

    @objc private func refreshUsage() {
        store.reload()
    }

    @objc private func toggleWidget() {
        guard let window else { return }
        window.isVisible ? window.orderOut(nil) : window.orderFrontRegardless()
    }

    private func bestScreen() -> NSScreen {
        if let zeroScreen = NSScreen.screens.first(where: { $0.frame.contains(NSPoint(x: 0, y: 0)) }) {
            return zeroScreen
        }
        let mouse = NSEvent.mouseLocation
        if let screen = NSScreen.screens.first(where: { $0.frame.contains(mouse) }) {
            return screen
        }
        return NSScreen.main ?? NSScreen.screens.first!
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()

final class DraggableHostingView<Content: View>: NSHostingView<Content> {
    private var dragStartMouseLocation: NSPoint?
    private var dragStartWindowOrigin: NSPoint?

    override func mouseDown(with event: NSEvent) {
        dragStartMouseLocation = NSEvent.mouseLocation
        dragStartWindowOrigin = window?.frame.origin
    }

    override func mouseDragged(with event: NSEvent) {
        guard
            let window,
            let startMouse = dragStartMouseLocation,
            let startOrigin = dragStartWindowOrigin
        else {
            return
        }

        let currentMouse = NSEvent.mouseLocation
        let delta = NSPoint(
            x: currentMouse.x - startMouse.x,
            y: currentMouse.y - startMouse.y
        )
        window.setFrameOrigin(NSPoint(
            x: startOrigin.x + delta.x,
            y: startOrigin.y + delta.y
        ))
    }

    override func mouseUp(with event: NSEvent) {
        dragStartMouseLocation = nil
        dragStartWindowOrigin = nil
    }
}
