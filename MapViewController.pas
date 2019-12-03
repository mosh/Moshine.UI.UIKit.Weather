namespace Moshine.UI.UIKit.Weather;

uses
  AerisMapKit,
  CoreLocation,
  MapKit,
  UIKit;

type
  [IBObject]
  MapViewController = public class(UIViewController, IAWFWeatherMapDelegate, IAWFTimelineViewDelegate)
  private

    method setBoat(zoomLocation:CLLocationCoordinate2D;name:String);
    begin
      //N16°50.16', W57°37.7'
      var METERS_PER_MILE := 1609.344;

      // 2
      var viewRegion := MKCoordinateRegionMakeWithDistance(zoomLocation, 500*METERS_PER_MILE, 500*METERS_PER_MILE);

      // 3
      if (assigned(self.weatherMapView.mapView))then
      begin
        var view := self.weatherMapView.mapView;
        if(view is MKMapView)then
        begin
          var mapView := view as MKMapView;
          mapView.setRegion(viewRegion) animated(true);

          var boat := new MKPointAnnotation;
          boat.title := name;
          boat.coordinate := zoomLocation;
          mapView.addAnnotation(boat);
          mapView.zoomEnabled := true;
        end;
      end;

    end;

  public

    property showTimeline:Boolean := false;

    property weatherMapView:AWFWeatherMap;
    property timelineView:AWFTimelineView;
    property Location:CLLocationCoordinate2D;
    property Name:String;

    method init: InstanceType; override;
    begin
      self := inherited init;
      if assigned(self) then
      begin

        // Custom initialization

      end;
      result := self;
    end;


    method viewDidLoad; override;
    begin
      inherited viewDidLoad;

      var config := AWFWeatherMapConfig.config;
      config.shouldApplyWaterMaskToSurfaceLayers := false;

      weatherMapView := new AWFWeatherMap WithMapType(AWFWeatherMapType.Apple) config(config);
      weatherMapView.delegate := self;
      self.view.addSubview(weatherMapView.weatherMapView);

      weatherMapView.addSourceForLayerType(AWFMapLayerWindSpeeds);
      weatherMapView.addSourceForLayerType(AWFMapLayerWindDirection);
      weatherMapView.addSourceForLayerType(AWFMapLayerWindGusts);

      if(showTimeline)then
      begin

        timelineView := new AWFTimelineView WithFrame(CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 50.0));
        timelineView.delegate := self;
        timelineView.startDate := weatherMapView.timeline.fromTime;
        timelineView.endDate := weatherMapView.timeline.toTime;
        timelineView.currentTime := weatherMapView.timeline.fromTime;
        self.view.addSubview(timelineView);

        var timelineHeight: CGFloat := 50.0;
        timelineView.translatesAutoresizingMaskIntoConstraints := false;
        timelineView.preservesSuperviewLayoutMargins := true;
        NSLayoutConstraint.activateConstraints([timelineView.topAnchor.constraintEqualToAnchor(self.view.layoutMarginsGuide.bottomAnchor) constant(-timelineHeight), timelineView.leftAnchor.constraintEqualToAnchor(self.view.leftAnchor), timelineView.rightAnchor.constraintEqualToAnchor(self.view.rightAnchor), timelineView.bottomAnchor.constraintEqualToAnchor(self.view.bottomAnchor)]);
        self.timelineView.playButton.addTarget(self) action(selector(toggleAnimation:)) forControlEvents(UIControlEvents.TouchUpInside);
        self.weatherMapView.goToTime(NSDate.date());
      end;

      weatherMapView.weatherMapView.translatesAutoresizingMaskIntoConstraints := false;
      NSLayoutConstraint.activateConstraints([weatherMapView.weatherMapView.topAnchor.constraintEqualToAnchor(self.view.topAnchor),
                                              weatherMapView.weatherMapView.leftAnchor.constraintEqualToAnchor(self.view.leftAnchor),
                                              weatherMapView.weatherMapView.rightAnchor.constraintEqualToAnchor(self.view.rightAnchor),
                                              weatherMapView.weatherMapView.bottomAnchor.constraintEqualToAnchor(self.view.bottomAnchor)]);


      setBoat(self.Location, self.Name);

    end;

    method toggleAnimation(target: id);
    begin
      var btn := UIButton(target);
      if self.weatherMapView.isAnimating or self.weatherMapView.isLoadingAnimation then
      begin
        btn.selected := false;
        self.weatherMapView.stopAnimating;
      end
      else
      begin
        btn.selected := true;
        self.weatherMapView.startAnimating;
      end;
    end;

    method timelineView(timelineViewParam: AWFTimelineView) didPanToDate(date: NSDate);
    begin
      if self.weatherMapView.config.timelineScrubbingEnabled then
      begin
        self.weatherMapView.pauseAnimation();
        self.weatherMapView.goToTime(date);
      end;
    end;

    method timelineView(timelineViewParam: AWFTimelineView) didSelectDate(date: NSDate);
    begin
      self.weatherMapView.stopAnimating();
      self.weatherMapView.goToTime(date);
    end;

    method weatherMap(weatherMap: AWFWeatherMap) didUpdateTimelineRangeFromDate(fromDate: NSDate) toDate(toDate: NSDate);
    begin
      self.timelineView.startDate := fromDate;
      self.timelineView.endDate := toDate;
      self.timelineView.currentTime := self.weatherMapView.timeline.currentTime;
    end;

    method weatherMapDidStartAnimating(weatherMap: AWFWeatherMap);
    begin
      self.timelineView.playButton.selected := true;
    end;

    method weatherMapDidStopAnimating(weatherMap: AWFWeatherMap);
    begin
      self.timelineView.playButton.selected := false;
    end;

    method weatherMapDidResetAnimation(weatherMapParam: AWFWeatherMap);
    begin
      if(assigned(self.timelineView))then
      begin
        self.timelineView.setProgress(0.0) animated(true);
      end;
    end;

    method weatherMap(weatherMapParam : AWFWeatherMap) animationDidUpdateToDate(date: NSDate);
    begin
      if(assigned(self.timelineView))then
      begin
        self.timelineView.currentTime := date;
      end;
    end;

    method weatherMapDidStartLoadingAnimationData(weatherMap: AWFWeatherMap);
    begin
      if(assigned(self.timelineView))then
      begin
        self.timelineView.playButton.selected := true;
        self.timelineView.showLoading(true);
      end;
    end;

    method weatherMapDidFinishLoadingAnimationData(weatherMap: AWFWeatherMap);
    begin
      if(assigned(self.timelineView))then
      begin
        self.timelineView.setProgress(1.0) animated(true);
        self.timelineView.showLoading(false);
      end;
    end;

    method weatherMapDidCancelLoadingAnimationData(weatherMap: AWFWeatherMap);
    begin
      if(assigned(self.timelineView))then
      begin
        self.timelineView.playButton.selected := false;
        self.timelineView.setProgress(0.0) animated(true);
        self.timelineView.showLoading(false);
      end;
    end;

    method weatherMap(weatherMap: AWFWeatherMap) didUpdateAnimationDataLoadingProgress(totalLoaded: NSInteger) total(total: NSInteger);
    begin
      if(assigned(self.timelineView))then
      begin
        self.timelineView.setProgress(CGFloat(totalLoaded) / CGFloat(total)) animated(true);
      end;
    end;



    method didReceiveMemoryWarning; override;
    begin
      inherited didReceiveMemoryWarning;

      // Dispose of any resources that can be recreated.
    end;


  end;



end.