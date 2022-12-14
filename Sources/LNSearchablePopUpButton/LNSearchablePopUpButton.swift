//
//  LNSearchablePopUpButton.swift
//  LNSearchablePopUpButton
//
//  Created by Leo Natan on 04/12/2022.
//  Copyright © 2022 LeoNatan. All rights reserved.
//

import Cocoa
import ObjectiveC

fileprivate var smartIdentifierKey: Void?
fileprivate extension NSMenuItem {
	var smartIdentifier: UUID {
		get {
			if let rv = objc_getAssociatedObject(self, &smartIdentifierKey) as? UUID {
				return rv
			}
			
			let generated = UUID()
			objc_setAssociatedObject(self, &smartIdentifierKey, generated, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
			
			return generated
		}
		set {
			objc_setAssociatedObject(self, &smartIdentifierKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
		}
	}
	
	func smartEquals(_ other: NSMenuItem?) -> Bool {
		guard let other = other else { return false }
		return self == other || smartIdentifier == other.smartIdentifier
	}
}

fileprivate func copyMenuItems(from others: [NSMenuItem]) -> [NSMenuItem] {
	var rv = [NSMenuItem]()
	for other in others {
		let copy = other.copy() as! NSMenuItem
		copy.smartIdentifier = other.smartIdentifier
		rv.append(copy)
	}
	return rv
}

@objc @objcMembers public class LNSearchablePopUpButton: NSPopUpButton {
	public lazy var searchField: NSSearchField = {
		let searchField = NSSearchField()
		searchField.focusRingType = .none
		searchField.translatesAutoresizingMaskIntoConstraints = false
		
		return searchField
	}()
	
	fileprivate lazy var searchFieldContainer: NSView = {
		let searchFieldContainer = LNMenuTrackingView()
		searchFieldContainer.translatesAutoresizingMaskIntoConstraints = false
		searchFieldContainer.addSubview(searchField)
		NSLayoutConstraint.activate([
			searchField.leadingAnchor.constraint(equalTo: searchFieldContainer.leadingAnchor, constant: 4),
			searchFieldContainer.trailingAnchor.constraint(equalTo: searchField.trailingAnchor, constant: 4),
			searchField.topAnchor.constraint(equalTo: searchFieldContainer.topAnchor),
			searchFieldContainer.bottomAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 4),
		])
		return searchFieldContainer
	}()
	
	fileprivate lazy var searchBarItem: NSMenuItem = {
		let searchBarMenuItem = NSMenuItem()
		searchBarMenuItem.view = searchFieldContainer
		searchBarMenuItem.title = "Select…"
		searchBarMenuItem.isEnabled = false
		return searchBarMenuItem
	}()
	
	public var searchingLabelTitle: String = "Searching…" {
		didSet {
			searchingLabel.stringValue = searchingLabelTitle
			searchingLabelItem.title = searchingLabelTitle
		}
	}
	
	fileprivate var searchingLabelItemIsVisible: Bool = false {
		didSet {
			refreshMenuItems()
		}
	}
	
	fileprivate lazy var searchingLabel: NSTextField = {
		let searchingLabel = NSTextField(labelWithString: searchingLabelTitle)
		searchingLabel.font = NSFont.menuFont(ofSize: NSFont.systemFontSize)
		searchingLabel.textColor = NSColor.secondaryLabelColor
		searchingLabel.translatesAutoresizingMaskIntoConstraints = false
		return searchingLabel
	}()
	
	fileprivate lazy var searchingLabelItem: NSMenuItem = {
		let wrapper = NSView()
		wrapper.translatesAutoresizingMaskIntoConstraints = false
		wrapper.addSubview(searchingLabel)
		NSLayoutConstraint.activate([
			searchingLabel.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 13.5),
			wrapper.trailingAnchor.constraint(equalTo: searchingLabel.trailingAnchor),
			searchingLabel.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 3),
			wrapper.bottomAnchor.constraint(equalTo: searchingLabel.bottomAnchor, constant: 3),
		])
		
		let searchingLabelItem = NSMenuItem(title: searchingLabelTitle, action: nil, keyEquivalent: "")
		searchingLabelItem.view = wrapper
		searchingLabelItem.isEnabled = false
		
		return searchingLabelItem
	}()
	
	public var noResultsTitle: String = "No Results Found" {
		didSet {
			noResultsLabel.stringValue = noResultsTitle
			noResultsLabelItem.title = noResultsTitle
		}
	}
	
	fileprivate lazy var noResultsLabel: NSTextField = {
		let noResultsLabel = NSTextField(labelWithString: noResultsTitle)
		noResultsLabel.font = NSFont.menuFont(ofSize: NSFont.systemFontSize)
		noResultsLabel.textColor = NSColor.secondaryLabelColor
		noResultsLabel.translatesAutoresizingMaskIntoConstraints = false
		return noResultsLabel
	}()
	
	fileprivate lazy var noResultsLabelItem: NSMenuItem = {
		let wrapper = NSView()
		wrapper.translatesAutoresizingMaskIntoConstraints = false
		wrapper.addSubview(noResultsLabel)
		NSLayoutConstraint.activate([
			noResultsLabel.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 13.5),
			wrapper.trailingAnchor.constraint(equalTo: noResultsLabel.trailingAnchor),
			noResultsLabel.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 3),
			wrapper.bottomAnchor.constraint(equalTo: noResultsLabel.bottomAnchor, constant: 3),
		])
		
		let searchingLabelItem = NSMenuItem(title: noResultsTitle, action: nil, keyEquivalent: "")
		searchingLabelItem.view = wrapper
		searchingLabelItem.isEnabled = false
		
		return searchingLabelItem
	}()
	
	public convenience init() {
		self.init(frame: NSRect.zero, pullsDown: false)
	}
	
	override public convenience init(frame frameRect: NSRect) {
		self.init(frame: frameRect, pullsDown: false)
	}
	
	override init(frame buttonFrame: NSRect, pullsDown flag: Bool) {
		//Only pop up buttons are supported for now.
		super.init(frame: buttonFrame, pullsDown: false)
		
		commonInit()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		
		commonInit()
	}
	
	fileprivate func commonInit() {
		let menu = NSMenu()
		menu.items = [searchBarItem]
		self.menu = menu
		
		super.autoenablesItems = false
		
		menuObservations = [
			NotificationCenter.default.addObserver(forName: NSMenu.didSendActionNotification, object: menu, queue: nil, using: { [weak self] _ in
				self?.didSelectMenuItem()
			}),
		]
		
		searchFieldObservations = [
			NotificationCenter.default.addObserver(forName: NSTextField.textDidChangeNotification, object: searchField, queue: nil, using: { [weak self] _ in
				self?.searchFieldTextDidChange()
			}),
		]
		
		let handler: (Notification) -> Void = { [weak self] _ in
			self?.refreshMenuItems()
		}
		
		itemMenuItemsObservations = [
			NotificationCenter.default.addObserver(forName: NSMenu.didAddItemNotification, object: itemMenu, queue: nil, using: handler),
			NotificationCenter.default.addObserver(forName: NSMenu.didChangeItemNotification, object: itemMenu, queue: nil, using: handler),
			NotificationCenter.default.addObserver(forName: NSMenu.didRemoveItemNotification, object: itemMenu, queue: nil, using: handler),
		]
		
		searchMenuItemsObservations = [
			NotificationCenter.default.addObserver(forName: NSMenu.didAddItemNotification, object: searchMenu, queue: nil, using: handler),
			NotificationCenter.default.addObserver(forName: NSMenu.didChangeItemNotification, object: searchMenu, queue: nil, using: handler),
			NotificationCenter.default.addObserver(forName: NSMenu.didRemoveItemNotification, object: searchMenu, queue: nil, using: handler),
		]
	}
	
	fileprivate var selectedItemBeforeSearch: NSMenuItem? = nil
	
	@objc private func didSelectMenuItem() {
		if searchField.stringValue.count == 0 {
			selectedItemBeforeSearch = selectedItem
		} else {
			//User selected some search result, so forget the selected item before search
			if selectedItem?.smartEquals(selectedItemBeforeSearch) == false {
				selectedItemBeforeSearch = nil
			}
		}
	}
	
	public override var autoenablesItems: Bool {
		get {
			return false
		}
		set {
			super.autoenablesItems = false
		}
	}
	
	public var defaultTitle: String {
		get {
			return searchBarItem.title
		}
		set {
			searchBarItem.title = newValue
		}
	}
	
	public let itemMenu: NSMenu = NSMenu()
	public let searchMenu: NSMenu = NSMenu()
	public var performsSearchInItemMenuTitles = true
	
	fileprivate var menuObservations: [AnyObject]?
	fileprivate var searchFieldObservations: [AnyObject]?
	fileprivate var itemMenuItemsObservations: [AnyObject]?
	fileprivate var searchMenuItemsObservations: [AnyObject]?
	
	public func clearSearch() {
		searchField.stringValue = ""
		searchMenu.removeAllItems()
		
		refreshMenuItems()
	}
	
	public func finishSearch() {
		searchingLabelItemIsVisible = false
	}
	
	fileprivate func refreshMenuItems() {
		var menuItems: [NSMenuItem]
		if searchField.stringValue.count == 0 {
			menuItems = copyMenuItems(from: itemMenu.items)
		} else {
			menuItems = copyMenuItems(from: searchMenu.items)
			
			if searchingLabelItemIsVisible {
				menuItems.append(searchingLabelItem)
			} else if searchField.stringValue.count > 0 && searchMenu.items.count == 0 {
				menuItems.append(noResultsLabelItem)
			}
		}

		guard let menu = menu else {
			return
		}

		let items = menu.items

		for oldItem in items[1..<items.count] {
			menu.removeItem(oldItem)
		}

		for menuItem in menuItems {
			menuItem.state = .off
			menu.addItem(menuItem)
		}

		updateSelectionAndNotifyIfNeeded(previousSelection: selectedItem)
	}
	
	fileprivate func updateSelectionAndNotifyIfNeeded(previousSelection: NSMenuItem?) {
		guard selectionGroupingCount == 0 else {
			return
		}
		
		guard let menuItems = menu?.items else {
			return
		}
		
		if let currentlySelectedMenuItem = selectedItem, currentlySelectedMenuItem != searchBarItem {
			if let newSelectedMenuItem = menuItems.first(where: { $0.smartEquals(currentlySelectedMenuItem) }) {
				select(newSelectedMenuItem)
			} else {
				select(nil)
			}
		}
		
		if let selectedItemBeforeSearch = selectedItemBeforeSearch, let newSelectedMenuItem = menuItems.first(where: { $0.smartEquals(selectedItemBeforeSearch) }) {
			select(newSelectedMenuItem)
		} else if let previousSelection = previousSelection, let newSelectedMenuItem = menuItems.first(where: { $0.smartEquals(previousSelection) }) {
			select(newSelectedMenuItem)
		}
		
		if selectedItem?.smartEquals(previousSelection) == false {
			sendAction(action, to: target)
		}
	}
	
	public func searchFieldTextDidChange() {
		groupSelection {
			if let editor = searchField.currentEditor() {
				let selection = editor.selectedRange
				let wasFirstResponder = searchField.window?.firstResponder == editor
				menu?.perform(Selector(("highlightItem:")), with: nil)
				if wasFirstResponder {
					searchField.window?.makeFirstResponder(searchField)
					searchField.currentEditor()?.selectedRange = selection
				}
			}
			
			searchingLabelItemIsVisible = false
			
			guard searchField.stringValue.count > 0 else {
				if let selectedItemBeforeSearch = selectedItemBeforeSearch, let selectedItemBeforeSearchActual = menu?.items.first(where: { $0.smartEquals(selectedItemBeforeSearch) }) {
					select(selectedItemBeforeSearchActual)
				}
				
				return
			}
			
			if performsSearchInItemMenuTitles {
				removeAllSearchItems()
				
				let filtered = itemMenu.items.filter { $0.title.localizedCaseInsensitiveContains(searchField.stringValue) }
				for filteredItem in copyMenuItems(from: filtered) {
					searchMenu.addItem(filteredItem)
				}
				
				return
			}
			
			searchingLabelItemIsVisible = true
		}
	}
	
	fileprivate var selectionGroupingCount: Int = 0
	fileprivate func groupSelection(_ actions: () -> Void) {
		let previousSelection = selectedItem
		
		selectionGroupingCount += 1
		
		actions()
		
		selectionGroupingCount -= 1
		updateSelectionAndNotifyIfNeeded(previousSelection: previousSelection)
	}
}

