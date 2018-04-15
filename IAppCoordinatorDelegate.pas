namespace Moshine.UI.UIKit.Weather;

uses
  Foundation,
  CoreLocation;

type

  IAppCoordinatorDelegate = public interface
    method locationUpdate(someLocation:CLLocation);
    begin
    end;

    method receiveLocationUpdate(eventDate:NSDate):Boolean;
    begin
      exit false;
    end;

  end;

end.