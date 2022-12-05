//
//  ViewController.swift
//  LNSearchablePopUpButtonExample
//
//  Created by Leo Natan on 04/12/2022.
//

import Cocoa
import LNSearchablePopUpButton

class ViewController: NSViewController, NSSearchFieldDelegate {
	private lazy var searchablePopUpButton = {
		let searchablePopUpButton = LNSearchablePopUpButton()
		searchablePopUpButton.translatesAutoresizingMaskIntoConstraints = false
		view.addSubview(searchablePopUpButton)
		
		NSLayoutConstraint.activate([
			view.centerXAnchor.constraint(equalTo: searchablePopUpButton.centerXAnchor),
			view.centerYAnchor.constraint(equalTo: searchablePopUpButton.centerYAnchor),
			searchablePopUpButton.widthAnchor.constraint(equalToConstant: 300)
		])
		
		return searchablePopUpButton
	}()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		searchablePopUpButton.target = self
		searchablePopUpButton.action = #selector(ViewController.didSelectItem)
		
		searchablePopUpButton.addItem(withTitle: "1")
		searchablePopUpButton.addItem(withTitle: "2")
		searchablePopUpButton.addItem(withTitle: "3")
		
		searchablePopUpButton.searchField.delegate = self
	}
	
	fileprivate var searchTimer: Timer? = nil
	func controlTextDidChange(_ obj: Notification) {
//		searchTimer?.invalidate()
//		searchTimer = nil
//		
//		searchablePopUpButton.removeAllSearchItems()
//		
//		let searchQuery = searchablePopUpButton.searchField.stringValue
//		
//		guard searchQuery.count > 0 else {
//			return
//		}
//		
//		let timer = Timer(timeInterval: 1.0, repeats: false, block: { [weak self] _ in
//			var demoSearchItems = [String]()
//			for idx in 0..<Int.random(in: 0..<4) {
//				demoSearchItems.append("“\(searchQuery)” demo result \(idx)")
//			}
//			
//			self?.searchablePopUpButton.addSearchItems(withTitles: demoSearchItems, for: searchQuery)
//			
//			self?.searchablePopUpButton.finishSearch()
//			self?.searchTimer?.invalidate()
//			self?.searchTimer = nil
//		})
//		RunLoop.current.add(timer, forMode: .common)
//		searchTimer = timer
	}
	
	@objc func didSelectItem() {
		print("Selected: \(searchablePopUpButton.selectedItem?.description ?? "none")")
	}
}