@objc(_LNMenuTrackingView) fileprivate class LNMenuTrackingView: NSView {
	override var frame: NSRect {
		set {
			var rv = newValue
			if let superview = superview, let super2 = superview.superview {
				if rv.width < super2.frame.width {
					var superFrame = superview.frame
					superFrame.size.width = super2.frame.width
					superview.frame = superFrame
					
					rv = CGRect(x: rv.origin.x, y: rv.origin.y, width: super2.frame.width, height: rv.height)
				}
			}
			
			super.frame = rv
		}
		get {
			return super.frame
		}
	}
}

//MARK: Item management

extension LNSearchablePopUpButton {
	// Adding and removing items
	open override func addItem(withTitle title: String) {
		itemMenu.addItem(withTitle: title, action: nil, keyEquivalent: "")
	}
	
	open override func addItems(withTitles itemTitles: [String]) {
		itemTitles.forEach {
			addItem(withTitle: $0)
		}
	}
	
	open override func insertItem(withTitle title: String, at index: Int) {
		itemMenu.insertItem(withTitle: title, action: nil, keyEquivalent: "", at: index)
	}
	
	open override func removeItem(withTitle title: String) {
		let idx = itemMenu.indexOfItem(withTitle: title)
		guard idx != -1 else { return }
		itemMenu.removeItem(at: idx)
	}
	
