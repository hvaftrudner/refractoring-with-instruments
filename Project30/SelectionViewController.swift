//
//  SelectionViewController.swift
//  Project30
//
//  Created by TwoStraws on 20/08/2016.
//  Copyright (c) 2016 TwoStraws. All rights reserved.
//

import UIKit

class SelectionViewController: UITableViewController {
	var items = [String]() // this is the array that will store the filenames to load
	 // create a cache of the detail view controllers for faster loading
	var dirty = false
    
    var images: [UIImage?] = [UIImage]() // array of optional UIImages
    var loadedImages = false

    override func viewDidLoad() {
        super.viewDidLoad()

		title = "Reactionist"

		tableView.rowHeight = 90
		tableView.separatorStyle = .none
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

        DispatchQueue.global().async {
            [weak self] in
            self?.loadImages()
        }
    }
    
    func loadImages(){
        // load all the JPEGs into our array
        let fm = FileManager.default
        
        if let resourcePath = Bundle.main.resourcePath {
            if let tempItems = try? fm.contentsOfDirectory(atPath: resourcePath) {
                for item in tempItems {
                    if item.range(of: "Large") != nil {
                        items.append(item)
                        
                        if let savedImage = save(imageName: item){
                            images.append(savedImage)
                        } else {
                            images.append(loadThumb(image: item))
                        }
                    }
                }
            }
        }
        loadedImages = true
        tableView.performSelector(onMainThread: #selector(UITableView.reloadData), with: nil, waitUntilDone: false)
    }
    func loadThumb(image: String) -> UIImage?{
        
        // find the image for this cell, and load its thumbnail
        let imageRootName = image.replacingOccurrences(of: "Large", with: "Thumb")
        guard let path = Bundle.main.path(forResource: imageRootName, ofType: nil) else {return nil}
        guard let original = UIImage(contentsOfFile: path) else {return nil}

        //setting new size for image
        let renderRect = CGRect(origin: .zero, size: CGSize(width: 90, height: 90))
        let renderer = UIGraphicsImageRenderer(size: renderRect.size)

        let rounded = renderer.image { ctx in
            //better rendering of shadow
//            ctx.cgContext.setShadow(offset: .zero, blur: 200, color: UIColor.black.cgColor)
//            ctx.cgContext.fillEllipse(in: CGRect(origin: .zero, size: original.size))
//            ctx.cgContext.setShadow(offset: .zero, blur: 0, color: nil)
            
            ctx.cgContext.addEllipse(in: renderRect)
            ctx.cgContext.clip()

            original.draw(in: renderRect)
        }
        saveCached(name: image, image: rounded)
        return rounded
    }
    
    func save(imageName: String) -> UIImage?{
        let path = getDocumentsDirectory().appendingPathComponent(imageName)
        return UIImage(contentsOfFile: path.path)
    }
    func saveCached(name: String, image: UIImage){
        let path = getDocumentsDirectory().appendingPathComponent(name)
        if let saveImage = image.pngData() {
            try? saveImage.write(to: path)
        }
    }
    
    func getDocumentsDirectory() -> URL {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return paths[0]
    }

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		if dirty {
			// we've been marked as needing a counter reload, so reload the whole table
			tableView.reloadData()
		}
	}

    // MARK: - Table view data source

	override func numberOfSections(in tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        
        if !loadedImages {
            return 0
        }
        
        return items.count * 10
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		//let cell = UITableViewCell(style: .default, reuseIdentifier: "Cell")
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

		// find the image for this cell, and load its thumbnail
		//let currentImage = items[indexPath.row % items.count]
        let index = indexPath.row % items.count
        let renderRect = CGRect(origin: .zero, size: CGSize(width: 90, height: 90))
        
        
        
        cell.imageView?.image = images[indexPath.row % items.count]
        
		// give the images a nice shadow to make them look a bit more dramatic
		cell.imageView?.layer.shadowColor = UIColor.black.cgColor
		cell.imageView?.layer.shadowOpacity = 1
		cell.imageView?.layer.shadowRadius = 10
		cell.imageView?.layer.shadowOffset = CGSize.zero
        //predetermens how the shadow should be drawn to minimize calc for code.
        cell.imageView?.layer.shadowPath = UIBezierPath(ovalIn: renderRect).cgPath

		// each image stores how often it's been tapped
		let defaults = UserDefaults.standard
		cell.textLabel?.text = "\(defaults.integer(forKey: items[index]))"

		return cell
    }

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let vc = ImageViewController()
		vc.image = items[indexPath.row % items.count]
		vc.owner = self

		// mark us as not needing a counter reload when we return
		dirty = false

		// add to our view controller cache and show
		
		navigationController?.pushViewController(vc, animated: true)
	}
}
