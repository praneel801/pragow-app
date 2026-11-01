import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const PRaGOwApp());
}

class AuthService {
  static const adminEmail = 'praneelbhavya122@gmail.com';
  static User? get currentUser => FirebaseAuth.instance.currentUser;
  static String? get currentUserEmail => currentUser?.email;
  static String? get currentUserName => currentUser?.displayName ?? currentUser?.email?.split('@')[0];
  static bool get isAdmin => currentUserEmail?.toLowerCase() == adminEmail.toLowerCase();
  static Future<User?> signInWithGoogle() async {
    final gUser = await GoogleSignIn().signIn();
    if (gUser == null) return null;
    final gAuth = await gUser.authentication;
    final cred = GoogleAuthProvider.credential(accessToken: gAuth.accessToken, idToken: gAuth.idToken);
    final uc = await FirebaseAuth.instance.signInWithCredential(cred);
    await FirebaseFirestore.instance.collection('users').doc(uc.user!.uid).set({
      'email': uc.user!.email, 'name': uc.user!.displayName, 'photo': uc.user!.photoURL,
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return uc.user;
  }
  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }
}

class PRaGOwApp extends StatelessWidget {
  const PRaGOwApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: Color(0xFF0A0A0A)),
      home: StreamBuilder<User?>(stream: FirebaseAuth.instance.authStateChanges(), builder: (c,snap){
        if (snap.connectionState==ConnectionState.waiting) return Scaffold(body: Center(child: CircularProgressIndicator()));
        if (snap.hasData) return HomeScreen();
        return LanguageScreen();
      }),
    );
  }
}

// LANGUAGE + LOGIN + HOME + POST + ADMIN - All in one file!

class LanguageScreen extends StatefulWidget { const LanguageScreen({super.key}); @override State<LanguageScreen> createState()=>_LangState(); }
class _LangState extends State<LanguageScreen> {
  String sel='en';
  @override Widget build(BuildContext context){
    return Scaffold(body: Padding(padding: EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
      SizedBox(height:60), Text('PRaGOw', style: TextStyle(fontSize:48, fontWeight: FontWeight.w900)), Text('AI Powered Practice', style: TextStyle(color: Colors.white60)),
      Spacer(), Text('Choose Language', style: TextStyle(fontSize:20, fontWeight: FontWeight.bold)), SizedBox(height:16),
      _tile('English','en','🇺🇸'), _tile('తెలుగు','te','🇮🇳'), _tile('हिंदी','hi','🇮🇳'),
      Spacer(),
      SizedBox(width:double.infinity,height:56,child:ElevatedButton(style:ElevatedButton.styleFrom(backgroundColor:Colors.white,foregroundColor:Colors.black,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))),onPressed: ()=>Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=>LoginScreen())), child: Text('Continue', style: TextStyle(fontWeight: FontWeight.bold)))),
    ])));
  }
  Widget _tile(String name,String code,String flag){
    bool isSel=sel==code;
    return GestureDetector(onTap: ()=>setState(()=>sel=code), child: Container(margin: EdgeInsets.only(bottom:12),padding: EdgeInsets.all(16),decoration: BoxDecoration(color: isSel?Colors.white:Color(0xFF1E1E1E),borderRadius:BorderRadius.circular(12)), child: Row(children:[Text(flag,style:TextStyle(fontSize:24)),SizedBox(width:12),Text(name,style:TextStyle(color:isSel?Colors.black:Colors.white,fontWeight:FontWeight.w600)),Spacer(), if(isSel)Icon(Icons.check_circle,color:Colors.black)])));
  }
}

class LoginScreen extends StatefulWidget { const LoginScreen({super.key}); @override State<LoginScreen> createState()=>_LoginState(); }
class _LoginState extends State<LoginScreen> {
  bool loading=false;
  @override Widget build(BuildContext context){
    return Scaffold(body: Padding(padding: EdgeInsets.all(24), child: Column(children:[
      SizedBox(height:80), Text('Welcome to',style:TextStyle(color:Colors.white60,fontSize:18)), Text('PRaGOw',style:TextStyle(fontSize:48,fontWeight:FontWeight.w900)), Text('Login to start',style:TextStyle(color:Colors.white54)),
      Spacer(),
      SizedBox(width:double.infinity,height:56,child:ElevatedButton.icon(style:ElevatedButton.styleFrom(backgroundColor:Colors.white,foregroundColor:Colors.black,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))),icon: Icon(Icons.login), label: loading?SizedBox(width:20,height:20,child:CircularProgressIndicator(strokeWidth:2)):Text('Continue with Google',style:TextStyle(fontWeight:FontWeight.bold)), onPressed: loading?null:() async { setState(()=>loading=true); final u=await AuthService.signInWithGoogle(); setState(()=>loading=false); if(u!=null&&mounted){ Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=>HomeScreen())); } })),
      SizedBox(height:40),
    ])));
  }
}

