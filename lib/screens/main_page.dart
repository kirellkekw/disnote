import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:disnote/assets/circular_box.dart';
import 'package:disnote/other/constants.dart';
import 'package:disnote/services/sql_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<MainPage> {
  // journals
  List<Map<String, dynamic>> journals = [];
  List<Map<String, dynamic>> backupJournal = [];

  // filtering
  String titleSearchQuery = "";
  bool filter = false;

  // webhook
  String webhookURL = "";

  // state check
  bool _isLoading = true;

  // controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _titleSearchController = TextEditingController();
  final TextEditingController _webhookController = TextEditingController();


  void _loadWebhook() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    webhookURL = (prefs.getString('webhook') ?? "");
  }

  void _setWebhook() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('webhook', webhookURL);
  }

  Future<http.Response> _postWebhook(
      String title, String content, String webhook) {
    if (title == "") {
      title = "noTitleFound";
    }
    if (content == "") {
      content = "noContentFound";
    }
    Map data = {
      "embeds": [
        {"title": title, "description": content}
      ]
    };
    return http.post(
      Uri.parse(webhook),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode(data),
    );
  }

  void _refreshJournals() async {
    final data = await SQLHelper.getItems();
    setState(() {
      journals = data;
      _isLoading = false;
      backupJournal = journals;
    });
  }

  void _askWebhook() async {
    showModalBottomSheet(
      context: context,
      elevation: 5,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          color: kBackgroundColor,
          padding: EdgeInsets.only(
            top: 15,
            left: 15,
            right: 15,
            // this will prevent the soft keyboard from covering the text fields
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(
                height: 30,
              ),
              TextField(
                style: const TextStyle(
                  color: kIconColor,
                  fontSize: 17,
                ),
                controller: _webhookController,
                decoration: const InputDecoration(
                  hintText: 'Webhook URL',
                  hintStyle: TextStyle(
                    color: kIconColor,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(kBoxColor),
                ),
                onPressed: () {
                  webhookURL = _webhookController.text;
                  _setWebhook();
                  Navigator.pop(context);
                },
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: kTextColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _askTitlePrompt() async {
    showModalBottomSheet(
      context: context,
      elevation: 5,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          color: kBackgroundColor,
          padding: EdgeInsets.only(
            top: 15,
            left: 15,
            right: 15,
            // this will prevent the soft keyboard from covering the text fields
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(
                height: 30,
              ),
              TextField(
                style: const TextStyle(
                  color: kIconColor,
                  fontSize: 17,
                ),
                controller: _titleSearchController,
                decoration: const InputDecoration(
                  hintText: 'Title',
                  hintStyle: TextStyle(
                    color: kIconColor,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(kBoxColor),
                ),
                onPressed: () {
                  journals = backupJournal;
                  titleSearchQuery = _titleSearchController.text;
                  _titleSearchController.text = '';
                  journals = journals
                      .where((element) => element['title']
                          .toString()
                          .toLowerCase()
                          .contains(titleSearchQuery))
                      .toList();
                  setState(() {
                    filter = true;
                  });
                  // Close the bottom sheet
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                child: const Text(
                  'Search',
                  style: TextStyle(
                    color: kTextColor,
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _showForm(int? id) async {
    if (id != null) {
      // id == null -> create new item
      // id != null -> update an existing item
      final existingJournal =
          journals.firstWhere((element) => element['id'] == id);
      _titleController.text = existingJournal['title'];
      _contentController.text = existingJournal['content'];
    }

    showModalBottomSheet(
      context: context,
      elevation: 5,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          color: kBackgroundColor,
          padding: EdgeInsets.only(
            top: 15,
            left: 15,
            right: 15,
            // this will prevent the soft keyboard from covering the text fields
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SizedBox(
                height: 30,
              ),
              TextField(
                style: const TextStyle(
                  color: kIconColor,
                  fontSize: 17,
                ),
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Title',
                  hintStyle: TextStyle(
                    color: kIconColor,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              TextField(
                minLines: 1,
                maxLines: 9,
                style: const TextStyle(
                  color: kIconColor,
                  fontSize: 17,
                ),
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: 'Content',
                  hintStyle: TextStyle(
                    color: kIconColor,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(kBoxColor),
                ),
                onPressed: () async {
                  // Save new journal
                  if (id == null) {
                    await _createItem();
                  }
                  if (id != null) {
                    await _updateItem(id);
                  }
                  // Clear the text fields
                  _titleController.text = '';
                  _contentController.text = '';
                  // Close the bottom sheet
                  if (!mounted) return;
                  Navigator.pop(context);
                },
                child: Text(
                  id == null ? 'Create New' : 'Update',
                  style: const TextStyle(
                    color: kTextColor,
                  ),
                ),
              )
            ],
          ),
        );
      },
    );
  }

// Insert a new journal to the database
  Future<void> _createItem() async {
    await SQLHelper.createItem(_titleController.text, _contentController.text);
    _refreshJournals();
  }

  // Update an existing journal
  Future<void> _updateItem(int id) async {
    await SQLHelper.updateItem(
        id, _titleController.text, _contentController.text);
    _refreshJournals();
  }

  // Delete an item
  void _deleteItem(int id) async {
    await SQLHelper.deleteItem(id);
    _refreshJournals();
  }
  
  @override
  void initState() {
    super.initState();
    _loadWebhook();
    _refreshJournals(); // Loading the diary when the app starts
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              _askTitlePrompt();
            },
            icon: const Icon(Icons.search),
          ),
          filter
              ? IconButton(
                  onPressed: () {
                    _refreshJournals();
                    setState(() {
                      filter = false;
                      titleSearchQuery = "";
                    });
                  },
                  icon: const Icon(Icons.close),
                )
              : Container(),
          IconButton(
            onPressed: () {
              _askWebhook();
            },
            icon: const Icon(Icons.settings),
          ),
        ],
        title: const Text(
          'Disnote',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: kTextColor,
          ),
        ),
        backgroundColor: kBackgroundColor,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
              ),
              itemCount: journals.length,
              itemBuilder: (_, index) {
                return CircularBox(
                  color: kBoxColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          journals[index]['title'],
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: kTextColor,
                            fontSize: 22,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8, right: 8),
                        child: Text(
                          journals[index]['content'],
                          overflow: TextOverflow.ellipsis,
                          maxLines: 5,
                          style: const TextStyle(
                            color: kTextColor,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: kIconColor,
                            ),
                            onPressed: () {
                              _showForm(
                                journals[index]['id'],
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: kIconColor,
                            ),
                            onPressed: () {
                              _deleteItem(journals[index]['id']);
                            },
                          ),
                          if (webhookURL != '')
                            IconButton(
                              icon: const Icon(
                                Icons.upload,
                                color: kIconColor,
                              ),
                              onPressed: () {
                                _postWebhook(journals[index]["title"],
                                    journals[index]["content"], webhookURL);
                              },
                            )
                        ],
                      ),
                    ],
                  ),
                );
              }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: kIconColor,
        onPressed: () {
          _showForm(null);
        },
        child: const Icon(
          Icons.add,
          color: kBackgroundColor,
        ),
      ),
    );
  }
}
