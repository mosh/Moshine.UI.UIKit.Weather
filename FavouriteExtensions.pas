namespace Moshine.UI.UIKit.Weather;

uses
    Foundation,
    Moshine.Api.Weather.Models.WeatherUnderground,
    Moshine.UI.UIKit.Weather.Models;

type

  FavouriteExtensions = public extension class(Favourite)
  private
  protected
  public

    method ForDisplay:String;
    begin
      exit iif(self.FavouriteType = Favourite.PersonalWeatherStation, self.Neighbourhood, NSString.stringWithFormat('%@ - %@',self.ICAO, self.City));
    end;

    method AsStation:Station;
    begin
      var someStation:Station;

      case self.FavouriteType of
        Favourite.PersonalWeatherStation :
          begin
            someStation := new PersonalStation( Id := self.PWSId, Neighborhood := self.Neighbourhood);
          end;
        Favourite.Airport:
          begin
            someStation := new AirportStation(ICAO := self.ICAO, City := self.City);
          end
      end;

      exit someStation;


    end;

  end;

end.