class HomeScreen extends StatefulWidget { const HomeScreen({super.key}); @override State<HomeScreen> createState()=>_HomeState(); }
class _HomeState extends State<HomeScreen> {
  int _idx=0;
  @override Widget build(BuildContext context){
    final pages=[FeedTab(), MyPostsScreen(), PostWorkScreen(), SettingsScreen()];
    return Scaffold(body: pages[_idx], bottomNavigationBar: BottomNavigationBar(backgroundColor: Color(0xFF111111), selectedItemColor: Colors.white, unselectedItemColor: Colors.white38, currentIndex: _idx, type: BottomNavigationBarType.fixed, onTap: (i)=>setState(()=>_idx=i), items: [BottomNavigationBarItem(icon: Icon(Icons.home),label:'Home'), BottomNavigationBarItem(icon: Icon(Icons.work_history),label:'My Posts'), BottomNavigationBarItem(icon: Icon(Icons.add_circle),label:'Post'), BottomNavigationBarItem(icon: Icon(Icons.settings),label:'Settings')]));
  }
}

class FeedTab extends StatelessWidget { const FeedTab({super.key}); @override Widget build(BuildContext context){
  return SafeArea(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
    Padding(padding: EdgeInsets.all(20), child: Row(children:[Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text('Hi, ${AuthService.currentUserName??'Learner'} 👋',style:TextStyle(fontSize:20,fontWeight:FontWeight.bold)), Text('Find practice work near you',style:TextStyle(color:Colors.white54))])), if(AuthService.isAdmin) IconButton(icon: Icon(Icons.admin_panel_settings,color:Colors.amber), onPressed: ()=>Navigator.push(context, MaterialPageRoute(builder: (_)=>AdminDashboard()))), CircleAvatar(backgroundImage: AuthService.currentUser?.photoURL!=null?NetworkImage(AuthService.currentUser!.photoURL!):null, child: AuthService.currentUser?.photoURL==null?Icon(Icons.person):null)])),
    Expanded(child: StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('posts').where('status',isEqualTo:'approved').orderBy('createdAt',descending:true).snapshots(), builder: (context,snap){ if(!snap.hasData) return Center(child:CircularProgressIndicator()); if(snap.data!.docs.isEmpty) return Center(child:Text('No approved works yet',style:TextStyle(color:Colors.white38))); return ListView.builder(padding: EdgeInsets.all(16), itemCount: snap.data!.docs.length, itemBuilder: (c,i){ final doc=snap.data!.docs[i]; final data=doc.data() as Map<String,dynamic>; return Container(margin: EdgeInsets.only(bottom:16),padding: EdgeInsets.all(16),decoration: BoxDecoration(color:Color(0xFF1A1A1A),borderRadius:BorderRadius.circular(16),border: Border.all(color:Colors.white10)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Row(children:[Container(padding: EdgeInsets.symmetric(horizontal:8,vertical:4),decoration: BoxDecoration(color:Colors.white12,borderRadius:BorderRadius.circular(6)), child: Text(data['category']??'Work',style:TextStyle(fontSize:12))),Spacer(),Text(data['budget']??'',style:TextStyle(fontWeight:FontWeight.bold,color:Colors.greenAccent))]),SizedBox(height:8),Text(data['title']??'Untitled',style:TextStyle(fontSize:18,fontWeight:FontWeight.bold)),SizedBox(height:4),Text(data['description']??'',maxLines:2,overflow:TextOverflow.ellipsis,style:TextStyle(color:Colors.white60))])); }); }))
  ]));
}}

class MyPostsScreen extends StatelessWidget { const MyPostsScreen({super.key}); @override Widget build(BuildContext context){
  final uid=AuthService.currentUser?.uid; if(uid==null) return Scaffold(body: Center(child: Text('Login to see posts')));
  return SafeArea(child: Column(children:[Padding(padding: EdgeInsets.all(20), child: Align(alignment: Alignment.centerLeft, child: Text('My Posts',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)))), Expanded(child: StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('posts').where('userId',isEqualTo:uid).orderBy('createdAt',descending:true).snapshots(), builder: (c,snap){ if(!snap.hasData) return Center(child:CircularProgressIndicator()); if(snap.data!.docs.isEmpty) return Center(child:Text('No posts yet',style:TextStyle(color:Colors.white38))); return ListView.builder(padding: EdgeInsets.all(16), itemCount: snap.data!.docs.length, itemBuilder: (c,i){ final d=snap.data!.docs[i].data() as Map<String,dynamic>; return ListTile(title: Text(d['title']??''), subtitle: Text('Status: ${d['status']??'pending'}'), trailing: Icon(d['status']=='approved'?Icons.check_circle:Icons.hourglass_empty, color: d['status']=='approved'?Colors.green:Colors.orange)); }); }))]));
}}

