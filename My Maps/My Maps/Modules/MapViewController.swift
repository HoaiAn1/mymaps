//
//  MainMapsViewController.swift
//  My Maps
//
//  Created by Le Vu Hoai An on 4/27/18.
//  Copyright © 2018 Le Vu Hoai An. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import GooglePlacePicker

class MapViewController: BaseMapViewController {
    
    // MARK: Properties
    fileprivate var _locationManager = CLLocationManager()
    fileprivate var _currentLocation: CLLocation?
    
    fileprivate var _mapView: GMSMapView!
    fileprivate var _placeDetailView: PlaceDetailView!
    fileprivate var _twoPlacesPickerView: TwoPlacesPickerView!
    fileprivate var _onePlacePickerView: OnePlacePickerView!
    fileprivate var _pickerViewType: PickerViewType = .onePlace
    
    fileprivate var _firstLocation: CLLocationCoordinate2D?
    fileprivate var _secondLocation: CLLocationCoordinate2D?
    fileprivate var _isSearching: Bool = false
    fileprivate var _pickingSecondPlace = false
    
    // MARK: Implementation
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func setupViews() {
        super.setupViews()
        
        // Setup main view
        let placeDetailYPosition = self.view.bounds.height - DEFAULT_PLACE_DETAIL_VIEW_HEIGHT
        let placeDetailViewRect = CGRect(
            x: 0,
            y: placeDetailYPosition,
            width: self.view.bounds.width,
            height: DEFAULT_PLACE_DETAIL_VIEW_HEIGHT
        )
        self._placeDetailView = PlaceDetailView(frame: placeDetailViewRect)
        self._placeDetailView.backgroundColor = UIColor.white
        self._placeDetailView.isHidden = true
        
        self._mapView = GMSMapView(frame: self.view.bounds)
        self._mapView.settings.myLocationButton = true
        self._mapView.isMyLocationEnabled = true
        self._mapView.isHidden = true
        self._mapView.delegate = self
        self._mapView.padding.top = self.headerDirectionView.bounds.height
        
        self.contentMainView.addSubview(self._mapView)
        self.contentMainView.addSubview(self._placeDetailView)
        
        // Setup header view
        self._twoPlacesPickerView = TwoPlacesPickerView(frame: self.headerDirectionView.bounds)
        self._twoPlacesPickerView.delegate = self
        
        let onePlacePickerViewRect = CGRect(
            x: 0,
            y: 0,
            width: self.headerDirectionView.bounds.width,
            height: self.headerDirectionView.bounds.height/3
        )
        self._onePlacePickerView = OnePlacePickerView(frame: onePlacePickerViewRect)
        self._onePlacePickerView.delegate = self
        
        self.headerDirectionView.addSubview(self._twoPlacesPickerView)
        self.headerDirectionView.addSubview(self._onePlacePickerView)

        if self._pickerViewType == .onePlace {
            self._twoPlacesPickerView.isHidden = true
        }
        else {
            self._onePlacePickerView.isHidden = true
        }

        self.headerDirectionView.backgroundColor = UIColor.clear
    }
    
    override func setupComponents() {
        super.setupComponents()
        
        self._locationManager = CLLocationManager()
        self._locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self._locationManager.requestAlwaysAuthorization()
        self._locationManager.distanceFilter = 50
        self._locationManager.startUpdatingLocation()
        self._locationManager.delegate = self
    }
    
