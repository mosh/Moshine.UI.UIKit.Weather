namespace Moshine.UI.UIKit.Weather;

uses
  CoreLocation,
  Moshine.Api.Weather,
  Moshine.Api.Weather.Models.WeatherUnderground,
  Moshine.UI.UIKit.Weather.Models,
  RemObjects.Elements.Linq,
  Realm.Realm;

type

  LocationsCollectionDelegate = public block(locations:NSArray<Station>);
  ConditionsDelegate = public block(foundConditions:Conditions);


  WeatherService = public class
  private
    _api:WeatherUndergroundApi;
    _workerQueue:NSOperationQueue;
  protected
  public

    constructor(apiKey:String);
    begin
      _workerQueue := new NSOperationQueue();

      _api := new WeatherUndergroundApi(apiKey);

    end;

    method conditionsForStation(weatherStation:Station) callback(callback:ConditionsDelegate);
    begin
      var outerExecutionBlock: NSBlockOperation := NSBlockOperation.blockOperationWithBlock(method
      begin
        var someConditions:Conditions;

        if (weatherStation is PersonalStation)then
        begin
          someConditions :=  _api.conditionsForPersonalWeatherStation((weatherStation as PersonalStation).Id);
        end
        else
        begin
          someConditions := _api.conditionsForName(AirportStation(weatherStation).ICAO);
        end;

        NSOperationQueue.mainQueue().addOperationWithBlock(method()
          begin
            callback(someConditions);
          end);

      end);

      _workerQueue.addOperation(outerExecutionBlock);

    end;

    method Favourites:NSArray<Favourite>;
    begin
      exit Favourite.allObjectsInRealm(RLMRealm.defaultRealm).array;
    end;

    method removeStationFromFavorites(station:Station);
    begin

    end;

    method addStationToFavorites(station:Station);
    begin

    end;


    method stationsForLocation(currentLocation:CLLocationCoordinate2D) callback(callback:LocationsCollectionDelegate);
    begin
      var outerExecutionBlock: NSBlockOperation := NSBlockOperation.blockOperationWithBlock(method
            begin

              var location := _api.geoLookup(currentLocation);

              NSOperationQueue.mainQueue().addOperationWithBlock(method()
              begin

                var stations := new NSMutableArray<Station>;

                for each station in location.NearbyWeatherStations do
                begin
                  stations.addObject(station);
                end;

                callback(stations);
              end);


            end);
      _workerQueue.addOperation(outerExecutionBlock);

    end;

  end;

end.