	open override func removeItem(at index: Int) {
		itemMenu.removeItem(at: index)
	}
	
	open override func removeAllItems() {
		itemMenu.removeAllItems()
		NotificationCenter.default.post(name: NSMenu.didRemoveItemNotification, object: itemMenu)
	}
	
	// Accessing the items
	open override var itemArray: [NSMenuItem] {
		return itemMenu.items
	}
	
	open override var numberOfItems: Int {
		return itemMenu.items.count
	}
	
	open override func index(of item: NSMenuItem) -> Int {
		return itemMenu.index(of: item)
	}
	
	open override func indexOfItem(withTitle title: String) -> Int {
		return itemMenu.indexOfItem(withTitle: title)
	}
	
	open override func indexOfItem(withTag tag: Int) -> Int {
		return itemMenu.indexOfItem(withTag: tag)
	}
	
	open override func indexOfItem(withRepresentedObject obj: Any?) -> Int {
		return itemMenu.indexOfItem(withRepresentedObject: obj)
	}
	
	open override func indexOfItem(withTarget target: Any?, andAction actionSelector: Selector?) -> Int {
		return itemMenu.indexOfItem(withTarget: target, andAction: actionSelector)
	}
	
	open override func item(at index: Int) -> NSMenuItem? {
		return itemMenu.item(at: index)
	}
	
