import 'package:flutter/material.dart';
import 'dart:math';
import 'package:xkcd_password/wordlist.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
	runApp(MyApp());
}

class MyApp extends StatelessWidget {
	@override
	Widget build(BuildContext context) {
		return ChangeNotifierProvider(
			create: (context) => WordStorage(),
			child:MaterialApp(
				title: 'xkcd password generator',
				theme: ThemeData(
					primarySwatch: Colors.blue,
				),
				home: MyScaffold()
			)
		);
	}
}

class WordStorage extends ChangeNotifier{
	List<String> _words = [for (var i = 0; i<6; i++) ''];
	final _random = Random.secure();

	void _setWord(int index){
		if (index >= _words.length){
			_words.addAll([for (var i = 0; i < (index - _words.length + 1); i++) _newWord()]);
		}
		_words[index] = _newWord();
	}

	String _newWord(){
		return wordlist[_random.nextInt(wordlist.length)];
	}

	String getWord(int index){
		if (index >= _words.length || _words[index].length == 0){
			_setWord(index);
			return _words[index];
		}
		return _words[index];
	}

	void changeWord(int index){
		_setWord(index);
		notifyListeners();
	}

	String getPassphrase(){
		return _words.where((String a) => a.length > 0).join(' ');
	}

	int get wordCount => _words.length;

	set wordCount (int newCount){
		if (_words.length < newCount){
			_setWord(newCount - 1);
		}else if (_words.length > newCount){
			var prevWordsLength = _words.length;
			for (var i = 0; i<(prevWordsLength - newCount); i++) _words.removeAt(_words.length - 1);
		}
		notifyListeners();
	}

	int get totalChars{
		var total = 0;
		for (var w in _words) total += w.length;
		return total;
	}
}

class MyScaffold extends StatelessWidget{
	@override
	Widget build(BuildContext context){
		var wordStorage = Provider.of<WordStorage>(context, listen:true);
		var wordCount = wordStorage.wordCount;
		var charCount = wordStorage.totalChars;
		var combinations = BigInt.from(1296).pow(wordCount).toString();
		var combinationsPow10 = combinations.length - 1;
		var bitsOfEntropy = BigInt.from(1296).pow(wordCount).toRadixString(2).length - 1;

		return Scaffold(
			appBar:	MyAppBar(),
			body:Center(
				child:Column(
					children:[
						Wrap(
							children: <StatefulWidget>[for (var i=0; i < wordCount; i++) 
								Word(i)
							],
							spacing: 4.0,
							runSpacing: 4.0,
							alignment: WrapAlignment.center,
						),
						SizedBox(
							height: 50,
						),
						Text('At a length of $wordCount words, there are ${combinations[0]}.${(int.parse(combinations.substring(1,4))/10).round()}×10^$combinationsPow10 possible combinations. ($bitsOfEntropy bits of entropy, ${(charCount == 0) ? 'ca. ${5*wordCount}' : charCount} characters)', textAlign: TextAlign.center,)
					],
					mainAxisAlignment: MainAxisAlignment.center,
					crossAxisAlignment: CrossAxisAlignment.center,
				)
			)
		);
	}
}

class MyAppBar extends StatelessWidget implements PreferredSizeWidget{
	@override
	Size get preferredSize => Size.fromHeight(kToolbarHeight);

	@override
	Widget build(BuildContext context){
		return AppBar(
			title:Text('xkcd password generator'),
			actions: [
				IconButton(
					icon: Icon(Icons.copy), 
					onPressed: (){
						var clipboardText = Provider.of<WordStorage>(context, listen:false).getPassphrase();
						Clipboard.setData(ClipboardData(text: clipboardText));
						ScaffoldMessenger.of(context).showSnackBar(SnackBar(
							content: Text("Copied '$clipboardText' to clipboard"),
							duration: Duration(seconds: 5)
						));
					}
				),
				PopupMenuButton(
					itemBuilder: (BuildContext context){
						return <PopupMenuEntry>[
							PopupMenuItem(
								child:ListTile(
									leading: Icon(Icons.refresh),
									title:Text('Refresh all'),
									onTap: (){
										var wordStorage = Provider.of<WordStorage>(context, listen:false);
										for (var i = 0; i<wordStorage.wordCount; i++) wordStorage.changeWord(i);
									},
								),
							),
							PopupMenuItem(
								child:ListTile(
									leading: Icon(Icons.settings),
									title:Text('Settings'),
									onTap: (){
										showDialog(
											context:context,
											builder:(context){
												return CustomDialog();
											}
										);
									},
								)
							),
							PopupMenuItem(
								child:ListTile(
									leading: Icon(Icons.info_outline),
									title:Text('About'),
									onTap: (){
										launch('https://m.xkcd.com/936/');
									},
								)
							),
						];
					}
				)
			],
		);
	}
}

class CustomDialog extends StatefulWidget{
	@override
	_CustomDialogState createState() => _CustomDialogState();
}

class _CustomDialogState extends State<CustomDialog>{
	double _wordCount;

	@override
	Widget build(BuildContext context){
		double _getWordCount(){
			var wordStorage = Provider.of<WordStorage>(context, listen:false);
			_wordCount = wordStorage.wordCount.toDouble();
			return _wordCount;
		}

		return AlertDialog(
			title: Text('Set number of words'),
			content: Container(
				height: 100,
				child:Slider(
					value: _wordCount ?? _getWordCount(),
					onChanged: (value){
						setState(() {
							_wordCount = value;
						});
					},
					min: 1,
					max: 20,
					divisions: 20,
					label:_wordCount.round().toString()
				),
			),
			actions: [
				TextButton(
					onPressed: (){
						Navigator.of(context, rootNavigator: true).pop();
					},
					child: Text('CANCEL')
				),
				TextButton(
					onPressed: (){
						var wordStorage = Provider.of<WordStorage>(context, listen:false);
						wordStorage.wordCount = _wordCount.round();
						Navigator.of(context, rootNavigator: true).pop();
					},
					child: Text('CONFIRM')
				)
			],
		);
	}
}

class Word extends StatefulWidget{
	final int _index;
	Word(this._index);

	@override
	_WordState createState() => _WordState(_index);
}

class _WordState extends State<Word> with SingleTickerProviderStateMixin{
	final int _index;
	AnimationController _animationController;
	var _animationDuration = Duration(milliseconds: 300);
	_WordState(this._index);

	final _wordStyle = TextStyle(fontSize: 24.0);

	@override
	void initState(){
		super.initState();
		_animationController = AnimationController(
			duration: _animationDuration,
			vsync: this
		);
	}

	@override
	Widget build(BuildContext context){
		return Consumer<WordStorage>(
			builder: (context, wordStorage, child){
				return InkWell(
					onTap: (){
						_animationController.repeat();
						_animationController.animateTo(1.0);
						//_animationController.repeat();
						Future.delayed(_animationDuration*0.5,(){
							wordStorage.changeWord(_index);
						});
						/*Future.delayed(_animationDuration,(){
							_animationController.stop();
						});*/
					},
					child:RotationTransition(
						alignment: Alignment.center,
						turns: _animationController,
						child:Container(
							child:Text(
								wordStorage.getWord(_index),
								style: _wordStyle,
							),
							padding: EdgeInsets.all(12),
						)
					),
					borderRadius: BorderRadius.all(Radius.circular(8)),
				);
			}
		);
	}
}

