//
//  AddRedditFeedWindowController.swift
//  NetNewsWire
//
//  Created by Maurice Parker on 5/10/20.
//  Copyright © 2020 Ranchero Software. All rights reserved.
//

import AppKit
import RSCore
import RSTree
import Articles
import Account

class AddRedditFeedWindowController : NSWindowController, AddFeedWindowController {

	@IBOutlet weak var typePopupButton: NSPopUpButton!
	@IBOutlet weak var typeDescriptionLabel: NSTextField!

	@IBOutlet weak var accountLabel: NSTextField!
	@IBOutlet weak var accountPopupButton: NSPopUpButton!
	@IBOutlet weak var subredditTextField: NSTextField!

	@IBOutlet weak var sortPopupButton: NSPopUpButton!
	
	@IBOutlet var nameTextField: NSTextField!
	@IBOutlet var addButton: NSButton!
	@IBOutlet var folderPopupButton: NSPopUpButton!

	private weak var delegate: AddFeedWindowControllerDelegate?
	private var folderTreeController: TreeController!

	private var userSelectedSort: RedditSort {
		switch sortPopupButton.selectedItem?.tag ?? 0 {
		case 0:
			return .best
		case 1:
			return .hot
		case 2:
			return .new
		case 3:
			return .top
		default:
			return .rising
		}
	}
	
	private var userEnteredSubreddit: String? {
		var s = subredditTextField.stringValue
		s = s.collapsingWhitespace
		if s.isEmpty {
			return nil
		}
		return s
	}
	
	private var userEnteredTitle: String? {
		var s = nameTextField.stringValue
		s = s.collapsingWhitespace
		if s.isEmpty {
			return nil
		}
		return s
	}
	
    var hostWindow: NSWindow!

	convenience init(folderTreeController: TreeController, delegate: AddFeedWindowControllerDelegate?) {
		self.init(windowNibName: NSNib.Name("AddRedditFeedSheet"))
		self.folderTreeController = folderTreeController
		self.delegate = delegate
	}
	
    func runSheetOnWindow(_ hostWindow: NSWindow) {
		hostWindow.beginSheet(window!) { (returnCode: NSApplication.ModalResponse) -> Void in
		}
    }

	override func windowDidLoad() {

		let accountMenu = NSMenu()
		for feedProvider in ExtensionPointManager.shared.activeFeedProviders {
			if let redditFeedProvider = feedProvider as? RedditFeedProvider {
				let accountMenuItem = NSMenuItem()
				accountMenuItem.title = redditFeedProvider.title
				accountMenu.addItem(accountMenuItem)
			}
		}
		accountPopupButton.menu = accountMenu
		
		folderPopupButton.menu = FolderTreeMenu.createFolderPopupMenu(with: folderTreeController.rootNode)
		
		if let container = AddWebFeedDefaultContainer.defaultContainer {
			if let folder = container as? Folder, let account = folder.account {
				FolderTreeMenu.select(account: account, folder: folder, in: folderPopupButton)
			} else {
				if let account = container as? Account {
					FolderTreeMenu.select(account: account, folder: nil, in: folderPopupButton)
				}
			}
		}
		
		updateUI()
	}

    // MARK: Actions
    
	@IBAction func selectedType(_ sender: Any) {
		subredditTextField.stringValue = ""
		updateUI()
	}

	@IBAction func cancel(_ sender: Any?) {
		cancelSheet()
    }
    
    @IBAction func addFeed(_ sender: Any?) {
		guard let type = RedditFeedType(rawValue: typePopupButton.selectedItem?.tag ?? 0),
			let atUsername = accountPopupButton.selectedItem?.title else { return }
		
		let username = String(atUsername[atUsername.index(atUsername.startIndex, offsetBy: 2)..<atUsername.endIndex])
		guard let url = RedditFeedProvider.buildURL(type, username: username, subreddit: userEnteredSubreddit, sort: userSelectedSort) else { return }
		
		let container = selectedContainer()!
		AddWebFeedDefaultContainer.saveDefaultContainer(container)
		delegate?.addFeedWindowController(self, userEnteredURL: url, userEnteredTitle: userEnteredTitle, container: container)
    }
	
}

extension AddRedditFeedWindowController: NSTextFieldDelegate {

	func controlTextDidChange(_ obj: Notification) {
		updateUI()
	}
	
}

private extension AddRedditFeedWindowController {
	
	private func updateUI() {
		
		switch typePopupButton.selectedItem?.tag ?? 0 {
		case 0:
			
			accountLabel.isHidden = false
			accountPopupButton.isHidden = false
			typeDescriptionLabel.stringValue = NSLocalizedString("Your personal Reddit frontpage", comment: "Home")
			subredditTextField.isHidden = true
			addButton.isEnabled = true
			
		case 1:
			
			accountLabel.isHidden = false
			accountPopupButton.isHidden = false
			typeDescriptionLabel.stringValue = NSLocalizedString("Best posts on Reddit for you", comment: "Popular")
			subredditTextField.isHidden = true
			addButton.isEnabled = true
			
		case 2:
			
			accountLabel.isHidden = false
			accountPopupButton.isHidden = false
			typeDescriptionLabel.stringValue = NSLocalizedString("The most active posts", comment: "All")
			subredditTextField.isHidden = true
			addButton.isEnabled = true
			
		default:
			
			accountLabel.isHidden = true
			accountPopupButton.isHidden = true
			
			if !subredditTextField.stringValue.isEmpty {
				typeDescriptionLabel.stringValue = NSLocalizedString("Posts from r/\(subredditTextField.stringValue)", comment: "Subreddit")
			} else {
				typeDescriptionLabel.stringValue = ""
			}
			
			subredditTextField.placeholderString = NSLocalizedString("Subreddit", comment: "Search Term")
			subredditTextField.isHidden = false
			addButton.isEnabled = !subredditTextField.stringValue.isEmpty
			
		}
		
	}

	func cancelSheet() {
		delegate?.addFeedWindowControllerUserDidCancel(self)
	}

	func selectedContainer() -> Container? {
		return folderPopupButton.selectedItem?.representedObject as? Container
	}
}