	open override func item(withTitle title: String) -> NSMenuItem? {
		return itemMenu.item(withTitle: title)
	}
	
	open override var lastItem: NSMenuItem? {
		return itemMenu.items.last
	}
	
	// Dealing with selection
//	open override func select(_ item: NSMenuItem?) {
//
//	}
//
//	open override func selectItem(at index: Int)
//
//	open override func selectItem(withTitle title: String)
//
//	open override func selectItem(withTag tag: Int) -> Bool
//
//	open override func setTitle(_ string: String)
//
//
//	open override var selectedItem: NSMenuItem? { get }
//
//	open override var indexOfSelectedItem: Int { get }
}

//MARK: Search item management

extension LNSearchablePopUpButton {
	// Adding and removing items
	open func addSearchItem(withTitle title: String, for searchQuery: String) {
		guard searchField.stringValue == searchQuery else { return }
		
		searchMenu.addItem(withTitle: title, action: nil, keyEquivalent: "")
	}
	
	open func addSearchItems(withTitles itemTitles: [String], for searchQuery: String) {
		guard searchField.stringValue == searchQuery else { return }
		
		itemTitles.forEach {
			addSearchItem(withTitle: $0, for: searchQuery)
		}
	}
	
	open func insertSearchItem(withTitle title: String, at index: Int, for searchQuery: String) {
		guard searchField.stringValue == searchQuery else { return }
		
		searchMenu.insertItem(withTitle: title, action: nil, keyEquivalent: "", at: index)
	}
	
	open func removeSearchItem(withTitle title: String) {
		let idx = searchMenu.indexOfItem(withTitle: title)
		guard idx != -1 else { return }
		searchMenu.removeItem(at: idx)
	}
	
	open func removeSearchItem(at index: Int) {
		searchMenu.removeItem(at: index)
	}
	
	open func removeAllSearchItems() {
		searchMenu.removeAllItems()
		NotificationCenter.default.post(name: NSMenu.didRemoveItemNotification, object: searchMenu)
	}
	
	// Accessing the items
	open var searcgItemArray: [NSMenuItem] {
		return searchMenu.items
	}
	
	open var numberOfSearchItems: Int {
		return searchMenu.items.count
	}
	
	open func index(ofSearchItem item: NSMenuItem) -> Int {
		return searchMenu.index(of: item)
	}
	
	open func indexOfSearchItem(withTitle title: String) -> Int {
		return searchMenu.indexOfItem(withTitle: title)
	}
	
	open func indexOfSearchItem(withTag tag: Int) -> Int {
		return searchMenu.indexOfItem(withTag: tag)
	}
	
	open func indexOfSearchItem(withRepresentedObject obj: Any?) -> Int {
		return searchMenu.indexOfItem(withRepresentedObject: obj)
	}
	
	open func indexOfSearchItem(withTarget target: Any?, andAction actionSelector: Selector?) -> Int {
		return searchMenu.indexOfItem(withTarget: target, andAction: actionSelector)
	}
	
	open func searchItem(at index: Int) -> NSMenuItem? {
		return searchMenu.item(at: index)
	}
	
	open func searchItem(withTitle title: String) -> NSMenuItem? {
		return searchMenu.item(withTitle: title)
	}
	
	open var lastSearchItem: NSMenuItem? {
		return searchMenu.items.last
	}
}
