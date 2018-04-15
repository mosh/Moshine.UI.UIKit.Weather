namespace Moshine.UI.UIKit.Weather;

uses
  Foundation,
  Moshine.Api.Weather.Models.WeatherUnderground;

type
  StationExtensions = public extension class(Station)
  private
  protected
  public

    method ForDisplay:String;
    begin
      exit iif(self is PersonalStation, PersonalStation(self).Neighborhood, NSString.stringWithFormat('%@ - %@',AirportStation(self).ICAO, AirportStation(self).City));
    end;

  end;

end.