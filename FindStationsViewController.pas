namespace Moshine.UI.UIKit.Weather;

uses
  MapKit,
  Moshine.Api.Weather.Models.WeatherUnderground,
  Moshine.UI.UIKit.Weather.Services,
  Moshine.UI.UIKit.Weather.Extensions,
  PureLayout,
  UIKit;

type
  [IBObject]
  FindStationsViewController = public class(UIViewController, IUITableViewDataSource,IUITableViewDelegate,IMKMapViewDelegate)
  private
    _mapView:MKMapView;
    _tableView:UITableView;
    _didSetupConstraints:Boolean;
    _startObserving:Boolean;

    _lastLocationCordinate:CLLocationCoordinate2D;
    _service:WeatherService;
    _locatedStations:NSMutableArray<Station>;

    method mapView(mapView: not nullable MKMapView) regionDidChangeAnimated(animated: BOOL);
    begin

    end;

    method mapView(mapView: not nullable MKMapView) regionWillChangeAnimated(animated: BOOL);
    begin
      if(_startObserving)then
      begin
        var region:MKCoordinateRegion := mapView.region;
        var center := region.center;
        var mapRect:MKMapRect := mapView.visibleMapRect;

        var cornerPointNW:MKMapPoint := MKMapPointMake(mapRect.origin.x, mapRect.origin.y);
        var cornerCoordinate:CLLocationCoordinate2D := MKCoordinateForMapPoint(cornerPointNW);

        // Then get the center coordinate of the mapView (just a shortcut for convenience)
        var centerCoordinate:CLLocationCoordinate2D := mapView.centerCoordinate;

        var currentDate := new NSDate;

        var cornerLocation := new CLLocation withCoordinate(cornerCoordinate) altitude(1) horizontalAccuracy(1) verticalAccuracy(1) timestamp(currentDate);
        var centerLocation := new CLLocation withCoordinate(centerCoordinate) altitude(1) horizontalAccuracy(1) verticalAccuracy(1) timestamp(currentDate);

        // And then calculate the distance
        var distance:CLLocationDistance := cornerLocation.distanceFromLocation(centerLocation);

        var miles := distance * 0.000621371192;

        if(miles < 100)then
        begin

          if(assigned(self._lastLocationCordinate))then
          begin
            var lastLocation := new CLLocation withCoordinate(_lastLocationCordinate) altitude(1) horizontalAccuracy(1) verticalAccuracy(1) timestamp(currentDate);

            var lastDistance:CLLocationDistance := centerLocation.distanceFromLocation(lastLocation);

            var lastMiles := lastDistance * 0.000621371192;

            if(lastMiles<40)then
            begin
              exit;
            end;

          end;

          self._service.stationsForLocation(centerCoordinate) callback(method (stations:NSArray<Station>)begin

              replaceWithNewStations(stations);
            end);

          _lastLocationCordinate := centerCoordinate;

        end
        else
        begin
          clearScreen;
        end;

        NSLog('%f',miles);
      end;
    end;

    method mapViewDidFinishRenderingMap(mapView: not nullable MKMapView) fullyRendered(fullyRendered: BOOL);
    begin
      if(fullyRendered)then
      begin
        _startObserving:=true;
      end;
    end;


    method numberOfSectionsInTableView(tableView: UITableView): NSInteger;
    begin
      result := 1;
    end;

    method tableView(tableView: UITableView) numberOfRowsInSection(section: NSInteger): NSInteger;
    begin
      exit _locatedStations.count;
    end;

    method tableView(tableView: UITableView) cellForRowAtIndexPath(indexPath: NSIndexPath): UITableViewCell;
    begin
      var CellIdentifier := 'FindStationsViewControllerCell';

      result := tableView.dequeueReusableCellWithIdentifier(CellIdentifier);
      if not assigned(result) then
      begin
        result := new UITableViewCell withStyle(UITableViewCellStyle.UITableViewCellStyleDefault) reuseIdentifier(CellIdentifier);
      end;

      var &index := indexPath.row;
      var someStation := self._locatedStations[&index];

      result.text := someStation.ForDisplay;
    end;

    method clearScreen;
    begin
      if(self._locatedStations.count>0)then
      begin
        self._mapView.removeAnnotations(self._locatedStations);

        self._locatedStations.removeAllObjects;

        self._tableView.reloadData;

      end;

    end;

    method replaceWithNewStations(stations:NSArray<Station>);
    begin
      self._mapView.removeAnnotations(self._locatedStations);
      self._locatedStations.removeAllObjects;

      self._locatedStations.addObjectsFromArray(stations);
      self._mapView.addAnnotations(self._locatedStations);

      self._tableView.reloadData;

    end;

    {$REGION Table view delegate}
    method tableView(tableView: UITableView) didSelectRowAtIndexPath(indexPath: NSIndexPath);
    begin

      var conditionsController := new ConditionsTableViewController withService(self._service);

      conditionsController.WeatherStation := self._locatedStations[indexPath.row];

      navigationController.pushViewController(conditionsController) animated(true);

    end;

    method tableView(tableView:UITableView) trailingSwipeActionsConfigurationForRowAtIndexPath(indexPath: NSIndexPath):UISwipeActionsConfiguration;
    begin

      var actions:NSArray := [];

      var action := UIContextualAction.contextualActionWithStyle(UIContextualActionStyle.Normal) title('Favourite') handler(method (action:UIContextualAction;sourceView:UIView;completionHandler:block(actionPerformed:Boolean)) begin

          var station := self._locatedStations[indexPath.row];

          self._service.addStationToFavorites(station);

          completionHandler(true);
        end);

      actions := [action];

      exit UISwipeActionsConfiguration.configurationWithActions(actions);

    end;


    {$ENDREGION}


  public

    method initWithService(service:WeatherService) : InstanceType;
    begin
      self := inherited init;
      if assigned(self) then
      begin
        _locatedStations := new NSMutableArray<Station>;
        // Custom initialization
        _service := service;

        self._mapView := new MKMapView;
        self._mapView.delegate := self;
        self.view.addSubview(_mapView);
        self._tableView := new UITableView;
        self._tableView.dataSource := self;
        self._tableView.delegate := self;
        self.view.addSubview(_tableView);
        self.view.setNeedsUpdateConstraints;


      end;
      result := self;
    end;


    method updateViewConstraints;override;
    begin

      if(not _didSetupConstraints)then
      begin
        self._mapView.autoPinEdgeToSuperviewEdge(ALEdge.Left);
        self._mapView.autoPinEdgeToSuperviewEdge(ALEdge.Right);
        self._mapView.autoPinEdgeToSuperviewEdge(ALEdge.Top);
        self._mapView.autoPinEdgeToSuperviewEdge(ALEdge.Bottom) withInset(200);

        self._tableView.autoPinEdge(ALEdge.Left) toEdge(ALEdge.Left) ofView(_mapView);
        self._tableView.autoPinEdge(ALEdge.Right) toEdge(ALEdge.Right) ofView(_mapView);
        self._tableView.autoPinEdge(ALEdge.Top) toEdge(ALEdge.Bottom) ofView(_mapView);
        self._tableView.autoPinEdgeToSuperviewEdge(ALEdge.Bottom);


        _didSetupConstraints := true;
      end;

      inherited updateViewConstraints;
    end;

    method viewDidLoad; override;
    begin
      inherited viewDidLoad;

      // Do any additional setup after loading the view.

    end;

    method didReceiveMemoryWarning; override;
    begin
      inherited didReceiveMemoryWarning;

      // Dispose of any resources that can be recreated.
    end;


  end;

end.