namespace Moshine.UI.UIKit.Weather;

uses
  iOSApp.Core,
  Moshine.Api.Weather.Models.WeatherUnderground,
  Moshine.UI.UIKit,
  UIKit;

type
  [IBObject]
  ConditionsTableViewController = public class(UITableViewController)
  private
    _service:WeatherService;
  protected

    {$REGION Table view data source}
    method numberOfSectionsInTableView(tableView: UITableView): NSInteger;
    begin
      result := 1;
    end;

    method tableView(tableView: UITableView) numberOfRowsInSection(section: NSInteger): NSInteger;
    begin
      //result := iif(assigned(_conditions),11,0);
      result := 13;
    end;

    method tableView(tableView: UITableView) cellForRowAtIndexPath(indexPath: NSIndexPath): UITableViewCell;
    begin
      var CellIdentifier := "ConditionsTableViewControllerCell";

      result := tableView.dequeueReusableCellWithIdentifier(CellIdentifier);
      if not assigned(result) then
      begin
        result := new MoshineLabelTableViewCell withStyle(UITableViewCellStyle.UITableViewCellStyleDefault) reuseIdentifier(CellIdentifier);
      end;

      var cell := result as MoshineLabelTableViewCell;

      var conditions := assigned(_conditions);

      case indexPath.row of
        0: cell.textLabel.text := iif(conditions,_conditions.Observation.Weather,'Not recorded');
        1: cell.textLabel.text := iif(conditions, NSString.stringWithFormat('Wind %@',_conditions.Observation.WindDirection),'Wind');
        2: cell.textLabel.text := iif(conditions, NSString.stringWithFormat('Wind Direction %d°',_conditions.Observation.WindDegress), 'Wind Direction');
        3: cell.textLabel.text := iif(conditions, NSString.stringWithFormat('%d Knts',_conditions.Observation.WindSpeed),'Knts');
        4: cell.textLabel.text := iif(conditions and (_conditions.Observation.WindSpeedGusting >0), NSString.stringWithFormat('Gusting %d Knts',_conditions.Observation.WindSpeedGusting),'Not Gusting');
        5: cell.textLabel.text := iif(conditions, NSString.stringWithFormat('%0.2f °C',_conditions.Observation.TemperatureC),'°C');
        6: cell.textLabel.text := iif(conditions, NSString.stringWithFormat('%@ humidity',_conditions.Observation.RelativeHumidity),'humidity');
        7: cell.textLabel.text := iif(conditions, NSString.stringWithFormat('1hr %0.2f inch Precipitation',_conditions.Observation.Precipitation1hrInch),'1hr Precipitation');
        8: cell.textLabel.text := iif(conditions, NSString.stringWithFormat('Today %0.2f inch Precipitation',_conditions.Observation.PrecipitationTodayInch),'Precipitation for today');
        9: cell.textLabel.text := iif(conditions, NSString.stringWithFormat('Visibilty %0.2f miles',_conditions.Observation.VisibilityM),'Visibility');
        10: cell.textLabel.text := iif(conditions, NSString.stringWithFormat('Pressure %d Mb',_conditions.Observation.PressureMb),'Pressure');
        11: cell.textLabel.text := iif(conditions, NSString.stringWithFormat('Observation Time : %@ ', DateUtils.epochToDate(_conditions.Observation.ObservationEpoch).FormatDateTimeForDisplay),'Observation Time :');
        12: cell.textLabel.text := iif(conditions, NSString.stringWithFormat('Local Time : %@', DateUtils.epochToDate(_conditions.Observation.LocalEpoch).FormatDateTimeForDisplay),'Local Time :');
      end;

    end;

    method tableView(tableView: UITableView) canEditRowAtIndexPath(indexPath: NSIndexPath): Boolean;
    begin
      result := false;
    end;

    method tableView(tableView: UITableView) commitEditingStyle(editingStyle: UITableViewCellEditingStyle) forRowAtIndexPath(indexPath: NSIndexPath);
    begin

      if (editingStyle = UITableViewCellEditingStyle.UITableViewCellEditingStyleDelete) then
      begin
        // Delete the row from the data source
        tableView.deleteRowsAtIndexPaths([indexPath]) withRowAnimation(UITableViewRowAnimation.UITableViewRowAnimationFade);
      end
      else if (editingStyle = UITableViewCellEditingStyle.UITableViewCellEditingStyleInsert) then begin
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
      end;
    end;


    method tableView(tableView: UITableView) canMoveRowAtIndexPath(indexPath: NSIndexPath): Boolean;
    begin
      exit false;
    end;

    method tableView(tableView: UITableView) moveRowAtIndexPath(fromIndexPath: NSIndexPath) toIndexPath(toIndexPath: NSIndexPath);
    begin
    end;

    {$ENDREGION}

    {$REGION Table view delegate}
    method tableView(tableView: UITableView) didSelectRowAtIndexPath(indexPath: NSIndexPath);
    begin
    end;
    {$ENDREGION}

    _conditions:Conditions;

    method loadWeather;
    begin
      if(assigned(self.WeatherStation))then
      begin

        self._service.conditionsForStation(self.WeatherStation) callback(method(someConditions:Conditions) begin
          _conditions := someConditions;
          self.tableView.reloadData;

          self.title := self.WeatherStation.ForDisplay;

        end);

      end;

    end;

  public
    property WeatherStation:Station;

    constructor withService(service:WeatherService);
    begin
      inherited constructor;

      _service := service;
    end;

    method init: instancetype; override;
    begin
      self := inherited initWithStyle(UITableViewStyle.UITableViewStylePlain);
      if assigned(self) then
      begin
      end;
      result := self;
    end;

    method viewDidLoad; override;
    begin
      inherited viewDidLoad;
    end;

    method viewDidAppear(animated: BOOL); override;
    begin
      inherited viewDidAppear(animated);

      loadWeather;
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
      loadWeather;
    end;


    method viewWillDisappear(animated:Boolean); override;
    begin
      inherited viewWillDisappear(animated);

      self.navigationController.setToolbarItems([]) animated(false);
      self.navigationController.setToolbarHidden(true) animated(false);

    end;


    method didReceiveMemoryWarning; override;
    begin
      inherited didReceiveMemoryWarning;

    end;
  end;

end.