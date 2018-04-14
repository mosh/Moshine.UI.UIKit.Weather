namespace Moshine.UI.UIKit.Weather.Models;

uses
  Foundation;

type


  Favourite = public class(DataObject)
  private
  protected
  public

    const PersonalWeatherStation = 1;
    const Airport = 2;

    property Id:Integer;
    property FavouriteType:Integer;
    property PWSId:String;
    property Name:String;
    property ICAO:String;
    property City:String;
    property Neighbourhood:String;
  end;

end.