    // MARK: Animate show/hide UI elements
    func hideTwoPlacesPickerView(_ hide: Bool, animated: Bool) {
        self._twoPlacesPickerView.isHidden = !self._twoPlacesPickerView.isHidden
        self._onePlacePickerView.isHidden = !self._onePlacePickerView.isHidden
        
        var originX: CGFloat = 0
        let moveDistance = self.headerDirectionView.bounds.width
        
        if hide {
            self._pickerViewType = .onePlace
            originX = self._twoPlacesPickerView.frame.origin.x
            
            if animated {
                self._onePlacePickerView.frame.origin.x -= moveDistance
                UIView.animate(withDuration: 0.3) { [weak self] in
                    self?._onePlacePickerView.frame.origin.x = originX
                    self?._twoPlacesPickerView.frame.origin.x += moveDistance
                }
            }
            else {
                self._onePlacePickerView.frame.origin.x -= originX
                self._twoPlacesPickerView.frame.origin.x += moveDistance
            }
            
            if self._isSearching {
                hidePlaceDetail(false, animated: true)
            }
        }
        else {
            self._pickerViewType = .twoPlace
            originX = self._onePlacePickerView.frame.origin.x
            
            if animated {
                self._twoPlacesPickerView.frame.origin.x += moveDistance
                UIView.animate(withDuration: 0.3) { [weak self] in
                    self?._onePlacePickerView.frame.origin.x -= moveDistance
                    self?._twoPlacesPickerView.frame.origin.x = originX
                }
            }
            else {
                self._onePlacePickerView.frame.origin.x -= moveDistance
                self._twoPlacesPickerView.frame.origin.x = originX
            }
            
            hidePlaceDetail(true, animated: true)
        }
    }
    
    func hidePlaceDetail(_ hide: Bool, animated: Bool) {
        var newMapRect = self._mapView.frame
        let moveDistance = DEFAULT_PLACE_DETAIL_VIEW_HEIGHT
        
        if hide {
            newMapRect.size = CGSize(width: newMapRect.size.width, height: self.view.bounds.height)
            self._mapView.frame = newMapRect
            if animated {
                UIView.animate(withDuration: 0.5, animations: { [weak self] in
                    self?._placeDetailView.frame.origin.y += moveDistance
                }) { [weak self] (completion) in
                    self?._placeDetailView.isHidden = hide
                }
            }
            else {
                self._placeDetailView.frame.origin.y += moveDistance
            }
        }
        else {
            newMapRect.size = CGSize(width: newMapRect.size.width, height: self.view.bounds.height - DEFAULT_PLACE_DETAIL_VIEW_HEIGHT)
            if animated {
                self._placeDetailView.isHidden = hide
                UIView.animate(withDuration: 0.5, animations: { [weak self] in
                    guard let `self` = self else { return }
                    self._placeDetailView.frame.origin.y = self.view.bounds.height - DEFAULT_PLACE_DETAIL_VIEW_HEIGHT
                }) { [weak self] (completion) in
                    self?._mapView.frame = newMapRect
                }
            }
            else {
                self._mapView.frame = newMapRect
                self._placeDetailView.frame.origin.y = self.view.bounds.height - DEFAULT_PLACE_DETAIL_VIEW_HEIGHT
            }
        }
    }

    fileprivate func presentAutoCompleteController() {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.view.backgroundColor = .red
        autocompleteController.tableCellBackgroundColor = .clear
        autocompleteController.delegate = self
        
        present(autocompleteController, animated: true, completion: nil)
    }
}

// MARK: CoreLocationManager Delegate
extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocation = locations.last!

        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude,
                                              longitude: location.coordinate.longitude,
                                              zoom: DEFAULT_MAP_ZOOM_LEVEL)

        self._mapView.isHidden = false
        self._mapView.animate(to: camera)
        self._currentLocation = location
    }
    
    // Handle location manager errors.
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self._locationManager.stopUpdatingLocation()
    }
    
    // Handle authorization for the location manager.
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .restricted: fallthrough
        case .denied:
            print("[Location Authorization] Location access was restricted | User denied.")
            UtilityHelper.presentOpenSettingsAlert(self)
        case .notDetermined:
            print("[Location Authorization] Location status not determined.")
            self._locationManager.requestAlwaysAuthorization()
        case .authorizedAlways: fallthrough
        case .authorizedWhenInUse:
            print("[Location Authorization] Location status is authorized.")
            self._locationManager.startUpdatingLocation()
        }
    }
    
}

