import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:milog/services/authentication.dart';
import 'package:flutter/material.dart';
import 'package:milog/model/Trip.dart';
import 'package:milog/ui/log_screen.dart';
import 'package:milog/ui/trip_action.dart';

class ListViewLog extends StatefulWidget {
  ListViewLog({Key key, this.auth, this.userId, this.onSignedOut})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback onSignedOut;
  final String userId;

  @override
  //This is the state of ListViewLogs
  _ListViewLogState createState() => new _ListViewLogState();
}

class _ListViewLogState extends State<ListViewLog> {
  //List of Trips
  List<Trip> _tripList;
  bool tripInProgress;

  var tripsReference;

  //The database reference
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  StreamSubscription<Event> _onTripAddedSubscription;
  StreamSubscription<Event> _onTripChangedSubscription;

  //Query to get the User's trips
  Query _tripQuery;

  @override
  void initState() {
    super.initState();
    tripInProgress = false;

    _tripList = new List();
    _tripQuery = _database
        .reference()
        .child("Trips")
        .orderByChild("userID")
        .equalTo(widget.userId);

    //Turns on Persistence
    FirebaseDatabase.instance.setPersistenceEnabled(true);
    tripsReference = _database.reference().child('Trips');

    //TODO: Need to add Listener for when the database data changes
    _onTripAddedSubscription = _tripQuery.onChildAdded.listen(_onLogAdded);
    _onTripChangedSubscription =
        _tripQuery.onChildChanged.listen(_onLogUpdated);
  }

  @override
  void dispose() {
    _onTripAddedSubscription.cancel();
    _onTripChangedSubscription.cancel();
    super.dispose();
  }

  Widget _showTripSubtitle(bool inProg, int position) {
    if (inProg) {
      return Text(
        "Active car: " + _tripList[position].vehicle.toString(),
        style: TextStyle(
          fontSize: 18.0,
          fontStyle: FontStyle.italic,
        ),
      );
    } else {
      return Text(
        "Miles Traveled: " + _tripList[position].milesTraveled.toString(),
        style: TextStyle(
          fontSize: 18.0,
          fontStyle: FontStyle.italic,
        ),
      );
    }
  }