class PostWorkScreen extends StatefulWidget { const PostWorkScreen({super.key}); @override State<PostWorkScreen> createState()=>_PostState(); }
class _PostState extends State<PostWorkScreen> {
  final _title=TextEditingController(); final _desc=TextEditingController(); final _budget=TextEditingController(); final _loc=TextEditingController(); String cat='Electrician'; bool load=false; final cats=['Electrician','Plumber','Carpenter','Painter','Mechanic','Other'];
  @override Widget build(BuildContext context){ return SafeArea(child: SingleChildScrollView(padding: EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[Text('Post a Work',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),SizedBox(height:20),DropdownButtonFormField(value:cat,decoration: InputDecoration(filled:true,fillColor:Color(0xFF1A1A1A),border:OutlineInputBorder(borderRadius:BorderRadius.circular(12))), items: cats.map((e)=>DropdownMenuItem(value:e,child:Text(e))).toList(), onChanged: (v)=>setState(()=>cat=v!)),SizedBox(height:12),TextField(controller:_title,decoration: InputDecoration(hintText:'Work Title',filled:true,fillColor:Color(0xFF1A1A1A),border:OutlineInputBorder(borderRadius:BorderRadius.circular(12)))),SizedBox(height:12),TextField(controller:_desc,maxLines:4,decoration: InputDecoration(hintText:'Describe work...',filled:true,fillColor:Color(0xFF1A1A1A),border:OutlineInputBorder(borderRadius:BorderRadius.circular(12)))),SizedBox(height:12),TextField(controller:_budget,decoration: InputDecoration(hintText:'Budget (₹500)',filled:true,fillColor:Color(0xFF1A1A1A),border:OutlineInputBorder(borderRadius:BorderRadius.circular(12)))),SizedBox(height:12),TextField(controller:_loc,decoration: InputDecoration(hintText:'Location',filled:true,fillColor:Color(0xFF1A1A1A),border:OutlineInputBorder(borderRadius:BorderRadius.circular(12)))),SizedBox(height:24),SizedBox(width:double.infinity,height:56,child:ElevatedButton(style:ElevatedButton.styleFrom(backgroundColor:Colors.white,foregroundColor:Colors.black,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16))), onPressed: load?null:() async { if(_title.text.isEmpty) return; setState(()=>load=true); try{ await FirebaseFirestore.instance.collection('posts').add({'title':_title.text,'description':_desc.text,'budget':_budget.text,'location':_loc.text.isEmpty?'Hyderabad':_loc.text,'category':cat,'userId':FirebaseAuth.instance.currentUser!.uid,'userEmail':FirebaseAuth.instance.currentUser!.email,'status':'pending','createdAt':FieldValue.serverTimestamp()}); if(mounted){ ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post submitted for approval!'))); _title.clear(); _desc.clear(); _budget.clear(); _loc.clear(); } }catch(e){ if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error $e')));} setState(()=>load=false); }, child: load?CircularProgressIndicator():Text('Submit for Approval',style:TextStyle(fontWeight:FontWeight.bold))))]))); }
}

class SettingsScreen extends StatelessWidget { const SettingsScreen({super.key}); @override Widget build(BuildContext context){ return SafeArea(child: Padding(padding: EdgeInsets.all(20), child: Column(children:[Align(alignment: Alignment.centerLeft, child: Text('Settings',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold))),SizedBox(height:20),ListTile(leading: CircleAvatar(child: Icon(Icons.person)), title: Text(AuthService.currentUserName??'User'), subtitle: Text(AuthService.currentUserEmail??'')),Divider(color:Colors.white10),Spacer(),SizedBox(width:double.infinity,height:50,child: OutlinedButton(style: OutlinedButton.styleFrom(foregroundColor:Colors.red,side:BorderSide(color:Colors.red)), onPressed: () async { await AuthService.signOut(); if(context.mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_)=>LanguageScreen()), (r)=>false); }, child: Text('Logout')))]))); } }

class AdminDashboard extends StatelessWidget { const AdminDashboard({super.key}); @override Widget build(BuildContext context){ return Scaffold(appBar: AppBar(title: Text('Admin - Approvals')), body: StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('posts').where('status',isEqualTo:'pending').orderBy('createdAt',descending:true).snapshots(), builder: (c,snap){ if(!snap.hasData) return Center(child:CircularProgressIndicator()); if(snap.data!.docs.isEmpty) return Center(child:Text('No pending posts')); return ListView.builder(itemCount: snap.data!.docs.length, itemBuilder: (c,i){ final doc=snap.data!.docs[i]; final d=doc.data() as Map<String,dynamic>; return Card(margin: EdgeInsets.all(8), child: ListTile(title: Text(d['title']??''), subtitle: Text("${d['description']??''}\nBy: ${d['userEmail']??''}"), isThreeLine: true, trailing: Row(mainAxisSize: MainAxisSize.min, children:[IconButton(icon: Icon(Icons.check,color:Colors.green), onPressed: ()=>doc.reference.update({'status':'approved'})), IconButton(icon: Icon(Icons.close,color:Colors.red), onPressed: ()=>doc.reference.update({'status':'rejected'}))] ))); }); })); } }