// MARK: GoogleMapView Delegate
extension MapViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, didTapPOIWithPlaceID placeID: String, name: String, location: CLLocationCoordinate2D) {
        let infoMarker = GMSMarker()
        infoMarker.snippet = "(\(location.latitude), \(location.longitude))"
        infoMarker.position = location
        infoMarker.title = name
        infoMarker.opacity = 0;
        infoMarker.infoWindowAnchor.y = 1
        infoMarker.map = mapView
        mapView.selectedMarker = infoMarker
    }
}


// MARK: GoogleMap AutoCompleteView Delegate
extension MapViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        // One place picker handle
        if self._pickerViewType == .onePlace {
            let marker = GMSMarker()
            marker.position = place.coordinate
            marker.title = place.name
            marker.map = self._mapView
            
            let camera = GMSCameraPosition.camera(
                withLatitude: place.coordinate.latitude,
                longitude: place.coordinate.longitude,
                zoom: DEFAULT_MAP_ZOOM_LEVEL
            )
            self._mapView.animate(to: camera)
            
            self.hidePlaceDetail(false, animated: true)
        
            if let address = place.formattedAddress {
                self._placeDetailView.setDetailDescription(address)
            }
            else {
                self._placeDetailView.setDetailDescription(place.name)
            }
            
            self._onePlacePickerView.setPlacePicker(place.name)
            
            self._secondLocation = place.coordinate
            
            self._isSearching = true
        }
        else { // Two places picker handle
            if !self._pickingSecondPlace {
                self._firstLocation = place.coordinate
                self._twoPlacesPickerView.setFirstPlacePicker(place.name)
            }
            else {
                self._secondLocation = place.coordinate
                self._twoPlacesPickerView.setSecondPlacePicker(place.name)
            }
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        UtilityHelper.presentAlert("Error", message: error.localizedDescription, vc: self)
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
}

extension MapViewController: OnePlacePickerViewDelegate {
    func didTapPlacePicker() {
        presentAutoCompleteController()
    }
    
    func didTapChangePickerView() {
        hideTwoPlacesPickerView(false, animated: true)
    }
    
}

// MARK: TwoPlacesPickerView Delegate
extension MapViewController: TwoPlacesPickerViewDelegate {
    
    func didTapFirstPlacePicker() {
        presentAutoCompleteController()
        self._pickingSecondPlace = false
    }
    
    func didTapSecondPlacePicker() {
        presentAutoCompleteController()
        self._pickingSecondPlace = true
    }
    
    func didTapBackButton() {
        hideTwoPlacesPickerView(true, animated: true)
        self._twoPlacesPickerView.resetTwoPlacesPickerView()
    }
    
    func didPickPlaces() {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) {
            guard let firstLocation = self._firstLocation, let secondLocation = self._secondLocation else { return }
            
            var bounds = GMSCoordinateBounds()
            let firstMarker = GMSMarker()
            firstMarker.icon = GMSMarker.markerImage(with: UIColor.lightGray)
            firstMarker.position = CLLocationCoordinate2D(latitude: firstLocation.latitude, longitude: firstLocation.longitude)
            firstMarker.map = self._mapView
            bounds = bounds.includingCoordinate(firstLocation)
            
            let secondMaker = GMSMarker()
            secondMaker.position = CLLocationCoordinate2D(latitude: secondLocation.latitude, longitude: secondLocation.longitude)
            secondMaker.map = self._mapView
            bounds = bounds.includingCoordinate(secondLocation)
            
            CATransaction.begin()
            CATransaction.setValue(1, forKey: kCATransactionAnimationDuration)
            self._mapView.animate(with: GMSCameraUpdate.fit(bounds, withPadding: 100))
            CATransaction.commit()
        }
    }
    
    func didResetPickerView() {
        self._mapView.clear()
    }
}


