namespace Moshine.UI.UIKit.Weather;

uses
  MapKit,
  PureLayout,
  UIKit;

type
  [IBObject]
  FindStationsViewController = public class(UIViewController, IUITableViewDataSource,IUITableViewDelegate)
  private
    _mapView:MKMapView;
    _tableView:UITableView;
    _didSetupConstraints:Boolean;

  public

    method tableView(tableView: UITableView) numberOfRowsInSection(section: NSInteger): NSInteger;
    begin
      exit 0;
    end;

    method tableView(tableView: UITableView) cellForRowAtIndexPath(indexPath: NSIndexPath): UITableViewCell;
    begin
      var CellIdentifier := 'FindStationsViewControllerCell';
      exit nil;
    end;


    method init: instancetype; override;
    begin
      self := inherited init;
      if assigned(self) then
      begin

        self._mapView := new MKMapView;
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