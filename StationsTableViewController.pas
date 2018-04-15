namespace Moshine.UI.UIKit.Weather;

uses
  CoreLocation,
  Moshine.Api.Weather.Models.WeatherUnderground,
  Moshine.UI.UIKit.Weather,
  Moshine.UI.UIKit.Weather.Models,
  UIKit;

type
  [IBObject]
  StationsTableViewController = public class(UITableViewController, IAppCoordinatorDelegate)
  private
    _favouriteStations:NSMutableArray<Favourite> := new NSMutableArray<Favourite>;
    _nearbyPersonal:NSMutableArray<Station> := new NSMutableArray<Station>;
    _nearbyAirports:NSMutableArray<Station> := new NSMutableArray<Station>;
    _service:WeatherService;
    _coordinator:IWeatherUpdatesCoordinator;

    lastLocation:CLLocationCoordinate2D;
    updatedLastLocation:Boolean := false;

    method loadFavourites;
    begin
      self._favouriteStations.removeAllObjects;
      var someFavourites := self._service.Favourites;
      for each item in someFavourites do
        begin
        self._favouriteStations.addObject(item);
      end;
    end;

    method locationUpdate(someLocation:CLLocation);
    begin

      NSLog('lat %f long %f', someLocation.coordinate.latitude, someLocation.coordinate.longitude);

      if(not updatedLastLocation)then
      begin
        populateUI(someLocation.coordinate);
      end;
      updatedLastLocation := true;
      lastLocation := someLocation.coordinate;

    end;

    method receiveLocationUpdate(eventDate:NSDate):Boolean;
    begin

      var howRecent: NSTimeInterval := eventDate.timeIntervalSinceNow();
      NSLog('%f',abs(howRecent));

      exit true;
    end;

    method indexPathAsStation(indexPath:NSIndexPath):Station;
    begin
      case indexPath.section of
        0: exit _favouriteStations[indexPath.row].AsStation;
        1: exit _nearbyAirports[indexPath.row];
        2: exit _nearbyPersonal[indexPath.row];
      end;

    end;




  protected

    {$REGION Table view data source}
    method numberOfSectionsInTableView(tableView: UITableView): NSInteger;
    begin
      result := 3;
    end;

    method tableView(tableView: UITableView) numberOfRowsInSection(section: NSInteger): NSInteger;
    begin
      case section of
        0: exit _favouriteStations.count;
        1: exit _nearbyAirports.count;
        2: exit _nearbyPersonal.count;
      end;
      exit 0;
    end;


    method tableView(tableView: UITableView) cellForRowAtIndexPath(indexPath: NSIndexPath): UITableViewCell;
    begin
      var CellIdentifier := 'RootViewControllerCell';

      result := tableView.dequeueReusableCellWithIdentifier(CellIdentifier);
      if not assigned(result) then
      begin
        result := new UITableViewCell withStyle(UITableViewCellStyle.UITableViewCellStyleDefault) reuseIdentifier(CellIdentifier);
        // Configure the new cell, if necessary...
      end;

      // Configure the individual cell...
      var &index := indexPath.row;
      var someStation:Station;
      var someFavourite:Favourite;

      case indexPath.section of
        0:
          begin
            someFavourite := _favouriteStations[&index];
          end;
        1:
          begin
            someStation := _nearbyAirports[&index];
          end;
        2:begin
            someStation := _nearbyPersonal[&index];
          end;
      end;

      var textForDisplay:='';

      if (assigned(someStation))then
      begin
        textForDisplay := someStation.ForDisplay;
      end
      else if(assigned(someFavourite))then
      begin
        textForDisplay := someFavourite.ForDisplay;
      end;

      result.text := textForDisplay;

    end;

    method tableView(tableView: UITableView) canEditRowAtIndexPath(indexPath: NSIndexPath): Boolean;
    begin
      result := true;
    end;

    method tableView(tableView: UITableView) commitEditingStyle(editingStyle: UITableViewCellEditingStyle) forRowAtIndexPath(indexPath: NSIndexPath);
    begin
      if (editingStyle = UITableViewCellEditingStyle.UITableViewCellEditingStyleDelete) then begin
        // Delete the row from the data source
        tableView.deleteRowsAtIndexPaths([indexPath]) withRowAnimation(UITableViewRowAnimation.UITableViewRowAnimationFade);
      end
      else if (editingStyle = UITableViewCellEditingStyle.UITableViewCellEditingStyleInsert) then begin
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
      end;
    end;

    method tableView(tableView: UITableView) canMoveRowAtIndexPath(indexPath: NSIndexPath): Boolean;
    begin
      result := false;
    end;

    method tableView(tableView: UITableView) moveRowAtIndexPath(fromIndexPath: NSIndexPath) toIndexPath(toIndexPath: NSIndexPath);
    begin
    end;

    {$ENDREGION}

    {$REGION Table view delegate}
    method tableView(tableView: UITableView) didSelectRowAtIndexPath(indexPath: NSIndexPath);
    begin

      var conditionsController := new ConditionsTableViewController withService(self._service);

      conditionsController.WeatherStation := indexPathAsStation(indexPath);

      navigationController.pushViewController(conditionsController) animated(true);

    end;

    method tableView(tableView:UITableView) trailingSwipeActionsConfigurationForRowAtIndexPath(indexPath: NSIndexPath):UISwipeActionsConfiguration;
    begin

      var actions:NSArray := [];

      if(indexPath.section>0)then
      begin
        var action := UIContextualAction.contextualActionWithStyle(UIContextualActionStyle.Normal) title('Favourite') handler(method (action:UIContextualAction;sourceView:UIView;completionHandler:block(actionPerformed:Boolean)) begin

            var station := indexPathAsStation(indexPath);

            self._service.addStationToFavorites(station);
            self.loadFavourites;
            self.tableView.reloadData;

            completionHandler(true);
          end);

        actions := [action];
      end
      else
      begin
        var action := UIContextualAction.contextualActionWithStyle(UIContextualActionStyle.Normal) title('Remove') handler(method (action:UIContextualAction;sourceView:UIView;completionHandler:block(actionPerformed:Boolean)) begin

          var station := indexPathAsStation(indexPath);

          self._service.removeStationFromFavorites(station);
          self.loadFavourites;
          self.tableView.reloadData;

          completionHandler(true);
        end);

        actions := [action];
      end;
      exit UISwipeActionsConfiguration.configurationWithActions(actions);

    end;

    {$ENDREGION}

    method tableView(tableView: not nullable UITableView) titleForHeaderInSection(section: NSInteger): nullable NSString;
    begin
      case section of
        0: exit 'Favorites';
        1: exit 'Airports';
        2: exit 'Personal';
        else
          exit nil;
        end;
      end;

  public

    method initWithService(service:WeatherService) withCoordinator(coordinator:IWeatherUpdatesCoordinator) : instancetype;
    begin
      self := inherited initWithStyle(UITableViewStyle.UITableViewStylePlain);
      if assigned(self) then
      begin

        // Custom initialization
        _service := service;
        _coordinator := coordinator;

      end;
      result := self;
    end;


    method viewDidAppear(animated: BOOL); override;
    begin
      inherited viewDidAppear(animated);

      NSLog('%@','viewDidAppear');

      loadFavourites;

      self.tableView.reloadData;


      self._coordinator.startSignificantChangeUpdates;

    end;

    method viewDidLoad; override;
    begin
      inherited viewDidLoad;
      NSLog('%@','viewDidLoad');

    end;

    method viewWillAppear(animated:Boolean); override;
    begin
      inherited viewWillAppear(animated);

      self.navigationController.setToolbarHidden(false) animated(false);

      var items: NSMutableArray := new NSMutableArray;
      var addButton := new UIBarButtonItem withImage(UIImage.imageNamed('RefreshImage')) style(UIBarButtonItemStyle.Plain) target(self) action(selector(refreshAction:));
      items.addObject(addButton);

      self.setToolbarItems(items) animated(true);

    end;

    [IBAction]
    method refreshAction(sender:id);
    begin
    end;


    method viewWillDisappear(animated:Boolean); override;
    begin
      inherited viewWillDisappear(animated);

      self.navigationController.setToolbarItems([]) animated(false);
      self.navigationController.setToolbarHidden(true) animated(false);

    end;


    method populateUI (someLocation:CLLocationCoordinate2D);
    begin

      self._service.stationsForLocation(someLocation) callback(method (stations:NSArray<Station>) begin

        _nearbyPersonal.removeAllObjects;

        for each station in stations do
          begin
          if station is AirportStation then
          begin
            _nearbyAirports.addObject(station);
          end
          else
          begin
            _nearbyPersonal.addObject(station);
          end;
        end;

        self.tableView.reloadData;
      end);

    end;

    method didReceiveMemoryWarning; override;
    begin
      inherited didReceiveMemoryWarning;

      // Dispose of any resources that can be recreated.
    end;

  end;

end.