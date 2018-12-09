import 'dart:async';
import 'package:logging/logging.dart';

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';

void main() => runApp(new MyApp());

final Logger logger = new Logger("global logger");

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  Future<Null> _showAddUserDialogBox(BuildContext context) {
    TextEditingController _nameTextController = new TextEditingController();
    TextEditingController _emailTextController = new TextEditingController();

    return showDialog<Null>(
      context: context,
      builder: (BuildContext context) {
        return new AlertDialog(
          title: const Text("Add a contact"),
          content: Container(
            height: 120.0,
            width: 100.0,
            child: ListView(
              children: <Widget>[
                new TextField(
                  controller: _nameTextController,
                  decoration: const InputDecoration(labelText: "Name: "),
                ),
                new TextField(
                  controller: _emailTextController,
                  decoration: const InputDecoration(labelText: "Email: "),
                ),

              ],
            ),
          ),
          actions: <Widget>[

            new FlatButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel")
            ),
            // This button results in adding the contact to the database
            new FlatButton(
                onPressed: () {

                  CloudFunctions.instance.call(
                    functionName: "addUser",
                    parameters: {
                      "name": _nameTextController.text,
                      "email": _emailTextController.text
                    }
                  );
                  Navigator.of(context).pop();

                },
                child: const Text("Confirm")
            )

          ],

        );
      }
    
    );
  }

  StreamBuilder<QuerySnapshot> _retrieveUsers() {

    return new StreamBuilder<QuerySnapshot>(
      stream: Firestore.instance.collection('users').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            print("retrieve users do not have data.");
            return Container();
          }
          return ListView.builder(
              itemCount: snapshot.data.documents.length,
              itemBuilder: (context, index) {

                  final DocumentSnapshot userDoc = snapshot.data.documents[index];

                  return Dismissible(
                    key: new Key(snapshot.data.documents[index].toString()),
                    direction: DismissDirection.horizontal,
                    onDismissed: (DismissDirection direction) {
                      Firestore.instance.collection('users').document(userDoc.documentID).delete();
                    },
                    child: new InkWell(
                      onTap: () => _showEditUserDialog(context, userDoc),
                      child: new ListTile(
                        title: new Text(userDoc['name']),
                        subtitle: new Text(userDoc['email'])
                      ),
                    ),
                  );
              }
          );

        }
    );
  }

  Future<Null> _showEditUserDialog(BuildContext context, DocumentSnapshot userDoc) {
    TextEditingController _nameTextController = new TextEditingController(text: userDoc['name']);
    TextEditingController _emailTextController = new TextEditingController(text: userDoc['email']);

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return new AlertDialog(
          title: Text("Edit contact"),
          content: Container(
            height: 120.0,
            width: 100.0,
            child: ListView(
              children: <Widget>[
                new TextField(
                  controller: _nameTextController,
                  decoration: new InputDecoration(labelText: "Name: "),

                ),
                new TextField(
                  controller: _emailTextController,
                  decoration: new InputDecoration(labelText: "Email: "),
                ),

              ],
            ),
          ),
          actions: <Widget>[
            new FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Cancel")
            ),
            // This button results in adding the contact to the database
            new FlatButton(
                onPressed: () {
                  CloudFunctions.instance.call(
                      functionName: "updateUser",
                      parameters: {
                        "doc_id": userDoc.documentID,
                        "name": _nameTextController.text,
                        "email": _emailTextController.text
                      }
                  );
                  Navigator.of(context).pop();
                },
                child: const Text("Confirm")
            )
          ],

        );
      }
    );
  }


  @override
  Widget build(BuildContext context) {

    return new Scaffold(
      appBar: new AppBar(),
      body: new Center(
       
        child: _retrieveUsers()


      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: () => _showAddUserDialogBox(context),
        tooltip: 'Increment',
        child: new Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  @override
  void initState() {
    super.initState();

  }
}
