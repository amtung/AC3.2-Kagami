//
//  WeatherView.swift
//  Kagami
//
//  Created by Eric Chang on 3/6/17.
//  Copyright © 2017 Eric Chang. All rights reserved.
//

import UIKit
import SnapKit
import TwicketSegmentedControl
import FirebaseDatabase

class WeatherView: UIView, UISearchBarDelegate {
    
    // MARK: - Properties
    var isSearchActive: Bool = false
    var database: FIRDatabaseReference!
    var weather: DailyWeather?
    var gradientLayer: CAGradientLayer!
    // default properties
    let userDefault = UserDefaults.standard
    var defaultZipcode: String?
    var isFahrenheit: Bool?
    var unit = "imperial"
    
    // MARK: - View Lifecycle
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.database = FIRDatabase.database().reference().child("weather")
        createGradientLayer()
        self.layer.cornerRadius = 9
        searchBar.delegate = self
        setupViewHierarchy()
        configureConstraints()
        loadUserDefaults()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    // MARK: - Setup View Hierarchy & Constraints
    func setupViewHierarchy() {
        self.addSubview(searchBar)
        self.addSubview(degreeLabel)
        self.addSubview(locationLabel)
        self.addSubview(weatherIcon)
        self.addSubview(descriptionLabel)
        self.addSubview(lowestTempLabel)
        self.addSubview(minMaxDegreeLabel)
        self.addSubview(highestTempLabel)
        self.addSubview(headerImage)
        self.addSubview(segmentView)
        self.addSubview(doneButton)
        self.addSubview(cancelButton)
        segmentView.addSubview(customSegmentControl)
        
        doneButton.addTarget(self, action: #selector(addToMirror), for: .touchUpInside)
    }
    
    func configureConstraints() {
        searchBar.snp.makeConstraints { (view) in
            view.top.left.right.equalToSuperview()
            view.height.equalTo(50)
        }
        
        headerImage.snp.makeConstraints { (view) in
            view.centerX.equalToSuperview()
            view.top.equalTo(searchBar.snp.bottom).offset(10)
        }
        
        degreeLabel.snp.makeConstraints { (label) in
            label.centerX.equalToSuperview()
            label.top.equalTo(headerImage.snp.bottom).offset(20)
        }
        
        locationLabel.snp.makeConstraints { (label) in
            label.centerX.equalToSuperview()
            label.top.equalTo(degreeLabel.snp.bottom).offset(10)
        }
        
        descriptionLabel.snp.makeConstraints { (label) in
            label.centerX.equalToSuperview()
            label.top.equalTo(locationLabel.snp.bottom).offset(10)
        }
        
        weatherIcon.snp.makeConstraints { (view) in
            view.top.equalTo(descriptionLabel.snp.bottom).offset(10)
            view.centerX.equalToSuperview()
        }
        
        minMaxDegreeLabel.snp.makeConstraints { (label) in
            label.centerX.equalToSuperview()
            label.top.equalTo(weatherIcon.snp.bottom).offset(10)
        }
        
        lowestTempLabel.snp.makeConstraints { (label) in
            label.right.equalTo(minMaxDegreeLabel.snp.left)
            label.centerY.equalTo(minMaxDegreeLabel)
        }
        
        highestTempLabel.snp.makeConstraints { (label) in
            label.left.equalTo(minMaxDegreeLabel.snp.right)
            label.centerY.equalTo(minMaxDegreeLabel)
        }
        
        segmentView.snp.makeConstraints { (view) in
            view.left.right.equalToSuperview()
            view.top.equalTo(minMaxDegreeLabel.snp.bottom).offset(10)
            view.height.equalTo(40)
        }
        
        customSegmentControl.snp.makeConstraints { (control) in
            control.top.bottom.equalTo(segmentView)
            control.left.equalToSuperview().offset(125.0)
            control.right.equalToSuperview().inset(125.0)
        }
        
        doneButton.snp.makeConstraints { (view) in
            view.right.equalTo(self.snp.right).inset(8)
            view.bottom.equalTo(self.snp.bottom).inset(8)
        }
        
        cancelButton.snp.makeConstraints { (view) in
            view.left.equalTo(self.snp.left).inset(8)
            view.bottom.equalTo(self.snp.bottom).inset(8)
        }
    }
    
    func createGradientLayer() {
        gradientLayer = CAGradientLayer()
        let view: UIView = UIView(frame: CGRect(x: 0, y: 0, width: 400, height: 650))
        gradientLayer.frame = view.bounds
        gradientLayer.colors = [UIColor(red:0.56, green:0.62, blue:0.67, alpha:1.0).cgColor, UIColor(red:0.93, green:0.95, blue:0.95, alpha:1.0).cgColor]
        gradientLayer.locations = [0.0 , 1.0]
        self.layer.addSublayer(gradientLayer)
    }
    
    // MARK: - Settings Methods
    func addToMirror() {
        self.userDefault.setValue(self.defaultZipcode, forKey: "weatherZip")
        
        if customSegmentControl.selectedSegmentIndex == 0 {
            self.userDefault.setValue(true, forKey: "weatherFahrenheit")
        }
        else {
            self.userDefault.setValue(false, forKey: "weatherFahrenheit")
        }
    }
    
    func loadUserDefaults() {
        if userDefault.object(forKey: "weatherFahrenheit") == nil {
            self.userDefault.setValue(true, forKey: "weatherFahrenheit")
        }
        
        if userDefault.object(forKey: "weatherZip") == nil {
            self.userDefault.setValue("10014", forKey: "weatherZip")
        }
        
        defaultZipcode = userDefault.object(forKey: "weatherZip") as? String
        isFahrenheit = userDefault.object(forKey: "weatherFahrenheit") as? Bool
        
        if isFahrenheit! {
            customSegmentControl.move(to: 0)
        }
        else {
            customSegmentControl.move(to: 1)
            self.unit = "metric"
        }
        
        APIRequestManager.manager.getData(endPoint: "http://api.openweathermap.org/data/2.5/weather?appid=93163a043d0bde0df1a79f0fdebc744f&zip=\(defaultZipcode!),us&units=\(self.unit)") { (data: Data?) in
            guard let validData = data else { return }
            if let weatherObject = DailyWeather.parseWeather(from: validData) {
                self.weather = weatherObject
                DispatchQueue.main.async {
                    self.locationLabel.text = self.weather!.name
                    self.degreeLabel.text = String(describing: self.weather!.temperature)
                    self.descriptionLabel.text = self.weather!.weatherDescription
                    self.lowestTempLabel.text = String(describing: self.weather!.minTemp)
                    self.highestTempLabel.text = String(describing: self.weather!.maxTemp)
                    self.layoutIfNeeded()
                }
            }
        }
    }
    
    func getAPIResultsForFahrenheit() {
        APIRequestManager.manager.getData(endPoint: "http://api.openweathermap.org/data/2.5/weather?appid=93163a043d0bde0df1a79f0fdebc744f&zip=\(defaultZipcode!),us&units=imperial") { (data: Data?) in
            guard let validData = data else { return }
            
            if let weatherObject = DailyWeather.parseWeather(from: validData) {
                self.weather = weatherObject
                DispatchQueue.main.async {
                    self.locationLabel.text = self.weather!.name
                    self.degreeLabel.text = String(describing: self.weather!.temperature)
                    self.descriptionLabel.text = self.weather!.weatherDescription
                    self.lowestTempLabel.text = String(describing: self.weather!.minTemp)
                    self.highestTempLabel.text = String(describing: self.weather!.maxTemp)
                    self.layoutIfNeeded()
                }
            }
        }
    }
    
    func getAPIResultsForCelsius() {
        APIRequestManager.manager.getData(endPoint: "http://api.openweathermap.org/data/2.5/weather?appid=93163a043d0bde0df1a79f0fdebc744f&zip=\(defaultZipcode!),us&units=metric") { (data: Data?) in
            guard let validData = data else { return }
            
            if let weatherObject = DailyWeather.parseWeather(from: validData) {
                self.weather = weatherObject
                DispatchQueue.main.async {
                    self.locationLabel.text = self.weather!.name
                    self.degreeLabel.text = String(describing: self.weather!.temperature)
                    self.descriptionLabel.text = self.weather!.weatherDescription
                    self.lowestTempLabel.text = String(describing: self.weather!.minTemp)
                    self.highestTempLabel.text = String(describing: self.weather!.maxTemp)
                    self.layoutIfNeeded()
                }
            }
        }
    }
    
    // MARK: - Search Bar Delegate
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        isSearchActive = true
        searchBar.showsCancelButton = true
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        isSearchActive = false
        self.searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard searchBar.text != nil else { return }
        
        defaultZipcode = searchBar.text!
        self.database.child("zipcode").setValue(defaultZipcode!)
        
        if customSegmentControl.selectedSegmentIndex == 0 {
            getAPIResultsForFahrenheit()
        }
        else {
            getAPIResultsForCelsius()
        }
        
        self.endEditing(true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        isSearchActive = false
        self.endEditing(true)
    }
    
    // MARK: - Lazy Instantiates
    lazy var weatherIcon: UIImageView = {
        let image = UIImage(named: "Partly-Cloudy-Day-white")
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleToFill
        return imageView
    }()
    
    lazy var locationLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont(name: "Code-Pro-Demo", size: 20)
        label.textColor = ColorPalette.whiteColor
        return label
    }()
    
