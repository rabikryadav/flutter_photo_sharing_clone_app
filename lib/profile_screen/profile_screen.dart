import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_photo_sharing_clone_app/home_screen/home_screen.dart';
import 'package:flutter_photo_sharing_clone_app/log_in/login_screen.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as fStorage;

class ProfileScreen extends StatefulWidget {

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  String? name = '';
  String? email = '';
  String? image = '';
  String? phoneNo = '';

  File? imageXFile;
  String? userImageUrl;
  String? userNameInput = '';

  Future _getDataFromDatabase() async{
    await FirebaseFirestore.instance.collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get().then((snapshot) async {
          if(snapshot.exists){
            setState(() {
              name = snapshot.data()!["name"];
              email = snapshot.data()!["email"];
              image = snapshot.data()!["userImage"];
              phoneNo = snapshot.data()!["phoneNumber"];
            });
          }
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getDataFromDatabase();
  }

  void _showImageDialog(){
    showDialog(
        context: context,
        builder: (context){
          return AlertDialog(
            title: const Text("Please choose an option"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: (){
                    _getFromCamera();
                  },
                  child: Row(
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.camera,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        "Camera",
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: (){
                    _getFromGallery();
                  },
                  child: Row(
                    children: const [
                      Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.image,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        "Gallery",
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
    );
  }

  void _getFromCamera() async{
    XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    _cropImage(pickedFile!.path);
    Navigator.pop(context);
  }

  void _getFromGallery() async{
    XFile? pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    _cropImage(pickedFile!.path);
    Navigator.pop(context);
  }

  void _cropImage(filePath) async{
    CroppedFile? croppedImage = await ImageCropper().cropImage(
        sourcePath: filePath, maxHeight: 1080, maxWidth: 1080);

    if(croppedImage != null){
      setState((){
        imageXFile = File(croppedImage.path);
        _updateImageInFirestore();
      });
    }
  }
  
  _updateImageInFirestore() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    fStorage.Reference reference = fStorage.FirebaseStorage.instance.ref()
    .child("userImages").child(fileName);
    fStorage.UploadTask uploadTask = reference.putFile(File(imageXFile!.path));
    fStorage.TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() {});
    await taskSnapshot.ref.getDownloadURL().then((url) async{
      userImageUrl = url;
    });
    await FirebaseFirestore.instance.collection("users")
    .doc(FirebaseAuth.instance.currentUser!.uid)
    .update({
      'userImage': userImageUrl,
    }).whenComplete(() {
      _updateProfileImageOnUserExistingPosts();
    });
  }

  _updateProfileImageOnUserExistingPosts() async{
    await FirebaseFirestore.instance.collection('wallpaper')
        .where('id', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((snapshot){
      for(int index = 0; index<snapshot.docs.length; index++){
        String userProfileImageInPost = snapshot.docs[index]['userImage'];
        if(userProfileImageInPost != userImageUrl){
          FirebaseFirestore.instance.collection('wallpaper')
              .doc(snapshot.docs[index].id)
              .update({
            'userImage': userImageUrl,
          });
        }
      }
    });
  }

  Future _updateUserName() async {
    await FirebaseFirestore.instance.collection("users")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .update({
      'name': userNameInput,
    }).whenComplete(() {
      _updateProfileNameOnUserExistingPosts();
    });
  }

  _updateProfileNameOnUserExistingPosts() async{
    await FirebaseFirestore.instance.collection('wallpaper')
        .where('id', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
        .get()
        .then((snapshot){
      for(int index = 0; index<snapshot.docs.length; index++){
        String userProfileNameInPost = snapshot.docs[index]['name'];
        if(userProfileNameInPost != userNameInput){
          FirebaseFirestore.instance.collection('wallpaper')
              .doc(snapshot.docs[index].id)
              .update({
            'name': userNameInput,
          });
        }
      }
    });
  }

  _displayTextInputDialog(BuildContext context) async{
    return showDialog(
        context: context,
        builder: (context){
          return AlertDialog(
            title: const Text("Update your Name Here"),
            content: TextField(
              onChanged: (value){
                setState(() {
                  userNameInput = value;
                });
              },
              decoration: const InputDecoration(hintText: "Type here"),
            ),
            actions: [
              ElevatedButton(
                  child: const Text('Cancel', style: TextStyle(color:  Colors.white),),
                onPressed: (){
                    setState(() {
                      Navigator.pop(context);
                    });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
              ElevatedButton(
                child: const Text('Save', style: TextStyle(color:  Colors.white),),
                onPressed: (){
                  _updateUserName();
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                ),
              )
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.pink, Colors.deepOrange.shade300],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [0.2, 0.9],
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.pink.shade400,
        title: const Center(
          child: Text("Profile Screen"),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white,),
          onPressed: (){
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepOrange.shade300, Colors.pink],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: [0.2, 0.9],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: (){
                _showImageDialog();
              },
              child: CircleAvatar(
                backgroundColor: Colors.amber,
                minRadius: 85.0,
                child: CircleAvatar(
                  radius: 80.0,
                  backgroundImage: imageXFile == null ? NetworkImage(image!) : Image.file(imageXFile!).image,
                ),
              ),
            ),
            const SizedBox(height: 10.0,),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Name : ${name!}',
                  style: const TextStyle(
                    fontSize: 25.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: (){
                    _displayTextInputDialog(context);
                  },
                  icon: const Icon(Icons.edit),
                ),
              ],
            ),
            const SizedBox(height: 10.0,),
            Text(
              'Email : ${email!}',
              style: const TextStyle(
                fontSize: 15.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10.0,),
            Text(
              'Number : ${phoneNo!}',
              style: const TextStyle(
                fontSize: 15.0,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10.0,),
            ElevatedButton(
              onPressed: (){
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              ),
              child: const Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }
}
