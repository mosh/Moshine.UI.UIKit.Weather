namespace Moshine.UI.UIKit.Weather.Services;

uses
  CoreLocation,
  Moshine.Api.Weather,
  Moshine.Api.Weather.Models.WeatherUnderground,
  Moshine.UI.UIKit.Weather.Models,
  RemObjects.Elements.Linq,
  Realm;

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
      var defaultRealm := RLMRealm.defaultRealm;
      defaultRealm.beginWriteTransaction;


      if(station is PersonalStation)then
      begin
        var ps := station as PersonalStation;
        var fav := Favourite.allObjectsInRealm(defaultRealm).FirstOrDefault(r -> r.PWSId = ps.Id);

        if(assigned(fav))then
        begin
          defaultRealm.deleteObject(fav);
        end;

      end
      else if(station is AirportStation)then
      begin
        var airS := station as AirportStation;

        var fav := Favourite.allObjectsInRealm(defaultRealm).FirstOrDefault(r -> r.ICAO = airS.ICAO);

        if(assigned(fav))then
        begin
          defaultRealm.deleteObject(fav);
        end;


      end
      else
      begin
        raise new NotImplementedException;
      end;

      defaultRealm.commitWriteTransaction;


    end;

    method addStationToFavorites(station:Station);
    begin

      var newFavourite:Favourite := nil;
      var maxValue:Integer := 0;

      if(Favourite.allObjectsInRealm(RLMRealm.defaultRealm).Any)then
      begin
        maxValue := Favourite.allObjectsInRealm(RLMRealm.defaultRealm).Max(r -> Favourite(r).Id);
      end;


      if(station is PersonalStation)then
      begin
        var ps := station as PersonalStation;
        newFavourite := new Favourite(Id:=maxValue+1, Neighbourhood := ps.Neighborhood, PWSId := ps.Id, FavouriteType:=Favourite.PersonalWeatherStation);
      end
      else if(station is AirportStation)then
      begin
        var airS := station as AirportStation;
        newFavourite := new Favourite(Id:=maxValue+1, City := airS.City, ICAO := airS.ICAO, FavouriteType:=Favourite.Airport);
      end
      else
      begin
        raise new NotImplementedException;
      end;

      if(assigned(newFavourite))then
      begin

        var defaultRealm := RLMRealm.defaultRealm;
        defaultRealm.beginWriteTransaction;
        defaultRealm.addObject(newFavourite);
        defaultRealm.commitWriteTransaction;

      end;

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