    lazy var degreeLabel: UILabel = {
        let label = UILabel()
        label.text = "0"
        label.font = UIFont(name: "Code-Pro-Demo", size: 70)
        label.textColor = ColorPalette.whiteColor
        return label
    }()
    
    lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont(name: "Code-Pro-Demo", size: 18)
        label.textColor = ColorPalette.whiteColor
        return label
    }()
    
    lazy var lowestTempLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont(name: "Code-Pro-Demo", size: 18)
        label.textColor = ColorPalette.whiteColor
        return label
    }()
    
    lazy var minMaxDegreeLabel: UILabel = {
        let label = UILabel()
        label.text = "/"
        label.font = UIFont(name: "Code-Pro-Demo", size: 18)
        label.textColor = ColorPalette.whiteColor
        return label
    }()
    
    lazy var highestTempLabel: UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont(name: "Code-Pro-Demo", size: 18)
        label.textColor = ColorPalette.whiteColor
        return label
    }()
    
    lazy var searchBar: UISearchBar = {
        let bar = UISearchBar()
        bar.placeholder = "SEARCH BY ZIPCODE"
        bar.tintColor = ColorPalette.whiteColor
        bar.barTintColor = UIColor(red:0.56, green:0.62, blue:0.67, alpha:1.0)
        bar.layer.borderWidth = 1
        bar.layer.borderColor = UIColor(red:0.56, green:0.62, blue:0.67, alpha:1.0).cgColor
        bar.searchBarStyle = UISearchBarStyle.default
        bar.isUserInteractionEnabled = true
        bar.clipsToBounds = true
        return bar
    }()
    
    lazy var customSegmentControl: TwicketSegmentedControl = {
        let segmentedControl = TwicketSegmentedControl()
        let titles = ["℉", "℃"]
        segmentedControl.setSegmentItems(titles)
        segmentedControl.delegate = self
        segmentedControl.highlightTextColor = ColorPalette.accentColor
        segmentedControl.sliderBackgroundColor = ColorPalette.whiteColor
        segmentedControl.segmentsBackgroundColor = ColorPalette.grayColor
        segmentedControl.isSliderShadowHidden = false
        segmentedControl.backgroundColor = .clear
        return segmentedControl
    }()
    
    lazy var segmentView: UIView = {
        let view = UIView()
        return view
    }()
    
    lazy var doneButton: UIButton = {
        let button = UIButton()
        let image = UIImage(named: "Ok-50")
        button.setImage(image, for: .normal)
        return button
    }()
    
    lazy var cancelButton: UIButton = {
        let button = UIButton()
        let image = UIImage(named: "Cancel-50")
        button.setImage(image, for: .normal)
        return button
    }()
    
    lazy var headerImage: UIImageView = {
        let imageView = UIImageView()
        let image = UIImage(named: "weatherheader")
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
}

extension WeatherView: TwicketSegmentedControlDelegate {
    func didSelect(_ segmentIndex: Int) {
        print("Selected index at: \(segmentIndex)!")
        if segmentIndex == 0 {
            database.child("fahrenheit").setValue(true)
            getAPIResultsForFahrenheit()
        } else {
            database.child("fahrenheit").setValue(false)
            getAPIResultsForCelsius()
        }
    }
}
