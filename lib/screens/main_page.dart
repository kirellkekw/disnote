import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:disnote/assets/circular_box.dart';
import 'package:disnote/other/constants.dart';
import 'package:disnote/services/sql_helper.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<MainPage> {
  // All journals
  List<Map<String, dynamic>> _journals = [];
  List<Map<String, dynamic>> backupJournal = [];
  String titleSearchQuery = "";
  bool filter = false;
  bool _isLoading = true;
  // This function is used to fetch all data from the database
  void _refreshJournals() async {
    final data = await SQLHelper.getItems();
    setState(() {
      _journals = data;
      _isLoading = false;
      backupJournal = _journals;
    });
  }

  Future<http.Response> postWebhook(String title, String content) {
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
      Uri.parse(
          'https://discord.com/api/webhooks/1095084147216765098/evSEDQkNU2okmrPbmIPwlZrwc75GdCANt5tBbT8rm1jfZyVxcazhnzl_IQ6xXaPN2ezd'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: json.encode(data),
    );
  }

  @override
  void initState() {
    super.initState();
    _refreshJournals(); // Loading the diary when the app starts
  }

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _titleSearchController = TextEditingController();

  void askTitlePrompt() async {
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
                    _journals = backupJournal;
                    titleSearchQuery = _titleSearchController.text;
                    _titleSearchController.text = '';
                    _journals = _journals
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
        });
  }

  void _showForm(int? id) async {
    if (id != null) {
      // id == null -> create new item
      // id != null -> update an existing item
      final existingJournal =
          _journals.firstWhere((element) => element['id'] == id);
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              askTitlePrompt();
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
              itemCount: _journals.length,
              itemBuilder: (_, index) {
                return CircularBox(
                  color: kBoxColor,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _journals[index]['title'],
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
                          _journals[index]['content'],
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
                                _journals[index]['id'],
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: kIconColor,
                            ),
                            onPressed: () {
                              _deleteItem(_journals[index]['id']);
                            },
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.upload,
                              color: kIconColor,
                            ),
                            onPressed: () async {
                              var res = await postWebhook(
                                  _journals[index]["title"],
                                  _journals[index]["content"]);
                              debugPrint(res.statusCode.toString());
                            },
                          ),
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
