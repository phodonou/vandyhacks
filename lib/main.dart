import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'component.dart';

void main() => runApp(new MyApp());
class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  final Firestore _f = Firestore.instance;

  @override
  Widget build(BuildContext context) {

    return new MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Text('My Great App'),
        ),
        body: StreamBuilder(
          stream: _f.collection('app').snapshots(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            return FutureBuilder(
              future: getDocs(snapshot),
              builder: (BuildContext context , AsyncSnapshot<List<Component>> appChildren){
                if(!appChildren.hasData) return Center(child: CircularProgressIndicator(),);
                // turn each component to widget
                List<Widget> bodyWidgets = [];
                for(Component comp in appChildren.data){
                    bodyWidgets.add(
                      buildWidget(comp)
                    );
                    bodyWidgets.add(
                      SizedBox(height: 20.0,)
                    );
                }
                //display each component
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                  child: ListView(
                    children: bodyWidgets,
                  ),
                );

              },
            );
          },
        ),
      ),
    );
  }

  Widget buildWidget(Component comp){
    //has only one child
    if(comp.children.length == 0 ){
      if(comp.widget == "Button"){
        return renderSingleWidget(widget: comp.widget , extras:{'hasText':comp.extras['hasText']});
      }else{
        return renderSingleWidget(widget: comp.widget);
      }
    }
    else{
      //has children
      List<Widget> children = [];
      for(Component vcomp in comp.children){
        children.add(
          buildWidget(vcomp)
        );
      }
      if(comp.widget == 'Row'){
        return renderMultipleWidget(widget: comp.widget, children: children, demensions: comp.extras['demensions']);
      }else{
        return renderMultipleWidget(widget: comp.widget, children: children);
      }
    }
  }

  Widget renderSingleWidget({String widget, Map extras}){
    switch(widget){
      case  "Button": {
        return RaisedButton(
          child: extras['hasText'] ? Text('Your Text Here') : Text(''),
          color: Colors.blue,
          onPressed: (){},
        );
      }
      break;

      case  "TextField": {
        return Container(
          child: Expanded(
            child: TextField(
                decoration: InputDecoration(
                  labelText: 'Your Input Here'
                ),
              ),
        )
        );
      }
      break;

      case  "Text": {
        return Text(
          'This is a text'
        );
      }
      break;

      case  "Image": {
        return Container(
          color: Colors.lightBlue,
          child: Center(
            child: Text('This is an image'),
          ),
        );
      }
      break;

      case  "Switch": {
        return Switch(
          value: true,
          onChanged: (_){},
        );
      }
      break;

      case  "Checkbox": {
        return Checkbox(
          value: true,
          onChanged: (_){},
        );
      }
      break;

      default: {
        return Center(child: Text("Cannot Render Widget"),);
      }
      break;

    }
  }

  Widget renderMultipleWidget({String widget, List<Widget> children, List demensions}){
    switch(widget){
      case  "Row": {
        return Container(
          margin: EdgeInsets.only(left: (demensions[0] + .0)/10, top: (demensions[1] + .0)/10),
          child: Row(
            mainAxisAlignment:  MainAxisAlignment.spaceEvenly,
            children: children,
          ),
        );
      }
      break;

      case  "Column": {
        return Container(
          child: Column(
            mainAxisAlignment:  MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        );
      }
      break;

      default: {
        return Center(child: Text("Cannot Render Widget"),);
      }
      break;

    }
  }

   Future<List<Component>> getDocs(AsyncSnapshot<QuerySnapshot> snapshot) async {
    List<Component> children = [];
    //for each children
    for(DocumentSnapshot doc in snapshot.data.documents){
      if(doc.documentID != "update_code"){
        children.add( await makeComp(doc.reference));
      }
    }
    return children;
  }

    Future<Component> makeComp(DocumentReference docF) async {
      QuerySnapshot querySnapshot = await docF.collection('children').getDocuments();
      if(querySnapshot.documents.length > 0){ //have children
        List<Component> children = [];
        for(DocumentSnapshot d in querySnapshot.documents){
          children.add(
            await makeComp(d.reference)
          );
        }
        DocumentSnapshot currDoc = await docF.get();
        return Component(
          widget: currDoc.data['comp'], 
          children: children,
          extras: currDoc.data['comp'] == 'Button' ? {
              "hasText": currDoc.data['hasText']
            } : currDoc.data['comp'] == 'Row' ? {'demensions':[currDoc.data['distanceFromLeft'], currDoc.data['distanceToTop']]} : {}
        );
      }
      else{
        DocumentSnapshot currDoc = await docF.get();
        return Component(
          widget: currDoc.data['comp'], 
          children: [],
          extras: currDoc.data['comp'] == 'Button' ? {
              "hasText": currDoc.data['hasText']
            } : currDoc.data['comp'] == 'Row' ? {'demensions':[currDoc.data['distanceFromLeft'], currDoc.data['distanceToTop']]} : {}
          );
      }
  }

}