  Widget _showTripList() {
    if (_tripList.length > 0) {
      return ListView.builder(
          //How many items in the list
          itemCount: _tripList.length,
          padding: const EdgeInsets.all(15.0),
          itemBuilder: (context, position) {
            return Column(
              children: <Widget>[
                Divider(height: 5.0),
                Divider(
                  height: 5.0,
                ),
                Container(
                  
                  decoration: 
                  (_tripList[position].inProgress)
                      ? new BoxDecoration(color: Colors.yellow[300], border: new Border.all(color: Colors.grey, width: 2))
                      : new BoxDecoration(color: Colors.white, border: new Border.all(color: Colors.grey, width: 2)),
                  //If trip is in progress, the containers is yellow
                  child: ListTile(
                      title: Text(
                        _tripList[position].notes.toString(),
                        style: TextStyle(
                          fontSize: 22.0,
                          color: Colors.black,
                        ),
                      ),
                      subtitle: _showTripSubtitle(
                          _tripList[position].inProgress, position),
                      leading: _tripIcon(_tripList[position].inProgress,
                          _tripList[position].paused),


                      //TAP
                      onTap: () {
                        if (_tripList[position].inProgress) {
                          _navigateToTripAction(context, _tripList[position]);
                        } else {
                          _navigateToLog(context, _tripList[position]);
                        }
                      },
                      //LONG PRESS
                      onLongPress: () =>
                          checkIfCanDel(context, _tripList[position],position)),
                ),
              ],
            );
          });
    } else {
      return Center(
          child: Text(
        "No trip logs",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 30.0),
      ));
    }
  }

  //Decides what icon to put into the trip ListTile (that's in a container)
  Widget _tripIcon(bool inProg, bool paused) {
    if (inProg && !paused)
      return Icon(Icons.drive_eta, color: Colors.blue[300]);
    else if (inProg && paused)
      return Icon(Icons.watch_later, color: Colors.orange);
    else {
      return Icon(Icons.check_circle, color: Colors.green[300]);
    }
  }

  Widget _showDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
              child: Container(
            child: Text(
              'Main Menu',
              style: TextStyle(
                fontSize: 24.0,
                color: Colors.black,
              ),
            ),
            margin: const EdgeInsets.only(bottom: 10.0),
            width: 10.0,
            height: 10.0,
            decoration: new BoxDecoration(
              shape: BoxShape.rectangle,
              image: DecorationImage(
                image: AssetImage("images/miLog.png"),
                alignment: Alignment(1, 1),
                fit: BoxFit.scaleDown,
              ),
              //Add the Drawer image here (user icon perhaps?)
            ),
          )),
          ListTile(
            title: Text('Trips'),
            leading: new Icon(Icons.speaker_notes, color: Colors.blueAccent),
            onTap: () {
              //Since we're currently in ListViewLog, do nothing
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Account'),
            leading: new Icon(Icons.perm_identity, color: Colors.black),
            onTap: () {
              // Update the state of the app
              // ...
              // Then close the drawer
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('Vehicles'),
            leading: new Icon(Icons.directions_car, color: Colors.blue),
            onTap: () {
              // Update the state of the app
              // ...
              // Then close the drawer
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: new Icon(Icons.exit_to_app, color: Colors.red[300]),
            title: Text('Sign Out'),
            onTap: () {
              _signOut();
              // Update the state of the app
              // ...
              // Then close the drawer
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  /*We need to return a Scaffold instead of another instance of
  Material app for the Drawer to work
  */
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("MiLog")),
      drawer: _showDrawer(context),
      body: Scaffold(
        body: Center(
          child: _showTripList(),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () => _createNewLog(context),
        ),
      ),
    );
  }

  void _onLogAdded(Event event) {
    setState(() {
      print("Entered _onLogAdded!");
      print("onLogAdded added a Trip to the _tripList list!");
      _tripList.add(new Trip.fromSnapshot(event.snapshot));
      isTripInProg();
    });
  }

  void _onLogUpdated(Event event) {
    var oldLogValue =
        _tripList.singleWhere((trip) => trip.tripID == event.snapshot.key);
    setState(() {
      print("Entered _onLogUpdated!");
      _tripList[_tripList.indexOf(oldLogValue)] =
          new Trip.fromSnapshot(event.snapshot);
      isTripInProg();
    });
  }

  //Check to make sure we can't delete a trip that is in progress
  void checkIfCanDel(BuildContext context, Trip trip, int position) {
    if(!trip.inProgress)
      _showConfimDelDialog(context, trip, position);
  }

  void _deleteTrip(BuildContext context, Trip trip, int position) async {
    await tripsReference.child(trip.tripID).remove().then((_) {
      setState(() {
        _tripList.removeAt(position);
      });
    });
  }

  void _navigateToLog(BuildContext context, Trip trip) async {
    await Navigator.push(
      context,
      //We want to update the Trip, so pass true
      MaterialPageRoute(
          builder: (context) => LogScreen(widget.userId, trip, true)),
    );
  }

  void _navigateToTripAction(BuildContext context, Trip trip) async {
    await Navigator.push(
      context,
      //We want to update the Trip, so pass true
      MaterialPageRoute(builder: (context) => TripAction(widget.userId, trip)),
    );
  }

  void _createNewLog(BuildContext context) async {
    //If there is a trip in progress
    if (tripInProgress) {
      _showDialogTripInProgress();
    } else {
      /*
      Mobile apps typically reveal their contents via full-screen elements called "screens" or "pages". 
      In Flutter these elements are called routes and they're managed by a Navigator widget. 
      The navigator manages a stack of Route objects and provides methods for managing the stack, like Navigator.push and Navigator.pop.
      */
      await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                LogScreen(widget.userId, Trip.newTrip(), false),
          ));
    }
  }

  //Signs out the user
  void _signOut() async {
    try {
      await widget.auth.signOut();
      widget.onSignedOut();
    } catch (e) {
      print(e);
    }
  }

  //Sets tripInProgress if a trip is in progress, otherwise sets to false
  void isTripInProg() {
    bool inProgress = false;
    for (Trip t in _tripList) {
      if (t.inProgress) {
        tripInProgress = true;
        inProgress = true;
      }
    }
    (inProgress) ? makeInProgFirst() : tripInProgress = false;
  }

  //Swaps the first index trip with trip that is in progress
  void makeInProgFirst() {
    if (_tripList.length > 0) {
      for (int i = 0; i < _tripList.length; i++) {
        Trip temp;
        if (_tripList[i].inProgress) {
          temp = _tripList[0];
          _tripList[0] = _tripList[i];
          _tripList[i] = temp;
        }
      }
    }
  }

  // user defined function
  void _showConfimDelDialog(BuildContext context, Trip trip, int position) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: Text("Delete Trip",
              style: TextStyle(fontSize: 18.0, color: Colors.red)),
          content: Text("Are you sure you want to delete this trip?",
              style: TextStyle(fontSize: 18.0, color: Colors.black)),
          actions: <Widget>[
            //buttons at the bottom of the dialog
            FlatButton(
              child: Text(
                "Yes",
                style: TextStyle(fontSize: 18.0, color: Colors.red),
              ),
              onPressed: () {
                _deleteTrip(context, trip, position);
                Navigator.of(context).pop();
              },
            ),
             FlatButton(
              child: Text(
                "No",
                style: TextStyle(fontSize: 18.0, color: Colors.black),
              ),
              onPressed: () {
                
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  //Dialog that shows a trip is in progress
  void _showDialogTripInProgress() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // return object of type Dialog
        return AlertDialog(
          title: Text("Oops!",
              style: TextStyle(fontSize: 18.0, color: Colors.black)),
          content: Text("A Trip is already in progress.",
              style: TextStyle(fontSize: 18.0, color: Colors.black)),
          actions: <Widget>[
            //buttons at the bottom of the dialog
            FlatButton(
              child: Text(
                "Ok",
                style: TextStyle(fontSize: 18.0, color: Colors.blueAccent),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
